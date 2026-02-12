const DEFAULT_WALLETS = [];

function getWallets() {
  const saved = localStorage.getItem("hl_wallets");
  return saved ? JSON.parse(saved) : DEFAULT_WALLETS;
}

function saveWallets(wallets) {
  localStorage.setItem("hl_wallets", JSON.stringify(wallets));
}

let wallet = localStorage.getItem("hl_active_wallet") || getWallets()[0]?.address || "";
const content = () => document.getElementById("content");

// --- Cache per wallet ---
// Keys are scoped: hl_cache_{walletAddr}_{pageKey}
function getCacheKey(page, addr) {
  return `hl_cache_${(addr || wallet).slice(0,10)}_${page}`;
}

function clearWalletCache(addr) {
  ["account", "orders", "trades", "funding"].forEach(page => {
    localStorage.removeItem(getCacheKey(page, addr));
  });
}

function getCache(page) {
  try {
    const raw = localStorage.getItem(getCacheKey(page));
    if (!raw) return null;
    const { data, ts } = JSON.parse(raw);
    // Cache valid for 5 minutes
    if (Date.now() - ts > 5 * 60 * 1000) return null;
    return data;
  } catch { return null; }
}

function setCache(page, data) {
  try {
    localStorage.setItem(getCacheKey(page), JSON.stringify({ data, ts: Date.now() }));
  } catch { /* quota exceeded, ignore */ }
}

// Global market cache (not wallet-scoped)
function getMarketCache() {
  try {
    const raw = localStorage.getItem("hl_cache_market");
    if (!raw) return null;
    const { data, ts } = JSON.parse(raw);
    if (Date.now() - ts > 2 * 60 * 1000) return null;
    return data;
  } catch { return null; }
}

function setMarketCache(data) {
  try {
    localStorage.setItem("hl_cache_market", JSON.stringify({ data, ts: Date.now() }));
  } catch {}
}

// --- Toast ---
function showToast(msg, type = "info") {
  const container = document.getElementById("toastContainer");
  const el = document.createElement("div");
  el.className = `toast ${type}`;
  el.textContent = msg;
  container.appendChild(el);
  setTimeout(() => { el.remove(); }, 3000);
}

// --- Skeleton ---
function setSkeleton(count = 5) {
  resetRendered();
  content().innerHTML = `
    <div class="skeleton lg"></div>
    ${Array.from({length: count}, (_, i) =>
      `<div class="skeleton" style="width:${55 + i * 8}%"></div>`
    ).join("")}
  `;
}

// --- Helpers ---
function pnlClass(v) {
  const n = parseFloat(v);
  return n > 0 ? "pos" : n < 0 ? "neg" : "";
}

function fmt(v, d = 2) {
  const n = parseFloat(v);
  return isNaN(n) ? "—" : n.toLocaleString(undefined, { minimumFractionDigits: d, maximumFractionDigits: d });
}

function updateTimestamp() {
  document.getElementById("lastUpdated").textContent = "Updated " + new Date().toLocaleTimeString();
}

// Thin loading bar at top when refreshing in background
function showRefreshBar() {
  if (document.getElementById("refreshBar")) return;
  const bar = document.createElement("div");
  bar.className = "refresh-bar";
  bar.id = "refreshBar";
  document.body.appendChild(bar);
}

function hideRefreshBar() {
  document.getElementById("refreshBar")?.remove();
}

function coinDot() {
  return '<span class="coin-dot"></span>';
}

function requireWallet() {
  if (wallet) return true;
  setContent(`<div class="empty-state" style="padding:60px 20px">
    <div style="font-size:1.1rem;font-weight:600;color:var(--text);margin-bottom:8px">No wallet added</div>
    <div style="margin-bottom:16px">Add a wallet address to view this page.</div>
    <button onclick="openWalletModal()" class="btn-primary" style="display:inline-flex">Add Wallet</button>
  </div>`);
  return false;
}

// --- Wallet ---
function renderWalletChip() {
  const w = getWallets().find(w => w.address === wallet);
  const chip = document.getElementById("walletChipText");
  if (w) {
    chip.textContent = (w.label ? w.label + " · " : "") + w.address.slice(0, 6) + "…" + w.address.slice(-4);
  } else {
    chip.textContent = "Select wallet";
  }
}

