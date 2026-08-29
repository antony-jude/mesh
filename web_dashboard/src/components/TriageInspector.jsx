import React, { useState } from 'react';
import { Sparkles, Activity, Lock, ChevronRight, Radio } from 'lucide-react';

export default function TriageInspector({ packet, onDeselect }) {
  const [showRawPayload, setShowRawPayload] = useState(false);

  if (!packet) {
    return (
      <div className="eoc-card" style={{ textAlign: 'center', padding: '40px 20px' }}>
        <Radio size={36} color="#64748b" style={{ margin: '0 auto 12px' }} />
        <h3 style={{ fontFamily: 'Orbitron', fontSize: '13px', color: '#fff' }}>SELECT AN EMERGENCY INCIDENT</h3>
        <p style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px' }}>
          Click any active marker on the map to inspect Gemini Nano's offline triage reasoning.
        </p>
      </div>
    );
  }

  const isCritical = packet.priority_label === 'CRITICAL';
  const priorityColor = isCritical ? '#ef4444' : packet.priority_label === 'HIGH' ? '#f97316' : '#eab308';

  return (
    <div className="eoc-card" style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #1f2c42', paddingBottom: '10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{ padding: '6px', borderRadius: '8px', background: `${priorityColor}22`, border: `1px solid ${priorityColor}` }}>
            <Activity size={18} color={priorityColor} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontFamily: 'Orbitron', fontWeight: 800, fontSize: '14px', color: '#fff' }}>
                {packet.origin_device_id}
              </span>
              <span style={{ fontSize: '10px', fontFamily: 'Orbitron', fontWeight: 700, padding: '2px 8px', borderRadius: '4px', background: `${priorityColor}22`, border: `1px solid ${priorityColor}`, color: priorityColor }}>
                {packet.priority_label}
              </span>
            </div>
            <div style={{ fontSize: '10px', fontFamily: 'Fira Code', color: '#64748b' }}>
              UUID: {packet.packet_id}
            </div>
          </div>
        </div>

        <button
          onClick={onDeselect}
          style={{ fontSize: '11px', color: '#94a3b8', background: '#1e293b', border: 'none', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer' }}
        >
          Clear
        </button>
      </div>

      {/* GEMINI NANO REASONING CARD */}
      <div className="gemini-card">
        <div className="gemini-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Sparkles size={16} color="#c084fc" />
            <span style={{ fontFamily: 'Orbitron', fontWeight: 700, fontSize: '11px', color: '#c084fc', letterSpacing: '0.5px' }}>
              STAGE B — GEMINI NANO REASONING
            </span>
          </div>
          <span style={{ fontSize: '9px', fontFamily: 'Fira Code', fontWeight: 700, padding: '2px 6px', borderRadius: '4px', background: '#a855f733', border: '1px solid #a855f7', color: '#e9d5ff' }}>
            100% OFFLINE (AICORE)
          </span>
        </div>

        <div className="gemini-quote-box">
          "{packet.classification_reasoning}"
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', fontFamily: 'Fira Code', color: '#c084fc' }}>
          <span>Triage Confidence Score:</span>
          <strong style={{ color: '#fff' }}>{(packet.priority_score * 100).toFixed(0)}%</strong>
        </div>
      </div>

      {/* Stage A: Acoustic / Sensor */}
      <div style={{ background: '#07090e', padding: '12px', borderRadius: '10px', border: '1px solid #1f2c42' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
          <span style={{ fontFamily: 'Orbitron', fontWeight: 700, fontSize: '11px', color: '#38bdf8' }}>
            STAGE A — FAST CLASSIFIER
          </span>
          <span style={{ fontSize: '10px', color: '#94a3b8' }}>MediaPipe Audio YAMNet</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
          <div className="metric-box">
            <div className="metric-label">SIGNAL TYPE</div>
            <div className="metric-value" style={{ fontSize: '12px' }}>{packet.signal_type}</div>
          </div>
          <div className="metric-box">
            <div className="metric-label">GPS ACCURACY</div>
            <div className="metric-value" style={{ fontSize: '12px', color: '#22c55e' }}>±{packet.last_known_location?.accuracy_m || 4.2}m</div>
          </div>
        </div>

        {/* Spectrogram Bars */}
        <div style={{ marginTop: '10px' }}>
          <div style={{ fontSize: '9px', color: '#64748b', marginBottom: '4px' }}>ACOUSTIC FREQUENCY SPECTRUM</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '3px', height: '36px', background: '#111622', padding: '4px', borderRadius: '6px' }}>
            {[35, 55, 75, 95, 65, 45, 85, 100, 75, 60, 40, 70, 85, 80, 55, 45, 65, 90, 75, 60].map((v, i) => (
              <div
                key={i}
                style={{ flex: 1, height: `${v}%`, background: 'linear-gradient(to top, #0284c7, #38bdf8)', borderRadius: '2px' }}
              ></div>
            ))}
          </div>
        </div>
      </div>

      {/* Mesh Hop Path */}
      <div style={{ background: '#07090e', padding: '12px', borderRadius: '10px', border: '1px solid #1f2c42' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
          <span style={{ fontFamily: 'Orbitron', fontWeight: 700, fontSize: '11px', color: '#22c55e' }}>
            STORE-AND-FORWARD MESH PATH
          </span>
          <span style={{ fontSize: '10px', fontFamily: 'Fira Code', color: '#94a3b8' }}>{packet.hop_count} Hops</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '4px' }}>
          {packet.hop_path?.map((node, i) => (
            <React.Fragment key={i}>
              <span style={{
                fontSize: '10px',
                fontFamily: 'Fira Code',
                fontWeight: 'bold',
                padding: '2px 6px',
                borderRadius: '4px',
                background: i === 0 ? '#ef444422' : i === packet.hop_path.length - 1 ? '#22c55e22' : '#38bdf822',
                color: i === 0 ? '#ef4444' : i === packet.hop_path.length - 1 ? '#22c55e' : '#38bdf8',
                border: `1px solid ${i === 0 ? '#ef4444' : i === packet.hop_path.length - 1 ? '#22c55e' : '#38bdf8'}`
              }}>
                {node}
              </span>
              {i < packet.hop_path.length - 1 && <ChevronRight size={12} color="#64748b" />}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* AES Payload View Toggle */}
      <div>
        <button
          onClick={() => setShowRawPayload(!showRawPayload)}
          style={{
            width: '100%',
            padding: '8px 12px',
            background: '#162032',
            border: '1px solid #263550',
            borderRadius: '8px',
            color: '#94a3b8',
            fontSize: '11px',
            fontFamily: 'Fira Code',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            cursor: 'pointer'
          }}
        >
          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Lock size={12} color="#38bdf8" /> AES-256 Encrypted Mesh Payload
          </span>
          <span style={{ color: '#38bdf8' }}>{showRawPayload ? 'HIDE' : 'VIEW RAW JSON'}</span>
        </button>

        {showRawPayload && (
          <pre style={{ marginTop: '8px', padding: '10px', background: '#07090e', borderRadius: '8px', border: '1px solid #1f2c42', fontSize: '9px', fontFamily: 'Fira Code', color: '#38bdf8', overflowX: 'auto' }}>
            {JSON.stringify(packet, null, 2)}
          </pre>
        )}
      </div>

    </div>
  );
}
