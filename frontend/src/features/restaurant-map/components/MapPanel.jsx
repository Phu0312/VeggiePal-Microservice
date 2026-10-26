import { useEffect, useMemo, useRef, useState } from "react";
import MapGL, { Layer, Marker, Popup, Source } from "react-map-gl/mapbox";
import "mapbox-gl/dist/mapbox-gl.css";
import {
  Loader2,
  LocateFixed,
  MapPin,
  Minus,
  Plus,
  RotateCcw,
  Star,
} from "lucide-react";

import MapFrame from "@/features/restaurant-map/components/MapFrame";
import {
  circleGeoJSON,
  MARKER_COLORS,
  zoomForRadius,
} from "@/features/restaurant-map/utils/mapConfig";
import {
  formatDistance,
  formatRating,
  toGeoJSON,
} from "@/features/restaurant-map/utils/restaurantFormat";
import { useThemeStore } from "@/shared/store/themeStore";

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN;
const MAPBOX_STYLE =
  import.meta.env.VITE_MAPBOX_STYLE || "mapbox://styles/mapbox/streets-v12";

const SOURCE_ID = "restaurants";
const CLUSTER_LAYER_ID = "restaurant-clusters";
const POINT_LAYER_ID = "restaurant-points";
const INTERACTIVE_LAYER_IDS = [CLUSTER_LAYER_ID, POINT_LAYER_ID];

// Task sheet: gom cụm marker khi có hơn 50 quán.
const CLUSTER_THRESHOLD = 50;
const SELECTED_MIN_ZOOM = 15;

const CIRCLE_BUTTON =
  "grid size-10 place-items-center text-ink transition hover:bg-surface";

function MapNotice({ title, description }) {
  return (
    <MapFrame>
      <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 px-6 text-center">
        <span className="grid size-14 place-items-center rounded-full bg-white/80 text-brand shadow-sm dark:bg-black/30">
          <MapPin className="h-6 w-6" />
        </span>
        <p className="text-sm font-semibold text-ink">{title}</p>
        <p className="max-w-[260px] text-xs leading-relaxed text-subtle">
          {description}
        </p>
      </div>
    </MapFrame>
  );
}

/**
 * Bản đồ Mapbox của trang quán chay.
 * - restaurants: quán đang hiện trong danh sách (đã lọc), vẽ thành chấm; > 50 quán thì gom cụm
 * - location / isDefaultLocation / radiusKm: tâm tìm kiếm (chấm xanh là vị trí thật) và vòng bán kính
 * - selectedId / onSelect(id | null): quán đang chọn (có ghim lớn và popup), đồng bộ với danh sách
 * - onLocate / locating: nút "Vị trí của tôi" xin định vị lại
 */
