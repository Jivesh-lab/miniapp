const cityCache = new Map();

function getCacheKey(lat, lng) {
  return `${Number(lat).toFixed(4)},${Number(lng).toFixed(4)}`;
}

function isValidCoordinate(value, min, max) {
  return typeof value === "number" && Number.isFinite(value) && value >= min && value <= max;
}

function extractCity(address = {}) {
  return (
    address.city ||
    address.town ||
    address.village ||
    address.county ||
    address.state ||
    "Unknown"
  );
}

export async function getCityFromCoordinates(lat, lng) {
  const key = getCacheKey(lat, lng);

  if (cityCache.has(key)) {
    return cityCache.get(key);
  }

  const url = new URL("https://nominatim.openstreetmap.org/reverse");
  url.searchParams.set("lat", String(lat));
  url.searchParams.set("lon", String(lng));
  url.searchParams.set("format", "json");
  url.searchParams.set("addressdetails", "1");

  const response = await fetch(url, {
    headers: {
      "User-Agent": "LocalConnectApp/1.0 (location lookup)",
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    cityCache.set(key, "Unknown");
    return "Unknown";
  }

  const data = await response.json();
  const city = extractCity(data?.address);
  cityCache.set(key, city);
  return city;
}

export function validateLatLng(lat, lng) {
  if (!isValidCoordinate(lat, -90, 90)) {
    return "Invalid latitude";
  }

  if (!isValidCoordinate(lng, -180, 180)) {
    return "Invalid longitude";
  }

  return null;
}