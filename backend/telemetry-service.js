// backend/telemetry-service.js
// Centralized Telemetry, Dynamic Pricing & Spend Circuit Breaker for LingoSync AI services (C09, C10, C11)

const DEFAULT_PRICING = {
    'gemini-3.8-flash': { text_in: 0.15, text_out: 0.60 },
    'gemini-3.6-flash': { text_in: 0.10, text_out: 0.40 },
    'gemini-3.5-flash-lite': { text_in: 0.075, text_out: 0.30 },
    'gemini-3.1-flash-lite': { text_in: 0.075, text_out: 0.30 },
    'gemini-3.8-live': { text_in: 0.15, audio_in: 0.60, audio_out: 2.40 },
    'default': { text_in: 0.15, text_out: 0.60 }
};

const TIER_DAILY_SPEND_LIMITS = {
    free: 0.08,
    pro: 0.25,
    elite: 0.45,
    unlimited: 100.00
};

const localTelemetryBuffer = [];
const MAX_LOCAL_BUFFER_SIZE = 200;

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
        // Fallback to DEFAULT_PRICING
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

    // Gemini live audio ~ 25 tokens/second (16kHz PCM)
    const audioInTokens = audioSecondsIn * 25;
    const audioOutTokens = audioSecondsOut * 25;
    cost += (audioInTokens / 1_000_000) * audioInRate;
    cost += (audioOutTokens / 1_000_000) * audioOutRate;

    return Math.round(cost * 1_000_000) / 1_000_000;
}

/**
 * Records AI telemetry both to Supabase and in-memory buffer, computing AI talk ratio
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

    // AI Talk Ratio (E1 Target: 0.30 - 0.35)
    const totalAudioSeconds = audioSecondsIn + audioSecondsOut;
    const aiTalkRatio = totalAudioSeconds > 0 ? Math.round((audioSecondsOut / totalAudioSeconds) * 100) / 100 : null;

    if (aiTalkRatio !== null && aiTalkRatio > 0.40) {
        console.warn(`⚠️ [AI Economy] AI Talk Ratio drift detected: ${(aiTalkRatio * 100).toFixed(1)}% (target <= 35%)`);
    }

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
        ai_talk_ratio: aiTalkRatio,
        user_id: userId,
        created_at: new Date().toISOString()
    };

    localTelemetryBuffer.push(entry);
    if (localTelemetryBuffer.length > MAX_LOCAL_BUFFER_SIZE) {
        localTelemetryBuffer.shift();
    }

    if (supabase) {
        try {
            const { error } = await supabase.from('ai_telemetry_logs').insert([entry]);
            if (error && error.code !== '42P01') {
                console.warn('⚠️ Telemetry insert notice:', error.message);
            }
        } catch (_) {}
    }

    return entry;
}

/**
 * Checks per-user tiered daily spend breaker and global daily budget
 */
async function checkDailySpendBreaker({ supabase, userId, tier = 'pro', globalLimitUsd = 25.00 }) {
    const userDailyLimitUsd = TIER_DAILY_SPEND_LIMITS[tier] || TIER_DAILY_SPEND_LIMITS.pro;

    if (!userId) {
        return { allowed: true, todaySpendUsd: 0, dailyLimitUsd: userDailyLimitUsd, remainingUsd: userDailyLimitUsd };
    }

    // 1. Try Supabase RPC check_spend_breakers
    if (supabase) {
        try {
            const { data, error } = await supabase.rpc('check_spend_breakers', {
                p_user_id: userId,
                p_user_tier: tier
            });

            if (!error && data) {
                return {
                    allowed: data.allowed,
                    todaySpendUsd: parseFloat(data.user_spend_usd || 0),
                    dailyLimitUsd: parseFloat(data.user_limit_usd || userDailyLimitUsd),
                    remainingUsd: Math.max(0, parseFloat((data.user_limit_usd || userDailyLimitUsd) - (data.user_spend_usd || 0))),
                    globalSpendUsd: parseFloat(data.global_spend_usd || 0),
                    globalKillSwitch: !!data.global_kill_switch
                };
            }
        } catch (_) {}
    }

    // 2. In-memory buffer calculation
    const today = new Date().toISOString().slice(0, 10);
    const todayUserEntries = localTelemetryBuffer.filter(
        e => e.user_id === userId && e.created_at && e.created_at.startsWith(today)
    );
    const localUserSpend = todayUserEntries.reduce((sum, e) => sum + (e.cost_estimate_usd || 0), 0);
    const totalDailySpend = localTelemetryBuffer
        .filter(e => e.created_at && e.created_at.startsWith(today))
        .reduce((sum, e) => sum + (e.cost_estimate_usd || 0), 0);

    const allowed = (localUserSpend < userDailyLimitUsd) && (totalDailySpend < globalLimitUsd);

    return {
        allowed,
        todaySpendUsd: Math.round(localUserSpend * 1000) / 1000,
        dailyLimitUsd: userDailyLimitUsd,
        remainingUsd: Math.max(0, Math.round((userDailyLimitUsd - localUserSpend) * 1000) / 1000),
        globalSpendUsd: Math.round(totalDailySpend * 1000) / 1000,
        globalKillSwitch: false
    };
}

module.exports = {
    DEFAULT_PRICING,
    TIER_DAILY_SPEND_LIMITS,
    getPricing,
    calculateCost,
    recordAiTelemetry,
    checkDailySpendBreaker
};
