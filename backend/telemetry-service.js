// backend/telemetry-service.js
// Centralized Telemetry, Dynamic Pricing & Spend Circuit Breaker for LingoSync AI services

const DEFAULT_PRICING = {
    'gemini-3.8-flash': { text_in: 0.15, text_out: 0.60 },
    'gemini-3.6-flash': { text_in: 0.10, text_out: 0.40 },
    'gemini-3.5-flash-lite': { text_in: 0.075, text_out: 0.30 },
    'gemini-3.1-flash-lite': { text_in: 0.075, text_out: 0.30 },
    'gemini-3.8-live': { text_in: 0.15, audio_in: 0.60, audio_out: 2.40 },
    'default': { text_in: 0.15, text_out: 0.60 }
};

// In-memory sliding buffer for telemetry & local circuit breaker fallback
const localTelemetryBuffer = [];
const MAX_LOCAL_BUFFER_SIZE = 1000;

let cachedPricing = null;
let lastPricingFetch = 0;
const PRICING_CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

/**
 * Loads dynamic pricing from Supabase or returns defaults
 */
async function getPricing(supabase) {
    const now = Date.now();
    if (cachedPricing && (now - lastPricingFetch < PRICING_CACHE_TTL_MS)) {
        return cachedPricing;
    }

    try {
        if (supabase) {
            const { data, error } = await supabase
                .from('ai_pricing_config')
                .select('*')
                .is('effective_to', null);

            if (!error && data && data.length > 0) {
                const map = {};
                for (const row of data) {
                    if (!map[row.model_id]) map[row.model_id] = {};
                    const key = `${row.modality}_${row.direction}`;
                    map[row.model_id][key] = parseFloat(row.usd_per_million_tokens);
                }
                cachedPricing = map;
                lastPricingFetch = now;
                return cachedPricing;
            }
        }
    } catch (err) {
        // Fallback gracefully to DEFAULT_PRICING
    }

    return DEFAULT_PRICING;
}

/**
 * Calculates estimated USD cost for an AI call
 */
function calculateCost(model, pricing, { tokensIn = 0, tokensOut = 0, audioSecondsIn = 0, audioSecondsOut = 0 }) {
    const modelPricing = pricing[model] || pricing['default'] || DEFAULT_PRICING['default'];
    let cost = 0;

    const textInRate = modelPricing.text_in ?? 0.15;
    const textOutRate = modelPricing.text_out ?? 0.60;
    const audioInRate = modelPricing.audio_in ?? 0.60;
    const audioOutRate = modelPricing.audio_out ?? 2.40;

    cost += (tokensIn / 1_000_000) * textInRate;
    cost += (tokensOut / 1_000_000) * textOutRate;

    // Convert audio seconds to approx token equivalent if needed, or per-second rate
    // Gemini live audio is approx 25 tokens/second (16kHz PCM)
    const audioInTokens = audioSecondsIn * 25;
    const audioOutTokens = audioSecondsOut * 25;
    cost += (audioInTokens / 1_000_000) * audioInRate;
    cost += (audioOutTokens / 1_000_000) * audioOutRate;

    return Math.round(cost * 1_000_000) / 1_000_000; // 6 decimal places
}

/**
 * Records AI telemetry both to Supabase and in-memory buffer
 */
async function recordAiTelemetry({
    supabase,
    module,
    model,
    fallbackTriggered = false,
    tokensIn = 0,
    tokensOut = 0,
    audioSecondsIn = 0,
    audioSecondsOut = 0,
    latencyMs = 0,
    userId = null
}) {
    const pricing = await getPricing(supabase);
    const costEstimateUsd = calculateCost(model, pricing, { tokensIn, tokensOut, audioSecondsIn, audioSecondsOut });

    const entry = {
        module,
        model,
        fallback_triggered: !!fallbackTriggered,
        tokens_in: tokensIn,
        tokens_out: tokensOut,
        audio_seconds_in: audioSecondsIn,
        audio_seconds_out: audioSecondsOut,
        latency_ms: latencyMs,
        cost_estimate_usd: costEstimateUsd,
        user_id: userId,
        created_at: new Date().toISOString()
    };

    // 1. In-memory buffer
    localTelemetryBuffer.push(entry);
    if (localTelemetryBuffer.length > MAX_LOCAL_BUFFER_SIZE) {
        localTelemetryBuffer.shift();
    }

    // 2. Persist to Supabase if client available
    if (supabase) {
        try {
            const { error } = await supabase.from('ai_telemetry_logs').insert([entry]);
            if (error && error.code !== '42P01') { // Ignore relation doesn't exist error if pending migration
                console.warn('⚠️ Telemetry insert notice:', error.message);
            }
        } catch (e) {
            // Non-blocking telemetry
        }
    }

    return entry;
}

/**
 * Checks if user has exceeded their daily AI budget ($1.50/day default circuit breaker)
 */
async function checkDailySpendBreaker({ supabase, userId, dailyLimitUsd = 1.50 }) {
    if (!userId) {
        return { allowed: true, todaySpendUsd: 0, dailyLimitUsd, remainingUsd: dailyLimitUsd };
    }

    // 1. Try Supabase RPC check_user_ai_spend
    if (supabase) {
        try {
            const { data, error } = await supabase.rpc('check_user_ai_spend', {
                p_user_id: userId,
                p_daily_limit_usd: dailyLimitUsd
            });

            if (!error && data) {
                return {
                    allowed: !data.quota_exceeded,
                    todaySpendUsd: parseFloat(data.today_spend_usd || 0),
                    dailyLimitUsd: parseFloat(data.daily_limit_usd || dailyLimitUsd),
                    remainingUsd: parseFloat(data.remaining_usd || 0)
                };
            }
        } catch (_) {
            // Fallback to local buffer
        }
    }

    // 2. Fallback to local memory buffer
    const today = new Date().toISOString().slice(0, 10);
    const todayUserEntries = localTelemetryBuffer.filter(
        e => e.user_id === userId && e.created_at && e.created_at.startsWith(today)
    );
    const localSpend = todayUserEntries.reduce((sum, e) => sum + (e.cost_estimate_usd || 0), 0);
    const allowed = localSpend < dailyLimitUsd;

    return {
        allowed,
        todaySpendUsd: Math.round(localSpend * 1000) / 1000,
        dailyLimitUsd,
        remainingUsd: Math.max(0, Math.round((dailyLimitUsd - localSpend) * 1000) / 1000)
    };
}

module.exports = {
    DEFAULT_PRICING,
    getPricing,
    calculateCost,
    recordAiTelemetry,
    checkDailySpendBreaker
};
