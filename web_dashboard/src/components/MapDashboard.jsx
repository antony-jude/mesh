import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, Circle, useMap } from 'react-leaflet';
import L from 'leaflet';
import { Shield, Navigation, AlertOctagon } from 'lucide-react';

function MapViewController({ center, zoom }) {
  const map = useMap();
  useEffect(() => {
    if (center) {
      map.setView(center, zoom, { animate: true });
    }
  }, [center, zoom, map]);
  return null;
}

export default function MapDashboard({
  sosPackets,
  selectedPacket,
  onSelectPacket,
  hazardZones,
  dijkstraSafeRoute,
  naiveRoute,
  waypoints
}) {
  const [mapCenter, setMapCenter] = useState([37.7770, -122.4140]);
  const [showNaiveRoute, setShowNaiveRoute] = useState(true);
  const [showSafeRoute, setShowSafeRoute] = useState(true);

  useEffect(() => {
    if (selectedPacket?.last_known_location) {
      setMapCenter([selectedPacket.last_known_location.lat, selectedPacket.last_known_location.lng]);
    }
  }, [selectedPacket]);

  // Create custom pulsing icon for SOS victims
  const createSosIcon = (priority) => {
    let color = '#ef4444';
    if (priority === 'HIGH') color = '#f97316';
    if (priority === 'MEDIUM') color = '#eab308';
    if (priority === 'LOW') color = '#22c55e';

    return L.divIcon({
      className: 'custom-sos-marker',
      html: `
        <div style="position: relative; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;">
          <div style="position: absolute; width: 32px; height: 32px; border-radius: 50%; background: ${color}33; border: 2px solid ${color};"></div>
          <div style="width: 18px; height: 18px; border-radius: 50%; background: ${color}; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 12px ${color};">
            <div style="width: 6px; height: 6px; border-radius: 50%; background: #ffffff;"></div>
          </div>
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
      popupAnchor: [0, -18]
    });
  };

  // Base Station Icon
  const baseStationIcon = L.divIcon({
    className: 'custom-base-marker',
    html: `
      <div style="width: 34px; height: 34px; border-radius: 8px; background: #0284c7; border: 2px solid #38bdf8; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 16px rgba(56,189,248,0.7);">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      </div>
    `,
    iconSize: [34, 34],
    iconAnchor: [17, 17]
  });

  return (
    <div className="map-container-wrapper">
      {/* Map Overlays Control Box */}
      <div className="map-layer-controls">
        <div style={{ fontSize: '10px', fontFamily: 'Orbitron, monospace', fontWeight: 700, color: '#94a3b8', letterSpacing: '1px' }}>
          DISPATCH OVERLAYS
        </div>
        
        <label className="map-checkbox-label">
          <input
            type="checkbox"
            checked={showSafeRoute}
            onChange={(e) => setShowSafeRoute(e.target.checked)}
            style={{ accentColor: '#22c55e' }}
          />
          <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#22c55e', display: 'inline-block', boxShadow: '0 0 6px #22c55e' }}></span>
          <span>ResQ Safe Route (Dijkstra)</span>
        </label>

        <label className="map-checkbox-label">
          <input
            type="checkbox"
            checked={showNaiveRoute}
            onChange={(e) => setShowNaiveRoute(e.target.checked)}
            style={{ accentColor: '#ef4444' }}
          />
          <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#ef4444', display: 'inline-block', boxShadow: '0 0 6px #ef4444' }}></span>
          <span>Naive Route (Crosses Hazard)</span>
        </label>
      </div>

      <MapContainer
        center={mapCenter}
        zoom={14}
        scrollWheelZoom={true}
        style={{ width: '100%', height: '100%' }}
      >
        <MapViewController center={mapCenter} zoom={14} />

        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Rescue Base Station Alpha */}
        <Marker position={[37.7749, -122.4194]} icon={baseStationIcon}>
          <Popup>
            <div style={{ padding: '6px', background: '#111622', color: '#fff', borderRadius: '6px' }}>
              <div style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px', color: '#38bdf8' }}>RESCUE BASE ALPHA</div>
              <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px' }}>Disaster Tactical Dispatch</div>
            </div>
          </Popup>
        </Marker>

        {/* Hazard Zones */}
        {hazardZones.map((hz) => (
          <Circle
            key={hz.id}
            center={[hz.lat, hz.lng]}
            radius={hz.radius}
            pathOptions={{
              color: hz.color || '#ef4444',
              fillColor: hz.color || '#ef4444',
              fillOpacity: 0.25,
              weight: 2,
              dashArray: '6, 6'
            }}
          >
            <Popup>
              <div style={{ padding: '6px', background: '#111622', color: '#fff', borderRadius: '6px' }}>
                <div style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px', color: '#ef4444' }}>{hz.title}</div>
                <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>Penalty Multiplier: {hz.penaltyMultiplier}x</div>
              </div>
            </Popup>
          </Circle>
        ))}

        {/* Naive Route (Red Dashed) */}
        {showNaiveRoute && naiveRoute?.coordinates?.length > 1 && (
          <Polyline
            positions={naiveRoute.coordinates}
            pathOptions={{
              color: '#ef4444',
              weight: 4,
              dashArray: '8, 8',
              opacity: 0.9
            }}
          />
        )}

        {/* ResQ Safe Route (Green Solid) */}
        {showSafeRoute && dijkstraSafeRoute?.coordinates?.length > 1 && (
          <Polyline
            positions={dijkstraSafeRoute.coordinates}
            pathOptions={{
              color: '#22c55e',
              weight: 6,
              opacity: 0.95
            }}
          />
        )}

        {/* SOS Incident Markers */}
        {sosPackets.map((pkt) => {
          const loc = pkt.last_known_location;
          if (!loc?.lat || !loc?.lng) return null;

          return (
            <Marker
              key={pkt.packet_id}
              position={[loc.lat, loc.lng]}
              icon={createSosIcon(pkt.priority_label)}
              eventHandlers={{
                click: () => onSelectPacket(pkt)
              }}
            >
              <Popup>
                <div style={{ padding: '8px', background: '#111622', color: '#fff', borderRadius: '8px', minWidth: '200px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #334155', paddingBottom: '6px' }}>
                    <span style={{ fontFamily: 'Orbitron', fontWeight: 'bold', fontSize: '12px' }}>{pkt.origin_device_id}</span>
                    <span style={{ fontSize: '9px', fontWeight: 'bold', padding: '2px 6px', borderRadius: '4px', background: pkt.priority_label === 'CRITICAL' ? '#ef444433' : '#f9731633', color: pkt.priority_label === 'CRITICAL' ? '#ef4444' : '#f97316' }}>
                      {pkt.priority_label}
                    </span>
                  </div>
                  <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '6px' }}>
                    Signal: <strong style={{ color: '#fff' }}>{pkt.signal_type}</strong> | Hops: <strong style={{ color: '#38bdf8' }}>{pkt.hop_count}</strong>
                  </div>
                  <div style={{ fontSize: '11px', fontStyle: 'italic', background: '#07090e', padding: '6px', borderRadius: '4px', marginTop: '6px' }}>
                    "{pkt.classification_reasoning}"
                  </div>
                </div>
              </Popup>
            </Marker>
          );
        })}

      </MapContainer>
    </div>
  );
}
