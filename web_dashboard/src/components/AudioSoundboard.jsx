import React, { useState } from 'react';
import { Volume2, Play } from 'lucide-react';
import { DISTRESS_ALLOWLIST, runStageAClassifier } from '../utils/audioClassifier';
import { runGeminiNanoReasoning } from '../utils/geminiNano';

export default function AudioSoundboard({ onTriggerAcousticSos }) {
  const [activeCategory, setActiveCategory] = useState(null);
  const [isClassifying, setIsClassifying] = useState(false);

  const handleTrigger = (item) => {
    setActiveCategory(item.id);
    setIsClassifying(true);

    setTimeout(() => {
      const stageA = runStageAClassifier(item.label, 0.93);
      const stageB = runGeminiNanoReasoning(stageA);

      onTriggerAcousticSos({
        packet_id: `pkt_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
        origin_device_id: 'VICTIM_NODE_01',
        timestamp: new Date().toISOString(),
        hop_count: 0,
        hop_path: ['VICTIM_NODE_01'],
        priority_score: stageB.priority_score,
        priority_label: stageB.priority_label,
        signal_type: 'ACOUSTIC',
        classification_reasoning: stageB.reasoning,
        last_known_location: { lat: 37.7825, lng: -122.4075, accuracy_m: 3.8 },
        payload_encrypted: true
      });

      setIsClassifying(false);
    }, 600);
  };

  return (
    <div className="eoc-card">
      <div className="eoc-card-header">
        <div className="eoc-card-title">
          <Volume2 size={16} color="#38bdf8" />
          <span>STAGE A: ACOUSTIC ML SOUNDBOARD</span>
        </div>
        <span style={{ fontSize: '10px', color: '#94a3b8' }}>Zero-Action Passive Mic</span>
      </div>

      <div className="soundboard-grid">
        {DISTRESS_ALLOWLIST.map((item) => (
          <button
            key={item.id}
            onClick={() => handleTrigger(item)}
            disabled={isClassifying}
            className={`soundboard-btn ${activeCategory === item.id && isClassifying ? 'active' : ''}`}
          >
            <div>
              <div style={{ fontSize: '11px', fontWeight: 'bold' }}>{item.label}</div>
              <div style={{ fontSize: '9px', fontFamily: 'Fira Code', color: '#64748b', marginTop: '2px' }}>
                Weight: {item.baseWeight}
              </div>
            </div>
            <Play size={14} color="#38bdf8" />
          </button>
        ))}
      </div>
    </div>
  );
}