// Balance cache per wallet address
function getBalanceCache(addr) {
  try {
    const raw = localStorage.getItem(`hl_bal_${addr.slice(0,10)}`);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch { return null; }
}

function setBalanceCache(addr, bal) {
  try {
    localStorage.setItem(`hl_bal_${addr.slice(0,10)}`, JSON.stringify(bal));
  } catch {}
}

function getSpotMidPrice(mids, coin, token) {
  if (coin === "USDC" || coin === "USDT") return 1;
  const byName = parseFloat(mids[coin]);
  if (byName) return byName;
  // Spot-only tokens use @{tokenIndex} as key in allMids
  if (token !== undefined) {
    const byToken = parseFloat(mids[`@${token}`]);
    if (byToken) return byToken;
  }
  return 0;
}

async function fetchWalletBalance(addr) {
  try {
    const [perps, spot] = await Promise.all([
      fetchInfo("clearinghouseState", { user: addr }),
      fetchInfo("spotClearinghouseState", { user: addr }),
    ]);
    const mb = perps.marginSummary || {};
    const perpsValue = parseFloat(mb.accountValue) || 0;
    const positions = (perps.assetPositions || []).filter(p => parseFloat(p.position.szi) !== 0);
    const uPnl = positions.reduce((s, p) => s + parseFloat(p.position.unrealizedPnl || 0), 0);

    // Sum spot balances (total value in USD — spot tokens don't have a direct USD value from this endpoint,
    // so we count the USDC/USDT balances directly and note non-stablecoin tokens separately)
    const spotBalances = (spot.balances || []).filter(b => parseFloat(b.total) > 0);
    // For a proper total, we'd need mid prices for each spot token.
    // Fetch mids to convert spot holdings to USD
    let spotUsdValue = 0;
    if (spotBalances.length) {
      try {
        const mids = await fetchInfo("allMids");
        for (const b of spotBalances) {
          const total = parseFloat(b.total) || 0;
          const price = getSpotMidPrice(mids, b.coin, b.token);
          spotUsdValue += total * price;
        }
      } catch {
        for (const b of spotBalances) {
          if (b.coin === "USDC" || b.coin === "USDT") {
            spotUsdValue += parseFloat(b.total) || 0;
          }
        }
      }
    }

    // Spot total includes perps margin, so total = spot + unrealized PnL only
    const total = spotUsdValue + uPnl;
    const bal = { perpsValue, spotValue: spotUsdValue, unrealizedPnl: uPnl, total, ts: Date.now() };
    setBalanceCache(addr, bal);
    return bal;
  } catch { return null; }
}

function renderWalletModal(filter = "") {
  const allWallets = getWallets();
  const f = filter.toLowerCase();
  const wallets = f
    ? allWallets.filter(w => (w.label || "").toLowerCase().includes(f) || w.address.toLowerCase().includes(f))
    : allWallets;
  const list = document.getElementById("walletList");
  list.innerHTML = wallets.map(w => {
    const cached = getBalanceCache(w.address);
    const balHtml = cached
      ? `<div class="wallet-item-balance">
          <span class="wallet-bal-total">$${fmt(cached.total)}</span>
          <span class="wallet-bal-pnl ${pnlClass(cached.unrealizedPnl)}">uPnL $${fmt(cached.unrealizedPnl)}</span>
        </div>
        <div class="wallet-item-breakdown">
          <span>Perps $${fmt(cached.perpsValue)}</span>
          <span>Spot $${fmt(cached.spotValue)}</span>
        </div>`
      : `<div class="wallet-item-balance"><span class="wallet-bal-loading">loading...</span></div>`;
    return `
    <div class="wallet-item ${w.address === wallet ? "active" : ""}" data-addr="${w.address}">
      <div class="wallet-item-left">
        <div class="wallet-item-label">${w.label || "Wallet"}</div>
        <div class="wallet-item-info">${w.address.slice(0, 10)}…${w.address.slice(-6)}</div>
        ${balHtml}
      </div>
      <div class="wallet-item-actions">
        <button class="wallet-item-copy" data-copy="${w.address}" title="Copy address">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
        </button>
        <button class="wallet-item-edit" data-edit="${w.address}" title="Rename">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17 3a2.85 2.85 0 0 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
        </button>
        ${wallets.length > 1 ? `<button class="wallet-item-remove" data-remove="${w.address}">&times;</button>` : ""}
      </div>
    </div>`;
  }).join("");

  list.querySelectorAll(".wallet-item").forEach(el => {
    el.addEventListener("click", (e) => {
      if (e.target.closest(".wallet-item-remove") || e.target.closest(".wallet-item-edit") || e.target.closest(".wallet-item-copy")) return;
      clearWalletCache(el.dataset.addr);
      wallet = el.dataset.addr;
      localStorage.setItem("hl_active_wallet", wallet);
      renderWalletChip();
      renderWalletModal();
      closeWalletModal();
      navigate(currentPage());
    });
  });

  list.querySelectorAll(".wallet-item-remove").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const addr = btn.dataset.remove;
      const ws = getWallets().filter(w => w.address !== addr);
      if (!ws.length) return;
      saveWallets(ws);
      if (wallet === addr) {
        wallet = ws[0].address;
        localStorage.setItem("hl_active_wallet", wallet);
      }
      renderWalletChip();
      renderWalletModal();
      showToast("Wallet removed");
    });
  });

  list.querySelectorAll(".wallet-item-copy").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      navigator.clipboard.writeText(btn.dataset.copy).then(() => {
        showToast("Address copied", "success");
      }).catch(() => {
        showToast("Failed to copy", "error");
      });
    });
  });

  list.querySelectorAll(".wallet-item-edit").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const addr = btn.dataset.edit;
      const wallets = getWallets();
      const w = wallets.find(w => w.address === addr);
      if (!w) return;
      const newLabel = prompt("Rename wallet:", w.label || "");
      if (newLabel === null) return;
      w.label = newLabel.trim();
      saveWallets(wallets);
      renderWalletChip();
      renderWalletModal();
      showToast("Wallet renamed", "success");
    });
  });
}

