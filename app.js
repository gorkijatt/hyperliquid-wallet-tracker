const DEFAULT_WALLETS = [
  { address: "0x1825397CA7497c2895B33C86D2beF1999Ba72F29", label: "Default" },
];

function getWallets() {
  const saved = localStorage.getItem("hl_wallets");
  return saved ? JSON.parse(saved) : DEFAULT_WALLETS;
}

function saveWallets(wallets) {
  localStorage.setItem("hl_wallets", JSON.stringify(wallets));
}

let wallet = getWallets()[0]?.address || "";
const content = () => document.getElementById("content");

function renderWalletSelect() {
  const select = document.getElementById("walletSelect");
  const wallets = getWallets();
  select.innerHTML = wallets.map((w) =>
    `<option value="${w.address}" ${w.address === wallet ? "selected" : ""}>${w.label ? w.label + " — " : ""}${w.address.slice(0, 6)}...${w.address.slice(-4)}</option>`
  ).join("");
}

function setLoading() {
  content().innerHTML = '<p class="loading">Loading...</p>';
}

function setError(msg) {
  content().innerHTML = `<p class="error">${msg}</p>`;
}

function pnlClass(v) {
  const n = parseFloat(v);
  return n > 0 ? "pos" : n < 0 ? "neg" : "";
}

// --- Pages ---

async function showMarket() {
  setLoading();
  try {
    const [mids, meta] = await Promise.all([
      fetchInfo("allMids"),
      fetchInfo("meta"),
    ]);
    const universe = meta.universe || [];
    const rows = universe.map((coin) => {
      const mid = mids[coin.name] || "—";
      return `<tr><td>${coin.name}</td><td>${mid}</td><td>${coin.szDecimals}</td></tr>`;
    }).join("");
    content().innerHTML = `
      <h2>Market Prices</h2>
      <table><thead><tr><th>Asset</th><th>Mid Price</th><th>Size Decimals</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  } catch (e) { setError(e.message); }
}

async function showAccount() {
  setLoading();
  try {
    const [perps, spot] = await Promise.all([
      fetchInfo("clearinghouseState", { user: wallet }),
      fetchInfo("spotClearinghouseState", { user: wallet }),
    ]);
    const mb = perps.marginSummary || {};
    const spotBalances = (spot.balances || []).filter(
      (b) => parseFloat(b.total) > 0
    );
    const positions = (perps.assetPositions || []).filter(
      (p) => parseFloat(p.position.szi) !== 0
    );

    const spotRows = spotBalances.map((b) =>
      `<tr><td>${b.coin}</td><td>${b.total}</td><td>${b.hold}</td></tr>`
    ).join("");

    const posRows = positions.map((p) => {
      const pos = p.position;
      return `<tr>
        <td>${pos.coin}</td>
        <td class="${pnlClass(pos.szi)}">${pos.szi}</td>
        <td>${pos.entryPx}</td>
        <td class="${pnlClass(pos.unrealizedPnl)}">${parseFloat(pos.unrealizedPnl).toFixed(2)}</td>
        <td>${pos.leverage?.value || "—"}x</td>
      </tr>`;
    }).join("");

    content().innerHTML = `
      <h2>Spot Balances</h2>
      ${spotBalances.length ? `<table><thead><tr><th>Coin</th><th>Total</th><th>In Use</th></tr></thead><tbody>${spotRows}</tbody></table>` : '<p class="loading">No spot balances</p>'}
      <h2 style="margin-top:1.5rem">Perps Account</h2>
      <table><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody>
        <tr><td>Account Value</td><td>${mb.accountValue}</td></tr>
        <tr><td>Total Margin Used</td><td>${mb.totalMarginUsed}</td></tr>
        <tr><td>Total Notional</td><td>${mb.totalNtlPos}</td></tr>
        <tr><td>Withdrawable</td><td>${perps.withdrawable}</td></tr>
      </tbody></table>
      <h2 style="margin-top:1.5rem">Positions</h2>
      ${positions.length ? `<table><thead><tr><th>Coin</th><th>Size</th><th>Entry</th><th>uPnL</th><th>Leverage</th></tr></thead><tbody>${posRows}</tbody></table>` : '<p class="loading">No open positions</p>'}`;
  } catch (e) { setError(e.message); }
}

async function showOrders() {
  setLoading();
  try {
    const data = await fetchInfo("openOrders", { user: wallet });
    if (!data.length) {
      content().innerHTML = '<h2>Open Orders</h2><p class="loading">No open orders</p>';
      return;
    }
    const rows = data.map((o) =>
      `<tr><td>${o.coin}</td><td>${o.side === "B" ? '<span class="pos">Buy</span>' : '<span class="neg">Sell</span>'}</td><td>${o.limitPx}</td><td>${o.sz}</td><td>${o.oid}</td></tr>`
    ).join("");
    content().innerHTML = `
      <h2>Open Orders</h2>
      <table><thead><tr><th>Coin</th><th>Side</th><th>Price</th><th>Size</th><th>OID</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  } catch (e) { setError(e.message); }
}

