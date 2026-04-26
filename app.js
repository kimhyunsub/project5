function isPrivateNetworkHost(hostname) {
  return /^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)/.test(hostname);
}

function resolveApiBaseUrl() {
  if (window.BIZ_HOME_API_BASE_URL) {
    return window.BIZ_HOME_API_BASE_URL;
  }

  const { protocol, hostname } = window.location;
  if (protocol === "file:") {
    return "http://localhost:8090/api";
  }

  if (["localhost", "127.0.0.1", "::1"].includes(hostname)) {
    return "http://localhost:8090/api";
  }

  if (isPrivateNetworkHost(hostname)) {
    return `${protocol}//${hostname}:8090/api`;
  }

  return "https://api.hsft.io.kr/api";
}

function resolveAdminLoginUrl() {
  if (window.BIZ_HOME_ADMIN_URL) {
    return window.BIZ_HOME_ADMIN_URL;
  }

  const { protocol, hostname } = window.location;
  if (protocol === "file:") {
    return "http://localhost:8091/login";
  }

  if (["localhost", "127.0.0.1", "::1"].includes(hostname)) {
    return "http://localhost:8091/login";
  }

  if (isPrivateNetworkHost(hostname)) {
    return `${protocol}//${hostname}:8091/login`;
  }

  return "https://admin.hsft.io.kr/login";
}

const API_BASE_URL = resolveApiBaseUrl();
const ADMIN_LOGIN_URL = resolveAdminLoginUrl();

const form = document.getElementById("signup-form");
const submitButton = document.getElementById("submit-button");
const statusElement = document.getElementById("form-status");
const successPanel = document.getElementById("success-panel");
const successMessage = document.getElementById("success-message");
const nextStepMessage = document.getElementById("next-step-message");
const companyNameElement = document.getElementById("result-company-name");
const adminNameElement = document.getElementById("result-admin-name");
const adminCodeElement = document.getElementById("result-admin-code");
const latitudeInput = form.elements.latitude;
const longitudeInput = form.elements.longitude;
const locationSummary = document.getElementById("location-summary");
const useCurrentLocationButton = document.getElementById("use-current-location");

const DEFAULT_LOCATION = {
  latitude: 37.5665,
  longitude: 126.978,
};

let map;
let marker;

function setStatus(message, type = "") {
  statusElement.textContent = message;
  statusElement.className = `form-status${type ? ` is-${type}` : ""}`;
}

function setLoading(loading) {
  submitButton.disabled = loading;
  submitButton.textContent = loading ? "가입 처리 중..." : "회사 가입하기";
}

function toNumber(value) {
  return value === "" ? null : Number(value);
}

function formatCoordinate(value) {
  return Number(value).toFixed(6);
}

function updateLocationFields(latitude, longitude, zoom = 16) {
  latitudeInput.value = formatCoordinate(latitude);
  longitudeInput.value = formatCoordinate(longitude);

  if (marker) {
    marker.setLatLng([latitude, longitude]);
  }

  if (map) {
    map.setView([latitude, longitude], zoom);
  }

  locationSummary.textContent = `선택된 위치: 위도 ${formatCoordinate(latitude)}, 경도 ${formatCoordinate(longitude)}`;
}

function initializeMap() {
  if (typeof L === "undefined") {
    updateLocationFields(DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude, 15);
    locationSummary.textContent = "지도를 불러오지 못했습니다. 잠시 후 다시 새로고침해 주세요.";
    return;
  }

  map = L.map("location-map").setView([DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude], 15);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap contributors",
  }).addTo(map);

  marker = L.marker([DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude]).addTo(map);

  map.on("click", (event) => {
    updateLocationFields(event.latlng.lat, event.latlng.lng);
  });

  updateLocationFields(DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude, 15);
}

function useCurrentLocation() {
  if (!navigator.geolocation) {
    setStatus("현재 브라우저에서는 위치 기능을 지원하지 않습니다.", "error");
    return;
  }

  useCurrentLocationButton.disabled = true;
  useCurrentLocationButton.textContent = "위치 확인 중...";

  navigator.geolocation.getCurrentPosition(
    (position) => {
      updateLocationFields(position.coords.latitude, position.coords.longitude, 17);
      setStatus("현재 위치를 기준 좌표로 설정했습니다.", "success");
      useCurrentLocationButton.disabled = false;
      useCurrentLocationButton.textContent = "현재 위치 사용";
    },
    (error) => {
      const message =
        error.code === error.PERMISSION_DENIED
          ? "브라우저 위치 권한을 허용한 뒤 다시 시도해 주세요."
          : "현재 위치를 가져오지 못했습니다. 지도를 클릭해 직접 선택해 주세요.";
      setStatus(message, "error");
      useCurrentLocationButton.disabled = false;
      useCurrentLocationButton.textContent = "현재 위치 사용";
    },
    {
      enableHighAccuracy: true,
      timeout: 10000,
    }
  );
}

updateLocationFields(DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude, 15);
initializeMap();
useCurrentLocationButton.addEventListener("click", useCurrentLocation);

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  setLoading(true);
  setStatus("회사 정보를 등록하고 있습니다.");
  successPanel.hidden = true;

  const formData = new FormData(form);
  const payload = {
    companyName: String(formData.get("companyName") || "").trim(),
    adminName: String(formData.get("adminName") || "").trim(),
    adminEmployeeCode: String(formData.get("adminEmployeeCode") || "").trim(),
    adminPassword: String(formData.get("adminPassword") || ""),
    latitude: toNumber(String(formData.get("latitude") || "")),
    longitude: toNumber(String(formData.get("longitude") || "")),
    allowedRadiusMeters: toNumber(String(formData.get("allowedRadiusMeters") || "")),
  };

  try {
    const response = await fetch(`${API_BASE_URL}/auth/company-signup`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(data.message || "회사 가입에 실패했습니다.");
    }

    setStatus("회사 가입이 완료되었습니다.", "success");
    successMessage.textContent = data.message || "관리자 계정이 생성되었습니다.";
    companyNameElement.textContent = data.companyName || payload.companyName;
    adminNameElement.textContent = data.adminName || payload.adminName;
    adminCodeElement.textContent = data.adminEmployeeCode || payload.adminEmployeeCode;
    nextStepMessage.innerHTML = `잠시 후 관리자 로그인 페이지로 이동합니다. 자동 이동하지 않으면 <a href="${ADMIN_LOGIN_URL}">여기를 눌러 로그인</a>해 주세요.`;
    successPanel.hidden = false;
    form.reset();
    updateLocationFields(DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude, 15);
    window.setTimeout(() => {
      window.location.href = ADMIN_LOGIN_URL;
    }, 1500);
  } catch (error) {
    const message =
      error instanceof TypeError
        ? `가입 요청을 서버로 보내지 못했습니다. 현재 연결 주소: ${API_BASE_URL}`
        : error.message || "회사 가입에 실패했습니다.";
    setStatus(message, "error");
  } finally {
    setLoading(false);
  }
});