function openWalletModal() {
  document.getElementById("walletModal").classList.remove("hidden");
  const searchInput = document.getElementById("walletSearch");
  searchInput.value = "";
  renderWalletModal();

  // Wire up search
  searchInput.addEventListener("input", () => {
    renderWalletModal(searchInput.value);
  });

  // Fetch fresh balances for all wallets
  const wallets = getWallets();
  wallets.forEach(w => {
    fetchWalletBalance(w.address).then(() => {
      if (!document.getElementById("walletModal").classList.contains("hidden")) {
        renderWalletModal(searchInput.value);
      }
    });
  });
}

function closeWalletModal() {
  document.getElementById("walletModal").classList.add("hidden");
}

// --- Diff helper: skip re-render if data unchanged ---
function dataChanged(a, b) {
  return JSON.stringify(a) !== JSON.stringify(b);
}

// Track if content already has a rendered page (not skeleton)
let hasRendered = false;

function setContent(html) {
  const el = content();
  if (!hasRendered) {
    // First paint: animate cards in
    el.innerHTML = `<div class="animate-in">${html}</div>`;
    hasRendered = true;
  } else {
    // Update: no animation, just swap content
    el.innerHTML = html;
  }
}

function resetRendered() {
  hasRendered = false;
}

// --- Pages ---

async function showMarket() {
  const cached = getMarketCache();
  if (cached) {
    renderMarket(cached);
    showRefreshBar();
  } else {
    setSkeleton(8);
  }

  try {
    const [mids, meta] = await Promise.all([fetchInfo("allMids"), fetchInfo("meta")]);
    const universe = meta.universe || [];
    const rows = universe.map(coin => {
      const mid = mids[coin.name];
      return { name: coin.name, mid: mid ? parseFloat(mid) : null, szDec: coin.szDecimals };
    });
    if (!cached || dataChanged(cached, rows)) {
      setMarketCache(rows);
      renderMarket(rows);
    }
    updateTimestamp();
  } catch (e) {
    if (!cached) {
      showToast(e.message, "error");
      setContent(`<div class="empty-state">${e.message}</div>`);
    }
  } finally {
    hideRefreshBar();
  }
}

function renderMarket(rows, filter = "") {
  const f = filter.toLowerCase();
  const filtered = f ? rows.filter(r => r.name.toLowerCase().includes(f)) : rows;
  const tbody = filtered.map((r, i) => `
    <tr>
      <td><span class="market-rank">${i + 1}</span></td>
      <td><span class="coin-tag">${coinDot()}<strong>${r.name}</strong></span></td>
      <td style="font-family:var(--font-mono)">${r.mid !== null ? fmt(r.mid, r.mid > 100 ? 2 : 4) : "—"}</td>
      <td>${r.szDec}</td>
    </tr>
  `).join("");

  setContent(`
    <div class="search-wrap">
      <input class="search-input" placeholder="Search assets..." value="${filter}" id="marketSearch">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
    </div>
    <div class="card">
      <div class="card-title">All Markets (${filtered.length})</div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Asset</th><th>Mid Price</th><th>Sz Dec</th></tr></thead>
          <tbody>${tbody}</tbody>
        </table>
      </div>
    </div>
  `);
  document.getElementById("marketSearch").addEventListener("input", e => renderMarket(rows, e.target.value));
}

