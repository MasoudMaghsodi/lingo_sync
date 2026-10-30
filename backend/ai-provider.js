// backend/ai-provider.js
// Provider Abstraction Layer for LingoSync AI Engines (C08)
// Strictly enforces Gemini 3.x parameter rules: no temperature/top_p, uses thinking_level.

let GoogleGenerativeAI = null;
try {
    GoogleGenerativeAI = require('@google/generative-ai').GoogleGenerativeAI;
} catch (_) {
    // Lazy loaded / mock friendly
}

/**
 * Task priority definitions for model routing
 */
const TASK_ROUTING = {
    // High-stakes pedagogy tasks: NEVER downgrade to Flash-Lite
    HIGH_STAKES: {
        models: ['gemini-3.8-flash', 'gemini-3.6-flash'],
        thinkingLevels: { 'gemini-3.8-flash': 'HIGH', 'gemini-3.6-flash': 'MEDIUM' },
        timeoutMs: 12000
    },
    // Standard tasks (Council viewpoints, transcript analysis, etc.)
    STANDARD: {
        models: ['gemini-3.8-flash', 'gemini-3.6-flash', 'gemini-3.5-flash-lite'],
        thinkingLevels: { 'gemini-3.8-flash': 'MEDIUM', 'gemini-3.6-flash': 'MEDIUM', 'gemini-3.5-flash-lite': 'LOW' },
        timeoutMs: 9000
    },
    // Light tasks (Micro-quiz, simple definitions, fast metadata)
    LIGHT: {
        models: ['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'],
        thinkingLevels: { 'gemini-3.5-flash-lite': 'LOW', 'gemini-3.1-flash-lite': 'LOW' },
        timeoutMs: 6000
    }
};

class BaseTextLLMProvider {
    async generateText({ prompt, taskType = 'STANDARD', systemInstruction = null }) {
        throw new Error('generateText must be implemented by subclass');
    }
}

class GeminiTextLLMProvider extends BaseTextLLMProvider {
    constructor(apiKey) {
        super();
        this.apiKey = apiKey;
        this.genAI = (apiKey && typeof GoogleGenerativeAI === 'function') ? new GoogleGenerativeAI(apiKey) : null;
    }

    /**
     * Sanitizes generation config for Gemini 3.x models
     * Strips temperature, topP, topK, candidateCount and sets thinkingConfig
     */
    buildGemini3GenerationConfig(modelName, thinkingLevel = 'MEDIUM') {
        const config = {};
        // Gemini 3.8/3.6/3.5/3.1 support thinkingConfig
        if (modelName.startsWith('gemini-3')) {
            config.thinkingConfig = {
                thinkingLevel: thinkingLevel || 'MEDIUM'
            };
        }
        return config;
    }

    async generateText({ prompt, taskType = 'STANDARD', systemInstruction = null }) {
        if (!this.genAI) {
            throw new Error('Gemini API key is not configured');
        }

        const routing = TASK_ROUTING[taskType] || TASK_ROUTING.STANDARD;
        let lastError = null;
        let fallbackTriggered = false;
        const startTime = Date.now();

        for (let i = 0; i < routing.models.length; i++) {
            const modelName = routing.models[i];
            if (i > 0) fallbackTriggered = true;

            const thinkingLevel = routing.thinkingLevels[modelName] || 'MEDIUM';
            const generationConfig = this.buildGemini3GenerationConfig(modelName, thinkingLevel);

            try {
                const modelParams = {
                    model: modelName,
                    generationConfig
                };
                if (systemInstruction) {
                    modelParams.systemInstruction = systemInstruction;
                }

                const model = this.genAI.getGenerativeModel(modelParams);

                // Timeout wrapper
                const result = await Promise.race([
                    model.generateContent(prompt),
                    new Promise((_, reject) =>
                        setTimeout(() => reject(new Error(`Timeout on ${modelName} after ${routing.timeoutMs}ms`)), routing.timeoutMs)
                    )
                ]);

                const text = result.response.text();
                const latencyMs = Date.now() - startTime;

                return {
                    text,
                    model: modelName,
                    fallbackTriggered,
                    latencyMs,
                    tokensIn: Math.round(prompt.length / 4),
                    tokensOut: Math.round(text.length / 4)
                };
            } catch (err) {
                console.warn(`⚠️ [AI Provider] Model ${modelName} failed for task ${taskType}:`, err.message);
                lastError = err;
            }
        }

        throw new Error(`All candidate models failed for ${taskType}. Last error: ${lastError?.message}`);
    }
}

/**
 * Mock Text LLM Provider for unit tests (Never calls paid endpoints)
 */
class MockTextLLMProvider extends BaseTextLLMProvider {
    constructor(fixtures = {}) {
        super();
        this.fixtures = fixtures;
    }

    async generateText({ prompt, taskType = 'STANDARD' }) {
        return {
            text: this.fixtures[taskType] || 'Mock response for testing purposes',
            model: 'mock-gemini-3.8-flash',
            fallbackTriggered: false,
            latencyMs: 15,
            tokensIn: 50,
            tokensOut: 40
        };
    }
}

module.exports = {
    TASK_ROUTING,
    BaseTextLLMProvider,
    GeminiTextLLMProvider,
    MockTextLLMProvider
};
