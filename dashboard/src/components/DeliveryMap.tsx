import { MapContainer, TileLayer, Marker, Popup, Polyline } from "react-leaflet";
import L from "leaflet";
import type { Delivery } from "../types";
import "leaflet/dist/leaflet.css";

const riderIcon = L.divIcon({
  className: "rider-marker",
  html: '<div style="background:#3b82f6;width:16px;height:16px;border-radius:50%;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,.3)"></div>',
  iconSize: [16, 16],
  iconAnchor: [8, 8],
});

const destIcon = L.divIcon({
  className: "dest-marker",
  html: '<div style="background:#22c55e;width:14px;height:14px;border-radius:2px;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,.3)"></div>',
  iconSize: [14, 14],
  iconAnchor: [7, 7],
});

interface Props {
  delivery: Delivery;
}

export function DeliveryMap({ delivery }: Props) {
  const center = delivery.current_location ?? delivery.origin;
  const positions: [number, number][] = [
    [delivery.origin.lat, delivery.origin.lng],
    ...(delivery.current_location
      ? [[delivery.current_location.lat, delivery.current_location.lng] as [number, number]]
      : []),
    [delivery.destination.lat, delivery.destination.lng],
  ];

  return (
    <MapContainer
      center={[center.lat, center.lng]}
      zoom={15}
      style={{ height: "100%", width: "100%", borderRadius: "12px" }}
      key={`${center.lat}-${center.lng}`}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Polyline positions={positions} color="#94a3b8" dashArray="6 6" weight={2} />
      {delivery.current_location && (
        <Marker
          position={[delivery.current_location.lat, delivery.current_location.lng]}
          icon={riderIcon}
        >
          <Popup>Rider — {delivery.rider_id}</Popup>
        </Marker>
      )}
      <Marker
        position={[delivery.destination.lat, delivery.destination.lng]}
        icon={destIcon}
      >
        <Popup>{delivery.destination.label ?? "Destination"}</Popup>
      </Marker>
    </MapContainer>
  );
}
