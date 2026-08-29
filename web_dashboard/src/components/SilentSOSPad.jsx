import React, { useState, useEffect } from 'react';
import { Fingerprint } from 'lucide-react';

export default function SilentSOSPad({ onTriggerSilentSos }) {
  const [tapCount, setTapCount] = useState(0);
  const [isTriggered, setIsTriggered] = useState(false);

  useEffect(() => {
    if (tapCount > 0 && tapCount < 4) {
      const timer = setTimeout(() => {
        setTapCount(0);
      }, 4000);
      return () => clearTimeout(timer);
    }
  }, [tapCount]);

  const handleTap = () => {
    const nextCount = tapCount + 1;
    setTapCount(nextCount);

    if (nextCount >= 4) {
      setIsTriggered(true);
      onTriggerSilentSos({
        packet_id: `pkt_silent_${Date.now()}`,
        origin_device_id: 'VICTIM_NODE_01',
        timestamp: new Date().toISOString(),
        hop_count: 0,
        hop_path: ['VICTIM_NODE_01'],
        priority_score: 1.0,
        priority_label: 'CRITICAL',
        signal_type: 'TAP_PATTERN',
        classification_reasoning: 'Silent SOS Triggered: Accelerometer rhythmic pattern (3-Short + 1-Long Morse distress) verified. Victim incapacitated/unable to speak. Immediate critical dispatch.',
        last_known_location: { lat: 37.7825, lng: -122.4075, accuracy_m: 3.5 },
        payload_encrypted: true
      });

      setTimeout(() => {
        setTapCount(0);
        setIsTriggered(false);
      }, 2500);
    }
  };

  return (
    <div className="eoc-card">
      <div className="eoc-card-header">
        <div className="eoc-card-title">
          <Fingerprint size={16} color="#ef4444" />
          <span>STAGE C: SILENT SOS TAP DETECTOR</span>
        </div>
        <span style={{ fontSize: '10px', color: '#ef4444', fontWeight: 'bold' }}>Incapacitated Rescue</span>
      </div>

      <div style={{ fontSize: '11px', color: '#94a3b8', lineHeight: 1.4 }}>
        Rhythmic accelerometer peak detection. Tap 3 Short + 1 Long to trigger instant CRITICAL dispatch.
      </div>

      {/* Steps Row */}
      <div className="tap-progress-row">
        {[
          { label: 'SHORT', num: 1 },
          { label: 'SHORT', num: 2 },
          { label: 'SHORT', num: 3 },
          { label: 'LONG', num: 4 },
        ].map((step) => (
          <div
            key={step.num}
            className={`tap-step-pill ${tapCount >= step.num ? 'active' : ''}`}
          >
            <div style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '11px' }}>{step.num}</div>
            <div style={{ fontSize: '8px' }}>{step.label}</div>
          </div>
        ))}
      </div>

      {/* Interactive Big Button */}
      <button onClick={handleTap} className="big-tap-btn">
        <Fingerprint size={20} color="#ef4444" />
        <span>
          {isTriggered
            ? 'SILENT SOS BROADCASTED!'
            : tapCount > 0
            ? `TAP RECORDED (${tapCount}/4)`
            : 'TAP RHYTHM HERE (SIMULATE ACCELEROMETER)'}
        </span>
      </button>
    </div>
  );
}
