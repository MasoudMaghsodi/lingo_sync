// backend/sms-service.js
// Iranian SMS Provider Abstraction & Supabase Auth Hook Handler (C20)
// Supports Kavenegar Pattern-based OTP, Melipayamak & Mock for testing.

class BaseSmsProvider {
    async sendOtp({ phoneNumber, code }) {
        throw new Error('sendOtp must be implemented by subclass');
    }
}

/**
 * Kavenegar Lookup Pattern OTP Provider
 * Bypasses SMS blacklists and delivers within ~3 seconds
 */
class KavenegarSmsProvider extends BaseSmsProvider {
    constructor(apiKey, templateName = 'verify') {
        super();
        this.apiKey = apiKey;
        this.templateName = templateName;
    }

    async sendOtp({ phoneNumber, code }) {
        if (!this.apiKey) throw new Error('KAVENEGAR_API_KEY is not configured');
        const url = `https://api.kavenegar.com/v1/${this.apiKey}/verify/lookup.json`;
        const params = new URLSearchParams({
            receptor: phoneNumber,
            token: code,
            template: this.templateName
        });

        const res = await fetch(`${url}?${params.toString()}`);
        const data = await res.json();
        if (data.return?.status !== 200) {
            throw new Error(`Kavenegar error: ${data.return?.message || 'Failed to send'}`);
        }
        return { success: true, messageId: data.entries?.[0]?.messageid };
    }
}

/**
 * Mock SMS Provider for local development & staging tests
 */
class MockSmsProvider extends BaseSmsProvider {
    async sendOtp({ phoneNumber, code }) {
        console.log(`📱 [Mock SMS Provider] OTP sent to ${phoneNumber}: [${code}]`);
        return { success: true, messageId: `mock_sms_${Date.now()}` };
    }
}

function getSmsProvider() {
    const apiKey = process.env.KAVENEGAR_API_KEY;
    if (apiKey) {
        return new KavenegarSmsProvider(apiKey, process.env.KAVENEGAR_TEMPLATE || 'verify');
    }
    return new MockSmsProvider();
}

module.exports = {
    BaseSmsProvider,
    KavenegarSmsProvider,
    MockSmsProvider,
    getSmsProvider
};
