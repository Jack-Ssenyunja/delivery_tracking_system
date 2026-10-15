import { useEffect, useState, useCallback } from "react";
import { API_BASE } from "../types";
import type { Delivery, WsEvent } from "../types";
import { useWebSocket } from "./useWebSocket";

export function useDeliveries() {
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [loading, setLoading] = useState(true);
  const [timeline, setTimeline] = useState<WsEvent[]>([]);

  const fetchDeliveries = useCallback(async () => {
    const res = await fetch(`${API_BASE}/deliveries`);
    const data = await res.json();
    setDeliveries(data);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchDeliveries();
  }, [fetchDeliveries]);

  const handleWsEvent = useCallback((event: WsEvent) => {
    setTimeline((prev) => [event, ...prev].slice(0, 50));

    setDeliveries((prev) =>
      prev.map((d) => {
        if (d.id !== event.deliveryId) return d;

        const updated = { ...d };

        if (event.type === "delivery.status_changed" && event.status) {
          updated.status = event.status;
        }
        if (event.type === "delivery.eta_updated" && event.etaSeconds !== undefined) {
          updated.eta_seconds = event.etaSeconds;
        }
        if (
          event.type === "rider.location_updated" &&
          event.lat !== undefined &&
          event.lng !== undefined
        ) {
          updated.current_location = {
            lat: event.lat,
            lng: event.lng,
            label: updated.current_location?.label,
          };
        }

        return updated;
      })
    );
  }, []);

  const { connected } = useWebSocket(handleWsEvent);

  return { deliveries, loading, connected, timeline, refresh: fetchDeliveries };
}
