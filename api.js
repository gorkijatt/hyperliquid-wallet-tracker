const API_URL = "https://api.hyperliquid.xyz/info";

async function fetchInfo(type, params = {}) {
  const body = { type, ...params };
  const res = await fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}
