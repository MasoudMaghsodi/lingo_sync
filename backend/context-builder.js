// backend/context-builder.js
// 3-Tier Budgeted Context Injection for LingoSync AI Mentors (500-800 tokens budget)

/**
 * Builds a strict 3-tier budgeted context string.
 * Tier 1: Immediate Mission (Day, Today's video/grammar, Due cards)
 * Tier 2: Recent Performance (Streak, Score, Last 3 tasks, Last 8 words)
 * Tier 3: Persistent Learner Identity (Name, Level, Goals)
 */
function buildThreeTierContext(ctx) {
    const profile = ctx?.profile || {};
    const stats = ctx?.stats || {};
    const currentDay = ctx?.currentDay ?? stats.current_day ?? 1;

    // TIER 3: Persistent Learner Identity (~100 tokens)
    const name = profile.full_name || 'Learner';
    const level = profile.english_level || 'B2';
    const targetExam = profile.target_exam || 'TOEFL / IELTS';
    const tier3 = `[LEARNER PROFILE] Name: ${name} | CEFR: ${level} | Target: ${targetExam} | Native: Persian`;

    // TIER 1: Immediate Mission (~250 tokens)
    const pendingDue = ctx?.pendingVocabCount ?? 0;
    const todayTasks = (ctx?.todayTasks || []).slice(0, 3)
        .map(t => `${t.task_type}: ${t.title}`)
        .join('; ');
    const videoSummary = (ctx?.watchedVideoSummaries || []).slice(0, 1)
        .map(v => `${v.title || v.video_id}: ${v.summary ? v.summary.substring(0, 140) : 'General'}`)
        .join('');
    const tier1 = `[TODAY'S MISSION - DAY ${currentDay}] Tasks: ${todayTasks || 'None'} | Due Flashcards: ${pendingDue} | Video: ${videoSummary || 'Standard'}`;

    // TIER 2: Recent Performance & Active Recall Targets (~250 tokens)
    const streak = stats.streak_days ?? 0;
    const score = stats.score ?? 0;
    const recentTasks = (ctx?.completedTasks || []).slice(0, 3)
        .map(t => `Day ${t.day_number}: ${t.title}`)
        .join('; ');
    const recentWords = (ctx?.learnedWords || []).slice(0, 8).join(', ');
    const recallRaidTargets = (ctx?.dueWords || []).slice(0, 3).join(', ');
    const knownErrors = (ctx?.errorPatterns || []).slice(0, 3).join('; ');

    const tier2 = `[RECENT PERFORMANCE] Streak: ${streak} days | Score: ${score} XP | Recent Done: ${recentTasks || 'None'} | Known Words: ${recentWords || 'None'}${recallRaidTargets ? ` | Active Recall Targets: ${recallRaidTargets}` : ''}${knownErrors ? ` | Weaknesses: ${knownErrors}` : ''}`;

    return `${tier3}\n${tier1}\n${tier2}`;
}

function buildMentorLiveSystemPrompt(ctx) {
    const contextBlock = buildThreeTierContext(ctx);

    return `You are "LingoMentor", an elite, empathetic, and encouraging English speaking coach in LingoSync. You are an AI mentor (never claim to be a human).
Language Policy: Speak in English by default. If the learner is A1-B1 or explicitly asks in Persian, use Persian explanations with English examples. If B2-C1, speak exclusively in natural English.

${contextBlock}

CRITICAL PEDAGOGICAL & ECONOMY RULES:
1. TALK RATIO ECONOMY (CRITICAL): Speak at most 30-35% of the total session time. Keep every turn to 1 or 2 concise, crisp sentences followed by an open-ended question to elicit learner speech.
2. DELAYED CORRECTION: In live audio, do NOT interrupt or over-correct. Use at most ONE gentle implicit recast per minute (e.g. Learner: "I go to store yesterday." -> You: "Nice, so you went to the store! What did you buy?"). Explicit error breakdowns belong in the final session card.
3. CODE-SWITCH RESCUE: If the learner uses a Persian word inside an English sentence, immediately provide the natural English equivalent smoothly without breaking flow (e.g., "Ah, 'appointment'—carry on!").
4. ACTIVE RECALL RAID: Seamlessly prompt the student to use one of their active recall target words without directly giving it away.

SAFETY & WELLBEING GUARDRAILS (ABSOLUTE):
- You are an educational AI tutor. Never provide medical diagnosis, legal advice, or official visa outcome guarantees.
- SELF-HARM / ACUTE CRISIS: If the learner mentions self-harm, suicide, or acute psychological crisis, IMMEDIATELY SUSPEND THE LESSON. Respond warmly, gently, and supportively in Persian:
  "متوجه ناراحتی و فشار روحی‌ات هستم، سلامت روان و امنیت تو از یادگیری زبان خیلی مهم‌تره. لطفاً با یکی از افراد نزدیک یا مشاوران متخصص گفتگو کن. من اینجام و همیشه با احترام در کنارت هستم."
  Do not lecture, analyze, or continue the English lesson.`;
}

module.exports = {
    buildThreeTierContext,
    buildMentorLiveSystemPrompt
};