async function showTrades() {
  setLoading();
  try {
    const data = await fetchInfo("userFills", { user: wallet });
    const fills = data.slice(0, 50);
    if (!fills.length) {
      content().innerHTML = '<h2>Recent Trades</h2><p class="loading">No recent trades</p>';
      return;
    }
    const rows = fills.map((f) =>
      `<tr><td>${f.coin}</td><td>${f.side === "B" ? '<span class="pos">Buy</span>' : '<span class="neg">Sell</span>'}</td><td>${f.px}</td><td>${f.sz}</td><td>${f.fee}</td><td>${new Date(f.time).toLocaleString()}</td></tr>`
    ).join("");
    content().innerHTML = `
      <h2>Recent Trades</h2>
      <table><thead><tr><th>Coin</th><th>Side</th><th>Price</th><th>Size</th><th>Fee</th><th>Time</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  } catch (e) { setError(e.message); }
}

async function showFunding() {
  setLoading();
  try {
    const data = await fetchInfo("userFunding", {
      user: wallet,
      startTime: Date.now() - 7 * 24 * 60 * 60 * 1000,
    });
    if (!data.length) {
      content().innerHTML = '<h2>Funding History</h2><p class="loading">No funding payments</p>';
      return;
    }
    const rows = data.slice(0, 50).map((f) =>
      `<tr><td>${f.coin}</td><td class="${pnlClass(f.usdc)}">${parseFloat(f.usdc).toFixed(4)}</td><td>${f.fundingRate}</td><td>${new Date(f.time).toLocaleString()}</td></tr>`
    ).join("");
    content().innerHTML = `
      <h2>Funding History (7d)</h2>
      <table><thead><tr><th>Coin</th><th>Payment</th><th>Rate</th><th>Time</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  } catch (e) { setError(e.message); }
}

// --- Routing ---

const pages = { market: showMarket, account: showAccount, orders: showOrders, trades: showTrades, funding: showFunding };

function navigate(page) {
  document.querySelectorAll("nav a").forEach((a) => a.classList.toggle("active", a.dataset.page === page));
  if (pages[page]) pages[page]();
}

function currentPage() {
  return document.querySelector("nav a.active")?.dataset.page || "market";
}

document.addEventListener("DOMContentLoaded", () => {
  renderWalletSelect();

  document.querySelectorAll("nav a[data-page]").forEach((a) =>
    a.addEventListener("click", () => navigate(a.dataset.page))
  );

  document.getElementById("walletSelect").addEventListener("change", (e) => {
    wallet = e.target.value;
    navigate(currentPage());
  });

  document.getElementById("addWalletBtn").addEventListener("click", () => {
    const addr = document.getElementById("walletInput").value.trim();
    const label = document.getElementById("walletLabel").value.trim();
    if (!addr) return;
    const wallets = getWallets();
    if (wallets.some((w) => w.address.toLowerCase() === addr.toLowerCase())) return;
    wallets.push({ address: addr, label: label || "" });
    saveWallets(wallets);
    wallet = addr;
    renderWalletSelect();
    document.getElementById("walletInput").value = "";
    document.getElementById("walletLabel").value = "";
    navigate(currentPage());
  });

  document.getElementById("removeWalletBtn").addEventListener("click", () => {
    const wallets = getWallets().filter((w) => w.address !== wallet);
    if (!wallets.length) return;
    saveWallets(wallets);
    wallet = wallets[0].address;
    renderWalletSelect();
    navigate(currentPage());
  });

  navigate("market");
});