async function showAccount() {
  if (!requireWallet()) return;
  const cached = getCache("account");
  if (cached) {
    renderAccount(cached);
    showRefreshBar();
  } else {
    setSkeleton(6);
  }

  try {
    const [perps, spot, mids] = await Promise.all([
      fetchInfo("clearinghouseState", { user: wallet }),
      fetchInfo("spotClearinghouseState", { user: wallet }),
      fetchInfo("allMids"),
    ]);
    const data = { perps, spot, mids };
    if (!cached || dataChanged(cached, data)) {
      setCache("account", data);
      renderAccount(data);
    }
    updateTimestamp();
  } catch (e) {
    if (!cached) {
      showToast(e.message, "error");
      setContent(`<div class="empty-state">${e.message}</div>`);
    }
  } finally {
    hideRefreshBar();
  }
}

function renderAccount({ perps, spot, mids }) {
  const mb = perps.marginSummary || {};
  const perpsValue = parseFloat(mb.accountValue) || 0;
  const spotBalances = (spot.balances || []).filter(b => parseFloat(b.total) > 0);
  const positions = (perps.assetPositions || []).filter(p => parseFloat(p.position.szi) !== 0);
  const totalPnl = positions.reduce((s, p) => s + parseFloat(p.position.unrealizedPnl || 0), 0);

  // Calculate spot USD value
  let spotUsdValue = 0;
  for (const b of spotBalances) {
    const total = parseFloat(b.total) || 0;
    const price = mids ? getSpotMidPrice(mids, b.coin, b.token) : (b.coin === "USDC" || b.coin === "USDT" ? 1 : 0);
    spotUsdValue += total * price;
  }
  // Spot total already includes perps margin (shown as "hold" in spot USDC).
  // To avoid double-counting, total = spot value + perps unrealized PnL only.
  const totalBalance = spotUsdValue + totalPnl;

  setContent(`
    <div class="card">
      <div class="card-title">Total Balance</div>
      <div class="total-balance-display">
        <span class="total-balance-value">$${fmt(totalBalance)}</span>
        <span class="total-balance-pnl ${pnlClass(totalPnl)}">uPnL $${fmt(totalPnl)}</span>
      </div>
      <div class="total-balance-breakdown">
        <span>Perps $${fmt(perpsValue)}</span>
        <span>Spot $${fmt(spotUsdValue)}</span>
      </div>
    </div>

    <div class="card">
      <div class="card-title">Perps Account</div>
      <div class="stat-row">
        <div class="stat-chip">
          <div class="label">Account Value</div>
          <div class="value">$${fmt(mb.accountValue)}</div>
        </div>
        <div class="stat-chip">
          <div class="label">Unrealized PnL</div>
          <div class="value ${pnlClass(totalPnl)}">$${fmt(totalPnl)}</div>
        </div>
        <div class="stat-chip">
          <div class="label">Margin Used</div>
          <div class="value">$${fmt(mb.totalMarginUsed)}</div>
        </div>
        <div class="stat-chip">
          <div class="label">Withdrawable</div>
          <div class="value">$${fmt(perps.withdrawable)}</div>
        </div>
      </div>
    </div>

    ${positions.length ? `
    <div class="card">
      <div class="card-title">Positions (${positions.length})</div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Coin</th><th>Size</th><th>Entry</th><th>uPnL</th><th>Lev</th></tr></thead>
          <tbody>${positions.map(p => {
            const pos = p.position;
            return `<tr>
              <td><span class="coin-tag">${coinDot()}<strong>${pos.coin}</strong></span></td>
              <td class="${pnlClass(pos.szi)}" style="font-family:var(--font-mono)">${pos.szi}</td>
              <td style="font-family:var(--font-mono)">${fmt(pos.entryPx, 2)}</td>
              <td class="${pnlClass(pos.unrealizedPnl)}" style="font-family:var(--font-mono)">$${fmt(pos.unrealizedPnl)}</td>
              <td>${pos.leverage?.value || "—"}x</td>
            </tr>`;
          }).join("")}</tbody>
        </table>
      </div>
    </div>` : ""}

    ${spotBalances.length ? `
    <div class="card">
      <div class="card-title">Spot Balances ($${fmt(spotUsdValue)})</div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Coin</th><th>Total</th><th>USD Value</th><th>In Use</th></tr></thead>
          <tbody>${spotBalances.map(b => {
            const total = parseFloat(b.total) || 0;
            const price = mids ? getSpotMidPrice(mids, b.coin, b.token) : (b.coin === "USDC" || b.coin === "USDT" ? 1 : 0);
            const usdVal = total * price;
            return `<tr>
            <td><span class="coin-tag">${coinDot()}<strong>${b.coin}</strong></span></td>
            <td style="font-family:var(--font-mono)">${b.total}</td>
            <td style="font-family:var(--font-mono)">$${fmt(usdVal)}</td>
            <td style="font-family:var(--font-mono)">${b.hold}</td>
          </tr>`;
          }).join("")}</tbody>
        </table>
      </div>
    </div>` : ""}

    ${!positions.length && !spotBalances.length ? '<div class="empty-state">No positions or balances</div>' : ""}
  `);
}

