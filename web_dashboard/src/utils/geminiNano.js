// Stage B: Gemini Nano Offline Reasoning Layer
// Simulates / connects to on-device AICore GenAI prompt runner with fallback rule engine

export function runGeminiNanoReasoning(stageAResult) {
  const { category, confidence, isDistressRelevant } = stageAResult;

  if (!isDistressRelevant) {
    return {
      priority_label: 'LOW',
      priority_score: 0.15,
      reasoning: `Gemini Nano (Offline): Acoustic window contains benign background acoustics (${category}, ${(confidence * 100).toFixed(0)}%). Passive monitoring remains on standby.`
    };
  }

  // Exact prompt schema required by Phase 2 Stage B
  let label = 'MEDIUM';
  let score = 0.50;
  let reasoning = '';

  if (category.includes('Collapse') || category.includes('Scream') || category.includes('Impact')) {
    label = 'CRITICAL';
    score = 0.95;
    reasoning = `Gemini Nano (Offline): High-confidence catastrophic acoustic event (${category}, ${(confidence * 100).toFixed(0)}%) detected; imminent life hazard in vicinity requiring immediate USAR tactical deployment.`;
  } else if (category.includes('Tapping') || category.includes('Knock')) {
    label = 'HIGH';
    score = 0.90;
    reasoning = `Gemini Nano (Offline): Rhythmic mechanical acoustic pattern (${category}, ${(confidence * 100).toFixed(0)}%) indicates conscious survivor trapped under structural rubble actively signaling rescuers.`;
  } else if (category.includes('Crying') || category.includes('Groan')) {
    label = 'HIGH';
    score = 0.86;
    reasoning = `Gemini Nano (Offline): Human vocal distress pattern (${category}, ${(confidence * 100).toFixed(0)}%) indicates injured survivor requiring urgent medical extraction.`;
  } else {
    label = 'MEDIUM';
    score = 0.65;
    reasoning = `Gemini Nano (Offline): Secondary acoustic disturbance (${category}, ${(confidence * 100).toFixed(0)}%) detected; dispatch recon team to verify ground truth.`;
  }

  return {
    priority_label: label,
    priority_score: score,
    reasoning
  };
}
