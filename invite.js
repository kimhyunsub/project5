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

const API_BASE_URL = resolveApiBaseUrl();

const params = new URLSearchParams(window.location.search);
const inviteToken = params.get("token") || "";
const appInviteUrl = inviteToken ? `attendanceapp://invite?token=${encodeURIComponent(inviteToken)}` : "attendanceapp://invite";

const inviteForm = document.getElementById("invite-form");
const activateButton = document.getElementById("activate-button");
const inviteStatus = document.getElementById("invite-status");
const inviteSummary = document.getElementById("invite-summary");
const inviteResult = document.getElementById("invite-result");
const inviteResultMessage = document.getElementById("invite-result-message");
const openAppButton = document.getElementById("open-app-button");

if (openAppButton) {
  openAppButton.href = appInviteUrl;
  openAppButton.addEventListener("click", (event) => {
    event.preventDefault();
    window.location.href = appInviteUrl;
  });
}

function setStatus(message, type = "") {
  inviteStatus.textContent = message;
  inviteStatus.className = `form-status${type ? ` is-${type}` : ""}`;
}

function setLoading(loading) {
  activateButton.disabled = loading;
  activateButton.textContent = loading ? "등록 중..." : "모바일 웹에서 등록 완료";
}

function text(id, value) {
  document.getElementById(id).textContent = value || "-";
}

function buildDevicePayload() {
  const normalizedAgent = (navigator.userAgent || "mobile-web")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48) || "mobile-web";
  const deviceId = `web-${normalizedAgent}-${inviteToken.slice(0, 8) || "invite"}`;
  const deviceName = "모바일 웹";
  return { deviceId, deviceName };
}

async function loadInvite() {
  if (!inviteToken) {
    setStatus("초대 토큰이 없습니다. 올바른 링크인지 확인해 주세요.", "error");
    return;
  }

  setStatus("초대 정보를 확인하고 있습니다.");

  try {
    const response = await fetch(
      `${API_BASE_URL}/auth/invite/preview?token=${encodeURIComponent(inviteToken)}`
    );
    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(data.message || "초대 정보를 불러오지 못했습니다.");
    }

    text("invite-company-name", data.companyName);
    text("invite-employee-name", data.employeeName);
    text("invite-employee-code", data.employeeCode);
    text("invite-role", data.role);
    text("invite-workplace-name", data.workplaceName);

    inviteSummary.hidden = false;
    inviteForm.hidden = false;
    setStatus(data.message || "초대 링크가 유효합니다. 이 페이지에서 바로 등록하거나 앱에서 이어서 진행해 주세요.", "success");
  } catch (error) {
    setStatus(error.message || "초대 링크를 확인할 수 없습니다.", "error");
  }
}

inviteForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setLoading(true);
  inviteResult.hidden = true;
  setStatus("직원 등록을 진행하고 있습니다.");

  const formData = new FormData(inviteForm);
  const { deviceId, deviceName } = buildDevicePayload();
  const payload = {
    inviteToken,
    newPassword: String(formData.get("newPassword") || ""),
    deviceId,
    deviceName,
  };

  try {
    const response = await fetch(`${API_BASE_URL}/auth/invite/activate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(data.message || "초대 활성화에 실패했습니다.");
    }

    inviteResultMessage.textContent =
      "직원 등록이 완료되었습니다. 이 계정은 지정된 회사 소속으로만 사용되며, 이후 요청도 같은 회사 기준으로 처리됩니다.";
    text("result-company-name", data.companyName);
    text("result-employee-code", data.employeeCode);
    text("result-token-expiry", data.accessTokenExpiresAt);
    inviteResult.hidden = false;
    inviteForm.hidden = true;
    setStatus("직원 등록과 로그인 준비가 완료되었습니다.", "success");
  } catch (error) {
    setStatus(error.message || "초대 활성화에 실패했습니다.", "error");
  } finally {
    setLoading(false);
  }
});

loadInvite();
