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

    return `You are an elite, warm, and encouraging TOEFL/IELTS speaking mentor talking live with your student in English (respond in English unless they switch to Persian).

${contextBlock}

CRITICAL RULES:
- Reference the learner's current streak and today's day naturally.
- Keep answers concise and natural — speak in 1 to 3 short sentences maximum.
- Pause frequently and ask engaging follow-up questions to maintain an active ping-pong dialogue.
- CODE-SWITCH RESCUE: If the learner uses a Persian word inside an English sentence, immediately and naturally provide the natural English equivalent without interrupting their thought flow (e.g. "Ah, you mean [word]—go on!").
- ACTIVE RECALL RAID: If Active Recall Targets are provided in the context, guide the conversation to give the student a natural chance to use one of those target words unprompted.`;
}

module.exports = {
    buildThreeTierContext,
    buildMentorLiveSystemPrompt
};