export default function MapPanel({
  restaurants,
  location,
  isDefaultLocation,
  radiusKm,
  selectedId,
  onSelect,
  onLocate,
  locating,
}) {
  const mapRef = useRef(null);
  const theme = useThemeStore((s) => s.theme);
  const colors = MARKER_COLORS[theme === "dark" ? "dark" : "light"];
  const [cursor, setCursor] = useState("");
  const [tokenRejected, setTokenRejected] = useState(false);

  const geojson = useMemo(() => toGeoJSON(restaurants), [restaurants]);
  const radiusCircle = useMemo(
    () => circleGeoJSON(location, radiusKm),
    [location, radiusKm],
  );
  const clustered = restaurants.length > CLUSTER_THRESHOLD;
  const selected = restaurants.find((r) => r.id === selectedId) ?? null;
  const selectedLng = selected?.longitude;
  const selectedLat = selected?.latitude;

  // Tâm hoặc bán kính đổi thì bay về vòng tìm kiếm mới.
  useEffect(() => {
    mapRef.current?.flyTo({
      center: [location.lng, location.lat],
      zoom: zoomForRadius(radiusKm),
      duration: 1200,
    });
  }, [location.lat, location.lng, radiusKm]);

  // Chọn quán (từ thẻ hoặc marker) thì bay tới quán, không zoom ra xa hơn mức đang xem.
  useEffect(() => {
    if (selectedLng == null || selectedLat == null) return;
    const map = mapRef.current;
    if (!map) return;
    map.flyTo({
      center: [selectedLng, selectedLat],
      zoom: Math.max(map.getZoom(), SELECTED_MIN_ZOOM),
      duration: 800,
    });
  }, [selectedLng, selectedLat]);

  if (!MAPBOX_TOKEN) {
    return (
      <MapNotice
        title="Chưa cấu hình bản đồ"
        description="Thiếu VITE_MAPBOX_TOKEN trong file .env của ứng dụng."
      />
    );
  }

  if (tokenRejected) {
    return (
      <MapNotice
        title="Không tải được bản đồ"
        description="Mapbox từ chối token hiện tại. Hãy kiểm tra VITE_MAPBOX_TOKEN."
      />
    );
  }

  const handleClick = (event) => {
    const feature = event.features?.[0];
    if (!feature) {
      onSelect(null);
      return;
    }

    if (feature.layer.id === CLUSTER_LAYER_ID) {
      // Bấm cụm thì zoom tới mức tách được các quán bên trong.
      const source = mapRef.current?.getMap().getSource(SOURCE_ID);
      source?.getClusterExpansionZoom(
        feature.properties.cluster_id,
        (error, zoom) => {
          if (error) return;
          mapRef.current?.easeTo({
            center: feature.geometry.coordinates,
            zoom,
          });
        },
      );
      return;
    }

    onSelect(Number(feature.properties.id));
  };

  const handleReset = () => {
    onSelect(null);
    mapRef.current?.flyTo({
      center: [location.lng, location.lat],
      zoom: zoomForRadius(radiusKm),
      duration: 1000,
    });
  };

  const handleError = (event) => {
    // Chỉ coi là lỗi chết khi Mapbox từ chối token; lỗi tải một ô bản đồ lẻ tẻ thì bỏ qua.
    const status = event.error?.status;
    if (status === 401 || status === 403) setTokenRejected(true);
  };

  return (
    <MapFrame>
      <div className="absolute inset-0">
        <MapGL
          ref={mapRef}
          mapboxAccessToken={MAPBOX_TOKEN}
          mapStyle={MAPBOX_STYLE}
          initialViewState={{
            longitude: location.lng,
            latitude: location.lat,
            zoom: zoomForRadius(radiusKm),
          }}
          style={{ width: "100%", height: "100%" }}
          interactiveLayerIds={INTERACTIVE_LAYER_IDS}
          cursor={cursor}
          onMouseEnter={() => setCursor("pointer")}
          onMouseLeave={() => setCursor("")}
          onClick={handleClick}
          onError={handleError}
        >
          {/* Vòng bán kính tìm kiếm, nằm dưới các marker */}
          <Source id="search-radius" type="geojson" data={radiusCircle}>
            <Layer
              id="search-radius-fill"
              type="fill"
              paint={{ "fill-color": colors.brand, "fill-opacity": 0.06 }}
            />
            <Layer
              id="search-radius-line"
              type="line"
              paint={{
                "line-color": colors.brand,
                "line-width": 1.5,
                "line-dasharray": [2, 2],
              }}
            />
          </Source>

          {/* key: bật/tắt gom cụm phải dựng lại source vì Mapbox không đổi `cluster` khi đang chạy */}
          <Source
            key={clustered ? "clustered" : "flat"}
            id={SOURCE_ID}
            type="geojson"
            data={geojson}
            cluster={clustered}
            clusterMaxZoom={14}
            clusterRadius={50}
          >
            <Layer
              id={CLUSTER_LAYER_ID}
              type="circle"
              filter={["has", "point_count"]}
              paint={{
                "circle-color": colors.brand,
                "circle-radius": ["step", ["get", "point_count"], 18, 10, 24, 30, 30],
                "circle-stroke-width": 3,
                "circle-stroke-color": colors.stroke,
              }}
            />
            <Layer
              id="restaurant-cluster-count"
              type="symbol"
              filter={["has", "point_count"]}
              layout={{
                "text-field": ["get", "point_count_abbreviated"],
                "text-font": ["DIN Offc Pro Medium", "Arial Unicode MS Bold"],
                "text-size": 13,
                "text-allow-overlap": true,
              }}
              paint={{ "text-color": colors.text }}
            />
            <Layer
              id={POINT_LAYER_ID}
              type="circle"
              filter={["!", ["has", "point_count"]]}
              paint={{
                "circle-color": colors.brand,
                "circle-radius": 8,
                "circle-stroke-width": 3,
                "circle-stroke-color": colors.stroke,
              }}
            />
          </Source>

          {!isDefaultLocation && (
            <Marker longitude={location.lng} latitude={location.lat}>
              <span
                role="img"
                aria-label="Vị trí của bạn"
                className="block size-4 rounded-full border-[3px] border-white bg-[#2f7cf6] shadow-[0_0_0_6px_rgba(47,124,246,0.25)]"
              />
            </Marker>
          )}

          {selected && (
            <>
              <Marker
                longitude={selected.longitude}
                latitude={selected.latitude}
                anchor="bottom"
              >
                <MapPin className="size-9 fill-brand text-white drop-shadow-md" />
              </Marker>
              <Popup
                longitude={selected.longitude}
                latitude={selected.latitude}
                anchor="bottom"
                offset={[0, -38]}
                maxWidth="240px"
                closeButton={false}
                closeOnClick={false}
              >
                {/* Popup của Mapbox luôn nền trắng nên dùng màu cố định, không theo theme */}
                <div className="flex flex-col gap-1 p-1 text-[#111c2d]">
                  <p className="text-sm font-bold leading-snug">
                    {selected.name}
                  </p>
                  <p className="text-xs text-[#707a70]">{selected.address}</p>
                  <p className="flex items-center gap-1 text-xs font-semibold">
                    <Star className="size-3 fill-[#F5B93D] text-[#F5B93D]" />
                    {formatRating(selected.rating)}
                    {formatDistance(selected.distanceKm) && (
                      <span className="font-normal text-[#707a70]">
                        • {formatDistance(selected.distanceKm)}
                      </span>
                    )}
                  </p>
                </div>
              </Popup>
            </>
          )}
        </MapGL>
      </div>

      <button
        type="button"
        onClick={handleReset}
        className="absolute right-4 top-4 flex items-center gap-1.5 rounded-full bg-card px-3.5 py-2 text-xs font-semibold text-ink shadow-sm transition hover:bg-surface"
      >
        <RotateCcw className="h-3.5 w-3.5" />
        Đặt lại bản đồ
      </button>

      <div className="absolute right-4 top-16 flex flex-col overflow-hidden rounded-2xl bg-card shadow-sm">
        <button
          type="button"
          aria-label="Phóng to"
          onClick={() => mapRef.current?.zoomIn({ duration: 300 })}
          className={CIRCLE_BUTTON}
        >
          <Plus className="h-4 w-4" />
        </button>
        <div className="h-px bg-border" />
        <button
          type="button"
          aria-label="Thu nhỏ"
          onClick={() => mapRef.current?.zoomOut({ duration: 300 })}
          className={CIRCLE_BUTTON}
        >
          <Minus className="h-4 w-4" />
        </button>
      </div>

      <button
        type="button"
        aria-label="Vị trí của tôi"
        onClick={onLocate}
        disabled={locating}
        className="absolute left-4 top-4 grid size-10 place-items-center rounded-full bg-card text-brand shadow-sm transition hover:bg-surface disabled:opacity-70"
      >
        {locating ? (
          <Loader2 className="h-4 w-4 animate-spin" />
        ) : (
          <LocateFixed className="h-4 w-4" />
        )}
      </button>
    </MapFrame>
  );
}
