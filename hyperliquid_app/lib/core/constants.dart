const String apiUrl = 'https://api.hyperliquid.xyz/info';
const Duration marketCacheTtl = Duration(minutes: 2);
const Duration walletCacheTtl = Duration(minutes: 5);
const int maxFills = 30;
const int maxTrades = 100;
const int maxFunding = 50;
const int fundingDays = 7;

// Auto-refresh intervals (only active tab refreshes)
const Duration marketRefreshInterval = Duration(seconds: 15);
const Duration accountRefreshInterval = Duration(seconds: 30);
const Duration ordersRefreshInterval = Duration(seconds: 60);
const Duration tradesRefreshInterval = Duration(seconds: 60);
const Duration fundingRefreshInterval = Duration(seconds: 120);

// Pagination
const int paginationDaysBack = 7;
const int msPerDay = 86400000;
