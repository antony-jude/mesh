import React, { useState } from 'react';
import { ShieldAlert, Plus, Trash2, Sliders } from 'lucide-react';

export default function HazardControlPanel({
  hazardZones,
  onAddHazard,
  onRemoveHazard,
  onUpdatePenalty,
  dijkstraSafeRoute,
  naiveRoute
}) {
  const [newTitle, setNewTitle] = useState('');

  const handleAdd = (e) => {
    e.preventDefault();
    if (!newTitle) return;

    onAddHazard({
      id: `HAZ_${Date.now().toString().slice(-4)}`,
      title: newTitle,
      type: 'COLLAPSED_BRIDGE',
      severity: 'CRITICAL',
      lat: 37.7760 + (Math.random() - 0.5) * 0.005,
      lng: -122.4130 + (Math.random() - 0.5) * 0.005,
      radius: 250,
      penaltyMultiplier: 50,
      isImpassable: false,
      color: '#ef4444'
    });

    setNewTitle('');
  };

  return (
    <div className="eoc-card">
      {/* Title */}
      <div className="eoc-card-header">
        <div>
          <div className="eoc-card-title">
            <ShieldAlert size={18} color="#f97316" />
            <span>PHASE 4: HAZARD-AWARE RESCUE ROUTING ENGINE</span>
          </div>
          <div className="eoc-card-subtitle">
            Dijkstra Min-Heap Algorithm • Dynamic Disaster Polygon Penalty Weighting
          </div>
        </div>
      </div>

      {/* Side-by-Side Algorithm Comparison Cards */}
      <div className="route-grid">
        
        {/* Naive Path Card */}
        <div className="route-card naive">
          <div className="route-header">
            <span className="route-title" style={{ color: '#ef4444' }}>
              NAIVE ROAD PATH
            </span>
            <span style={{ fontSize: '9px', fontWeight: 'bold', padding: '2px 6px', borderRadius: '4px', background: '#ef444422', color: '#ef4444' }}>
              STANDARD ROUTE
            </span>
          </div>

          <div className="route-metrics-row">
            <div className="metric-box">
              <div className="metric-label">DISTANCE</div>
              <div className="metric-value">{naiveRoute?.distanceMeters || 1391}m</div>
            </div>
            <div className="metric-box">
              <div className="metric-label">EST. DURATION</div>
              <div className="metric-value">{naiveRoute?.estimatedTimeMin || 5.6} min</div>
            </div>
          </div>

          <div className="route-warning-box danger">
            ⚠️ Traverses active hazard zone! High risk of rescuer entrapment.
          </div>
        </div>

        {/* ResQ Safe Path Card */}
        <div className="route-card safe">
          <div className="route-header">
            <span className="route-title" style={{ color: '#22c55e' }}>
              RESQ-MESH SAFE CORRIDOR
            </span>
            <span style={{ fontSize: '9px', fontWeight: 'bold', padding: '2px 6px', borderRadius: '4px', background: '#22c55e22', color: '#22c55e' }}>
              HAZARD-WEIGHTED
            </span>
          </div>

          <div className="route-metrics-row">
            <div className="metric-box">
              <div className="metric-label">DISTANCE</div>
              <div className="metric-value">{dijkstraSafeRoute?.distanceMeters || 2537}m</div>
            </div>
            <div className="metric-box">
              <div className="metric-label">EST. DURATION</div>
              <div className="metric-value">{dijkstraSafeRoute?.estimatedTimeMin || 10.1} min</div>
            </div>
          </div>

          <div className="route-warning-box success">
            ✓ Safely bypasses collapsed bridges & gas leaks via alternate arterial.
          </div>
        </div>

      </div>

      {/* Hazard Zones Manager */}
      <div style={{ marginTop: '16px' }}>
        <div style={{ fontSize: '11px', fontFamily: 'Orbitron', fontWeight: 'bold', color: '#94a3b8', marginBottom: '10px' }}>
          ACTIVE DISASTER HAZARDS ({hazardZones.length})
        </div>

        <div>
          {hazardZones.map((hz) => (
            <div key={hz.id} className="hazard-item-row">
              <div className="hazard-item-top">
                <div>
                  <strong style={{ fontSize: '12px', color: '#ffffff' }}>{hz.title}</strong>
                  <div style={{ fontSize: '10px', color: '#64748b' }}>
                    Radius: {hz.radius}m • Lat: {hz.lat.toFixed(4)}, Lng: {hz.lng.toFixed(4)}
                  </div>
                </div>
                <button
                  onClick={() => onRemoveHazard(hz.id)}
                  style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', padding: '4px' }}
                  title="Remove hazard zone"
                >
                  <Trash2 size={16} />
                </button>
              </div>

              <div className="hazard-slider-row">
                <Sliders size={14} color="#38bdf8" />
                <span>Penalty Weight:</span>
                <input
                  type="range"
                  min="5"
                  max="100"
                  value={hz.penaltyMultiplier}
                  onChange={(e) => onUpdatePenalty(hz.id, Number(e.target.value))}
                  className="hazard-slider"
                />
                <span style={{ fontFamily: 'Fira Code', fontWeight: 'bold', color: '#38bdf8', minWidth: '35px', textAlign: 'right' }}>
                  {hz.penaltyMultiplier}x
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Quick Add Form */}
        <form onSubmit={handleAdd} style={{ display: 'flex', gap: '8px', marginTop: '10px' }}>
          <input
            type="text"
            placeholder="New Hazard (e.g. Structural Gas Rupture)"
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            style={{
              flex: 1,
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #1f2c42',
              background: '#07090e',
              color: '#ffffff',
              fontSize: '11px',
              outline: 'none'
            }}
          />
          <button
            type="submit"
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              background: '#38bdf8',
              color: '#07090e',
              fontWeight: 'bold',
              fontSize: '11px',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px'
            }}
          >
            <Plus size={14} /> Add Hazard
          </button>
        </form>
      </div>

    </div>
  );
}