async function showOrders() {
  if (!requireWallet()) return;
  const cached = getCache("orders");
  if (cached) {
    renderOrders(cached);
    showRefreshBar();
  } else {
    setSkeleton(4);
  }

  try {
    const [openOrders, fills] = await Promise.all([
      fetchInfo("frontendOpenOrders", { user: wallet }),
      fetchInfo("userFills", { user: wallet }),
    ]);
    const data = { openOrders, fills: fills.slice(0, 30) };
    if (!cached || dataChanged(cached, data)) {
      setCache("orders", data);
      renderOrders(data);
    }
    updateTimestamp();
  } catch (e) {
    if (!cached) {
      showToast(e.message, "error");
      setContent(`<div class="empty-state">${e.message}</div>`);
    }
  } finally {
    hideRefreshBar();
  }
}

function renderOrders({ openOrders, fills }, activeTab = "open") {
  const openContent = openOrders.length ? `
    <div class="table-wrap"><table>
      <thead><tr><th>Coin</th><th>Side</th><th>Price</th><th>Size</th><th>Type</th></tr></thead>
      <tbody>${openOrders.map(o => {
        // Direction: show Close Long/Short for position TP/SL orders
        let sideLabel, sideClass;
        if (o.isPositionTpsl) {
          sideLabel = o.side === 'A' ? 'Close Long' : 'Close Short';
          sideClass = o.side === 'A' ? 'sell' : 'buy';
        } else if (o.reduceOnly) {
          sideLabel = o.side === 'B' ? 'Close Short' : 'Close Long';
          sideClass = o.side === 'B' ? 'buy' : 'sell';
        } else {
          sideLabel = o.side === 'B' ? 'Long' : 'Short';
          sideClass = o.side === 'B' ? 'buy' : 'sell';
        }
        // Price: show trigger price for trigger orders, "Market" for market types
        const isMarketType = (o.orderType || '').includes('Market');
        const price = o.isTrigger
          ? (isMarketType ? 'Market' : o.limitPx)
          : o.limitPx;
        const triggerInfo = o.isTrigger && o.triggerPx !== '0' ? o.triggerPx : '';
        // Size: show "--" for position TP/SL with no fixed size
        const rawSize = parseFloat(o.sz) === 0 && parseFloat(o.origSz) === 0 ? '—' : (parseFloat(o.sz) === 0 ? o.origSz : o.sz);
        return `<tr>
        <td><span class="coin-tag">${coinDot()}<strong>${o.coin}</strong></span></td>
        <td><span class="badge ${sideClass}">${sideLabel}</span></td>
        <td style="font-family:var(--font-mono)">${price}${triggerInfo ? `<div style="font-size:0.6rem;color:var(--text-dim)">trigger: ${triggerInfo}</div>` : ''}</td>
        <td style="font-family:var(--font-mono)">${rawSize}</td>
        <td style="font-size:0.65rem;color:var(--text-secondary)">${o.orderType || 'Limit'}</td>
      </tr>`;
      }).join("")}</tbody>
    </table></div>` : '<div class="empty-state">No open orders</div>';

  const historyContent = fills.length ? `
    <div class="table-wrap"><table>
      <thead><tr><th>Coin</th><th>Side</th><th>Price</th><th>Size</th><th>Fee</th><th>Time</th></tr></thead>
      <tbody>${fills.map(f => `<tr>
        <td><span class="coin-tag">${coinDot()}<strong>${f.coin}</strong></span></td>
        <td><span class="badge ${f.side === 'B' ? 'buy' : 'sell'}">${f.side === 'B' ? 'Buy' : 'Sell'}</span></td>
        <td style="font-family:var(--font-mono)">${f.px}</td>
        <td style="font-family:var(--font-mono)">${f.sz}</td>
        <td style="font-family:var(--font-mono)">${f.fee}</td>
        <td style="font-size:0.68rem;color:var(--text-secondary)">${new Date(f.time).toLocaleString()}</td>
      </tr>`).join("")}</tbody>
    </table></div>` : '<div class="empty-state">No recent fills</div>';

  setContent(`
    <div class="tab-bar-inner">
      <button class="tab-btn ${activeTab === 'open' ? 'active' : ''}" data-tab="open">Open (${openOrders.length})</button>
      <button class="tab-btn ${activeTab === 'history' ? 'active' : ''}" data-tab="history">History (${fills.length})</button>
    </div>
    <div class="card">${activeTab === 'open' ? openContent : historyContent}</div>
  `);

  const data = { openOrders, fills };
  content().querySelectorAll(".tab-btn").forEach(btn => {
    btn.addEventListener("click", () => renderOrders(data, btn.dataset.tab));
  });
}

