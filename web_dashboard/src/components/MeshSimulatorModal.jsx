import React, { useState } from 'react';
import { X, Smartphone, Play, Cloud } from 'lucide-react';
import { DISTRESS_ALLOWLIST, runStageAClassifier } from '../utils/audioClassifier';
import { runGeminiNanoReasoning } from '../utils/geminiNano';

export default function MeshSimulatorModal({ isOpen, onClose, onSyncPacketToDashboard }) {
  if (!isOpen) return null;

  const [victimAudio, setVictimAudio] = useState(DISTRESS_ALLOWLIST[0]);
  const [victimPacket, setVictimPacket] = useState(null);
  
  const [relayLogs, setRelayLogs] = useState([]);
  const [relayPacket, setRelayPacket] = useState(null);

  const [gatewayQueue, setGatewayQueue] = useState([]);
  const [gatewayLogs, setGatewayLogs] = useState([]);
  const [isGatewayOnline, setIsGatewayOnline] = useState(false);

  const handleVictimTrigger = () => {
    const stageA = runStageAClassifier(victimAudio.label, 0.94);
    const stageB = runGeminiNanoReasoning(stageA);

    const packet = {
      packet_id: `pkt_${Date.now().toString().slice(-6)}`,
      origin_device_id: 'PHONE_1_VICTIM',
      timestamp: new Date().toISOString(),
      hop_count: 0,
      hop_path: ['PHONE_1_VICTIM'],
      priority_score: stageB.priority_score,
      priority_label: stageB.priority_label,
      signal_type: 'ACOUSTIC',
      classification_reasoning: stageB.reasoning,
      last_known_location: { lat: 37.7825, lng: -122.4075, accuracy_m: 3.2 },
      payload_encrypted: true
    };

    setVictimPacket(packet);

    setTimeout(() => {
      handleRelayReceive(packet);
    }, 700);
  };

  const handleRelayReceive = (pkt) => {
    const relayed = {
      ...pkt,
      hop_count: pkt.hop_count + 1,
      hop_path: [...pkt.hop_path, 'PHONE_2_RELAY']
    };

    setRelayPacket(relayed);
    setRelayLogs(prev => [
      `[HOP ${relayed.hop_count}] Relayed packet ${relayed.packet_id} to Gateway`,
      ...prev
    ]);

    setTimeout(() => {
      handleGatewayReceive(relayed);
    }, 700);
  };

  const handleGatewayReceive = (pkt) => {
    const gatewayReceived = {
      ...pkt,
      hop_count: pkt.hop_count + 1,
      hop_path: [...pkt.hop_path, 'PHONE_3_GATEWAY']
    };

    setGatewayQueue(prev => [gatewayReceived, ...prev]);
    setGatewayLogs(prev => [
      `[GATEWAY] Queued packet ${gatewayReceived.packet_id} (Awaiting Internet sync)`,
      ...prev
    ]);

    if (isGatewayOnline) {
      handleGatewaySync(gatewayReceived);
    }
  };

  const handleGatewaySync = (pkt) => {
    const target = pkt || gatewayQueue[0];
    if (!target) return;

    setGatewayLogs(prev => [
      `[FIRESTORE SYNC] Batch uploaded packet ${target.packet_id} to Cloud EOC!`,
      ...prev
    ]);

    onSyncPacketToDashboard(target);
    setGatewayQueue(prev => prev.filter(p => p.packet_id !== target.packet_id));
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        
        {/* Header */}
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <Smartphone size={22} color="#a855f7" />
            <div>
              <h2 style={{ fontFamily: 'Orbitron', fontWeight: 800, fontSize: '15px', color: '#fff' }}>
                3-PHONE LIVE MESH TESTBED & DEMO HARNESS
              </h2>
              <div style={{ fontSize: '11px', color: '#94a3b8' }}>
                Simulates Phone 1 (Victim) → Phone 2 (Relay) → Phone 3 (Gateway) in Airplane Mode
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            style={{ background: '#162032', border: '1px solid #202b3f', color: '#fff', borderRadius: '8px', padding: '6px', cursor: 'pointer' }}
          >
            <X size={18} />
          </button>
        </div>

        {/* 3 Phones Grid */}
        <div className="modal-body">
          
          {/* PHONE 1: VICTIM */}
          <div className="phone-simulator-card" style={{ borderColor: 'rgba(239, 68, 68, 0.4)' }}>
            <div className="phone-header">
              <span style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px', color: '#ef4444' }}>
                PHONE 1: VICTIM
              </span>
              <span style={{ fontSize: '9px', fontFamily: 'Fira Code', padding: '2px 6px', borderRadius: '4px', background: '#ef444422', color: '#ef4444' }}>
                AIRPLANE MODE
              </span>
            </div>

            <div style={{ fontSize: '11px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ color: '#94a3b8' }}>Passive Mic Audio Sample:</label>
              <select
                value={victimAudio.id}
                onChange={(e) => setVictimAudio(DISTRESS_ALLOWLIST.find(d => d.id === e.target.value))}
                style={{ padding: '8px', background: '#0a0d14', border: '1px solid #1f2c42', color: '#fff', borderRadius: '6px', fontSize: '11px' }}
              >
                {DISTRESS_ALLOWLIST.map(d => (
                  <option key={d.id} value={d.id}>{d.label}</option>
                ))}
              </select>

              <button
                onClick={handleVictimTrigger}
                style={{
                  padding: '10px',
                  background: '#ef4444',
                  border: 'none',
                  borderRadius: '6px',
                  color: '#fff',
                  fontFamily: 'Orbitron',
                  fontWeight: 'bold',
                  fontSize: '11px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px'
                }}
              >
                <Play size={12} /> Run On-Device Triage
              </button>
            </div>

            {victimPacket && (
              <div style={{ padding: '8px', background: '#0a0d14', borderRadius: '6px', border: '1px solid rgba(239,68,68,0.3)', fontSize: '11px' }}>
                <div style={{ fontWeight: 'bold', color: '#ef4444' }}>
                  Gemini Nano: [{victimPacket.priority_label}]
                </div>
                <div style={{ fontStyle: 'italic', color: '#94a3b8', fontSize: '10px', marginTop: '2px' }}>
                  "{victimPacket.classification_reasoning}"
                </div>
              </div>
            )}
          </div>

          {/* PHONE 2: RELAY */}
          <div className="phone-simulator-card" style={{ borderColor: 'rgba(56, 189, 248, 0.4)' }}>
            <div className="phone-header">
              <span style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px', color: '#38bdf8' }}>
                PHONE 2: RELAY
              </span>
              <span style={{ fontSize: '9px', fontFamily: 'Fira Code', padding: '2px 6px', borderRadius: '4px', background: '#38bdf822', color: '#38bdf8' }}>
                STORE & FORWARD
              </span>
            </div>

            <div style={{ fontSize: '11px', color: '#94a3b8' }}>
              Nearby Connections Hop Dedupe
            </div>

            <div className="phone-log-box">
              {relayLogs.length === 0 ? 'Waiting for BLE packets...' : relayLogs.map((l, i) => (
                <div key={i} style={{ color: '#38bdf8', marginBottom: '2px' }}>{l}</div>
              ))}
            </div>
          </div>

          {/* PHONE 3: GATEWAY */}
          <div className="phone-simulator-card" style={{ borderColor: 'rgba(34, 197, 94, 0.4)' }}>
            <div className="phone-header">
              <span style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px', color: '#22c55e' }}>
                PHONE 3: GATEWAY
              </span>
              <button
                onClick={() => {
                  const newState = !isGatewayOnline;
                  setIsGatewayOnline(newState);
                  if (newState && gatewayQueue.length > 0) {
                    handleGatewaySync(gatewayQueue[0]);
                  }
                }}
                style={{
                  fontSize: '9px',
                  fontFamily: 'Fira Code',
                  fontWeight: 'bold',
                  padding: '2px 8px',
                  borderRadius: '4px',
                  border: 'none',
                  cursor: 'pointer',
                  background: isGatewayOnline ? '#22c55e' : '#ef444433',
                  color: isGatewayOnline ? '#07090e' : '#ef4444'
                }}
              >
                {isGatewayOnline ? 'WI-FI CONNECTED' : 'AIRPLANE MODE'}
              </button>
            </div>

            <div style={{ fontSize: '11px', display: 'flex', justifyContent: 'space-between', color: '#94a3b8' }}>
              <span>Queued Packets:</span>
              <strong style={{ color: '#fff', fontFamily: 'Fira Code' }}>{gatewayQueue.length}</strong>
            </div>

            <button
              onClick={() => handleGatewaySync()}
              disabled={gatewayQueue.length === 0 || !isGatewayOnline}
              style={{
                padding: '10px',
                background: gatewayQueue.length > 0 && isGatewayOnline ? '#22c55e' : '#162032',
                color: gatewayQueue.length > 0 && isGatewayOnline ? '#07090e' : '#64748b',
                fontFamily: 'Orbitron',
                fontWeight: 'bold',
                fontSize: '11px',
                border: 'none',
                borderRadius: '6px',
                cursor: gatewayQueue.length > 0 && isGatewayOnline ? 'pointer' : 'not-allowed',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '6px'
              }}
            >
              <Cloud size={14} /> Flush to Firestore Cloud
            </button>

            <div className="phone-log-box">
              {gatewayLogs.length === 0 ? 'No gateway events.' : gatewayLogs.map((l, i) => (
                <div key={i} style={{ color: '#22c55e', marginBottom: '2px' }}>{l}</div>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
