// Stage A: Fast Acoustic Classifier (MediaPipe Audio / YAMNet Allowlist)

export const DISTRESS_ALLOWLIST = [
  { id: 'RUBBLE_TAP', label: 'Rubble Tapping / Knock', baseWeight: 0.94, defaultPriority: 'HIGH', soundType: 'mechanical' },
  { id: 'CRYING_SOBBING', label: 'Crying, sobbing', baseWeight: 0.91, defaultPriority: 'HIGH', soundType: 'vocal' },
  { id: 'SCREAM_DISTRESS', label: 'Screaming / Distress Shout', baseWeight: 0.96, defaultPriority: 'CRITICAL', soundType: 'vocal' },
  { id: 'STRUCTURAL_COLLAPSE', label: 'Structural Creaking / Collapse', baseWeight: 0.97, defaultPriority: 'CRITICAL', soundType: 'environmental' },
  { id: 'GLASS_BREAK', label: 'Glass Shatter / Impact', baseWeight: 0.78, defaultPriority: 'MEDIUM', soundType: 'mechanical' },
  { id: 'GROAN_LABORED', label: 'Groan / Labored Breathing', baseWeight: 0.85, defaultPriority: 'HIGH', soundType: 'vocal' },
  { id: 'AMBIENT_NORMAL', label: 'Normal Ambient Urban Noise', baseWeight: 0.18, defaultPriority: 'LOW', soundType: 'benign' }
];

export function runStageAClassifier(categoryLabel, rawConfidence = 0.92) {
  const match = DISTRESS_ALLOWLIST.find(d => d.label === categoryLabel || d.id === categoryLabel) || DISTRESS_ALLOWLIST[0];
  const isDistress = match.baseWeight > 0.5 && rawConfidence >= 0.60;

  return {
    category: match.label,
    categoryId: match.id,
    confidence: rawConfidence,
    isDistressRelevant: isDistress,
    soundType: match.soundType
  };
}