async function showTrades() {
  if (!requireWallet()) return;
  const cached = getCache("trades");
  if (cached) {
    renderTrades(cached);
    showRefreshBar();
  } else {
    setSkeleton(6);
  }

  try {
    const data = await fetchInfo("userFills", { user: wallet });
    const fills = data.slice(0, 100);
    if (!cached || dataChanged(cached, fills)) {
      setCache("trades", fills);
      renderTrades(fills);
    }
    updateTimestamp();
  } catch (e) {
    if (!cached) {
      showToast(e.message, "error");
      setContent(`<div class="empty-state">${e.message}</div>`);
    }
  } finally {
    hideRefreshBar();
  }
}

function renderTrades(fills, activeCoin = "All") {
  if (!fills.length) {
    content().innerHTML = '<div class="empty-state">No recent trades</div>';
    return;
  }
  const coins = [...new Set(fills.map(f => f.coin))];
  const filtered = activeCoin === "All" ? fills : fills.filter(f => f.coin === activeCoin);

  setContent(`
    <div class="filter-chips">
      <button class="filter-chip ${activeCoin === 'All' ? 'active' : ''}" data-coin="All">All</button>
      ${coins.map(c => `<button class="filter-chip ${activeCoin === c ? 'active' : ''}" data-coin="${c}">${c}</button>`).join("")}
    </div>
    <div class="card">
      <div class="card-title">Trades (${filtered.length})</div>
      <div class="table-wrap"><table>
        <thead><tr><th>Coin</th><th>Side</th><th>Price</th><th>Size</th><th>Fee</th><th>Time</th></tr></thead>
        <tbody>${filtered.map(f => `<tr>
          <td><span class="coin-tag">${coinDot()}<strong>${f.coin}</strong></span></td>
          <td><span class="badge ${f.side === 'B' ? 'buy' : 'sell'}">${f.side === 'B' ? 'Buy' : 'Sell'}</span></td>
          <td style="font-family:var(--font-mono)">${f.px}</td>
          <td style="font-family:var(--font-mono)">${f.sz}</td>
          <td style="font-family:var(--font-mono)">${f.fee}</td>
          <td style="font-size:0.68rem;color:var(--text-secondary)">${new Date(f.time).toLocaleString()}</td>
        </tr>`).join("")}</tbody>
      </table></div>
    </div>
  `);
  content().querySelectorAll(".filter-chip").forEach(chip => {
    chip.addEventListener("click", () => renderTrades(fills, chip.dataset.coin));
  });
}

