import React, { useRef, useEffect, useState } from 'react';
import { Layers, ShieldCheck } from 'lucide-react';

export default function TopologyVisualizer({ activePacket, allPackets }) {
  const canvasRef = useRef(null);
  const [selectedNode, setSelectedNode] = useState('VICTIM_NODE_01');

  const nodes = [
    { id: 'VICTIM_NODE_01', label: 'Victim Device (Mic/Tap)', role: 'VICTIM', x: 100, y: 190, color: '#ef4444' },
    { id: 'RELAY_NODE_ALPHA', label: 'Relay Node Alpha (Hop 1)', role: 'RELAY', x: 300, y: 110, color: '#38bdf8' },
    { id: 'RELAY_NODE_BETA', label: 'Relay Node Beta (Hop 2)', role: 'RELAY', x: 500, y: 190, color: '#38bdf8' },
    { id: 'GATEWAY_NODE_01', label: 'Gateway Node (Wi-Fi Bridge)', role: 'GATEWAY', x: 700, y: 110, color: '#22c55e' },
    { id: 'FIREBASE_CLOUD', label: 'EOC Firestore Command Cloud', role: 'CLOUD', x: 880, y: 190, color: '#a855f7' },
  ];

  const links = [
    { source: 'VICTIM_NODE_01', target: 'RELAY_NODE_ALPHA', rssi: '-54 dBm', latency: '38ms' },
    { source: 'RELAY_NODE_ALPHA', target: 'RELAY_NODE_BETA', rssi: '-62 dBm', latency: '44ms' },
    { source: 'RELAY_NODE_BETA', target: 'GATEWAY_NODE_01', rssi: '-59 dBm', latency: '41ms' },
    { source: 'GATEWAY_NODE_01', target: 'FIREBASE_CLOUD', rssi: 'Wi-Fi 6', latency: '18ms' },
  ];

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let animationFrameId;
    let particleOffset = 0;

    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Draw Links
      links.forEach((link) => {
        const src = nodes.find(n => n.id === link.source);
        const tgt = nodes.find(n => n.id === link.target);
        if (!src || !tgt) return;

        ctx.beginPath();
        ctx.moveTo(src.x, src.y);
        ctx.lineTo(tgt.x, tgt.y);
        ctx.strokeStyle = '#202b3f';
        ctx.lineWidth = 3;
        ctx.stroke();

        // Pulsing line
        ctx.beginPath();
        ctx.moveTo(src.x, src.y);
        ctx.lineTo(tgt.x, tgt.y);
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
        ctx.lineWidth = 1.5;
        ctx.setLineDash([8, 8]);
        ctx.lineDashOffset = -particleOffset * 2;
        ctx.stroke();
        ctx.setLineDash([]);

        // Animated Particle
        const progress = (particleOffset % 100) / 100;
        const px = src.x + (tgt.x - src.x) * progress;
        const py = src.y + (tgt.y - src.y) * progress;

        ctx.beginPath();
        ctx.arc(px, py, 5, 0, Math.PI * 2);
        ctx.fillStyle = '#ef4444';
        ctx.shadowColor = '#ef4444';
        ctx.shadowBlur = 10;
        ctx.fill();
        ctx.shadowBlur = 0;

        // Metric Text
        const midX = (src.x + tgt.x) / 2;
        const midY = (src.y + tgt.y) / 2 - 12;
        ctx.font = '10px Fira Code';
        ctx.fillStyle = '#94a3b8';
        ctx.textAlign = 'center';
        ctx.fillText(`${link.rssi} | ${link.latency}`, midX, midY);
      });

      // Draw Nodes
      nodes.forEach((node) => {
        const isSelected = selectedNode === node.id;

        ctx.beginPath();
        ctx.arc(node.x, node.y, 26, 0, Math.PI * 2);
        ctx.fillStyle = isSelected ? `${node.color}33` : '#111622';
        ctx.strokeStyle = node.color;
        ctx.lineWidth = isSelected ? 3 : 2;
        ctx.fill();
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(node.x, node.y, 12, 0, Math.PI * 2);
        ctx.fillStyle = node.color;
        ctx.fill();

        ctx.font = 'bold 11px Orbitron';
        ctx.fillStyle = '#ffffff';
        ctx.textAlign = 'center';
        ctx.fillText(node.id, node.x, node.y + 42);

        ctx.font = '10px Inter';
        ctx.fillStyle = '#94a3b8';
        ctx.fillText(node.role, node.x, node.y + 56);
      });

      particleOffset += 0.8;
      animationFrameId = requestAnimationFrame(render);
    };

    render();
    return () => cancelAnimationFrame(animationFrameId);
  }, [selectedNode]);

  const selectedNodeData = nodes.find(n => n.id === selectedNode);

  return (
    <div className="eoc-card">
      <div className="eoc-card-header">
        <div>
          <div className="eoc-card-title">
            <Layers size={18} color="#38bdf8" />
            <span>DYNAMIC MESH TOPOLOGY GRAPH</span>
          </div>
          <div className="eoc-card-subtitle">
            Google Nearby Connections P2P_CLUSTER • Store-and-Forward Mesh Relay
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', fontSize: '12px', fontFamily: 'Fira Code' }}>
          <span style={{ color: '#38bdf8' }}>● 4 Active Hops</span>
          <span style={{ color: '#22c55e', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <ShieldCheck size={14} /> AES-256
          </span>
        </div>
      </div>

      <div style={{ background: '#07090e', borderRadius: '10px', height: '360px', border: '1px solid #1f2c42', position: 'relative', overflow: 'hidden' }}>
        <canvas
          ref={canvasRef}
          width={1000}
          height={360}
          style={{ width: '100%', height: '100%', cursor: 'pointer' }}
        />
      </div>

      {selectedNodeData && (
        <div style={{ marginTop: '14px', padding: '12px', background: '#0a0d14', borderRadius: '8px', border: '1px solid #1f2c42', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ width: 10, height: 10, borderRadius: '50%', background: selectedNodeData.color }}></span>
              <strong style={{ fontFamily: 'Orbitron', fontSize: '13px', color: '#fff' }}>{selectedNodeData.id}</strong>
              <span style={{ fontSize: '10px', background: '#1e293b', padding: '2px 6px', borderRadius: '4px', color: '#94a3b8' }}>{selectedNodeData.role}</span>
            </div>
            <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>{selectedNodeData.label}</div>
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <div className="metric-box">
              <div className="metric-label">PROTOCOL</div>
              <div className="metric-value" style={{ fontSize: '11px' }}>Nearby P2P</div>
            </div>
            <div className="metric-box">
              <div className="metric-label">DEDUPLICATION</div>
              <div className="metric-value" style={{ fontSize: '11px', color: '#22c55e' }}>UUID Active</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