async function showFunding() {
  if (!requireWallet()) return;
  const cached = getCache("funding");
  if (cached) {
    renderFunding(cached);
    showRefreshBar();
  } else {
    setSkeleton(6);
  }

  try {
    const data = await fetchInfo("userFunding", { user: wallet, startTime: Date.now() - 7 * 24 * 60 * 60 * 1000 });
    const entries = data.slice(0, 50);
    if (!cached || dataChanged(cached, entries)) {
      setCache("funding", entries);
      renderFunding(entries);
    }
    updateTimestamp();
  } catch (e) {
    if (!cached) {
      showToast(e.message, "error");
      setContent(`<div class="empty-state">${e.message}</div>`);
    }
  } finally {
    hideRefreshBar();
  }
}

function renderFunding(entries) {
  if (!entries.length) {
    content().innerHTML = '<div class="empty-state">No funding payments in the last 7 days</div>';
    updateTimestamp();
    return;
  }
  const totalFunding = entries.reduce((s, f) => s + parseFloat(f.usdc || 0), 0);

  setContent(`
    <div class="card">
      <div class="card-title">7-Day Funding Summary</div>
      <div class="stat-row">
        <div class="stat-chip">
          <div class="label">Total Funding</div>
          <div class="value ${pnlClass(totalFunding)}">$${fmt(totalFunding, 4)}</div>
        </div>
        <div class="stat-chip">
          <div class="label">Payments</div>
          <div class="value">${entries.length}</div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-title">Funding History</div>
      <div class="table-wrap"><table>
        <thead><tr><th>Coin</th><th>Payment</th><th>Rate</th><th>Time</th></tr></thead>
        <tbody>${entries.map(f => `<tr>
          <td><span class="coin-tag">${coinDot()}<strong>${f.coin}</strong></span></td>
          <td class="${pnlClass(f.usdc)}" style="font-family:var(--font-mono)">$${fmt(parseFloat(f.usdc), 4)}</td>
          <td style="font-family:var(--font-mono)">${f.fundingRate}</td>
          <td style="font-size:0.68rem;color:var(--text-secondary)">${new Date(f.time).toLocaleString()}</td>
        </tr>`).join("")}</tbody>
      </table></div>
    </div>
  `);
}

// --- Routing ---
const pages = { market: showMarket, account: showAccount, orders: showOrders, trades: showTrades, funding: showFunding };

function navigate(page) {
  resetRendered();
  hideRefreshBar();
  document.querySelectorAll("#tabBar .tab").forEach(a => a.classList.toggle("active", a.dataset.page === page));
  if (pages[page]) pages[page]();
}

function currentPage() {
  return document.querySelector("#tabBar .tab.active")?.dataset.page || "market";
}

// --- Pull to Refresh ---
let touchStart = 0;
document.addEventListener("touchstart", e => { touchStart = e.touches[0].clientY; }, { passive: true });
document.addEventListener("touchend", e => {
  if (window.scrollY === 0 && e.changedTouches[0].clientY - touchStart > 80) {
    // Force refresh: clear cache for current page
    const page = currentPage();
    if (page === "market") {
      localStorage.removeItem("hl_cache_market");
    } else {
      localStorage.removeItem(getCacheKey(page));
    }
    navigate(page);
    showToast("Refreshed", "success");
  }
}, { passive: true });

// --- Init ---
document.addEventListener("DOMContentLoaded", () => {
  renderWalletChip();

  document.getElementById("walletChip").addEventListener("click", openWalletModal);
  document.getElementById("walletModalClose").addEventListener("click", closeWalletModal);
  document.getElementById("walletModal").addEventListener("click", e => {
    if (e.target === e.currentTarget) closeWalletModal();
  });

  document.getElementById("addWalletBtn").addEventListener("click", () => {
    const addr = document.getElementById("walletInput").value.trim();
    const label = document.getElementById("walletLabel").value.trim();
    if (!addr) return;
    const wallets = getWallets();
    if (wallets.some(w => w.address.toLowerCase() === addr.toLowerCase())) {
      showToast("Wallet already exists", "error"); return;
    }
    wallets.push({ address: addr, label: label || "" });
    saveWallets(wallets);
    wallet = addr;
    localStorage.setItem("hl_active_wallet", wallet);
    document.getElementById("walletInput").value = "";
    document.getElementById("walletLabel").value = "";
    renderWalletChip();
    renderWalletModal();
    showToast("Wallet added", "success");
  });

  document.querySelectorAll("#tabBar .tab").forEach(a =>
    a.addEventListener("click", () => navigate(a.dataset.page))
  );

  navigate("market");

  // Register SW
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
});
