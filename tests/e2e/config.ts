/**
 * E2E Test Configuration
 *
 * Centralized configuration for all E2E tests.
 * Supports multiple modes, languages, and accounts.
 */

export type TestMode = 'quick' | 'full';
export type TestLang = 'fr' | 'en';
export type TestAccount = 'mathieu' | 'rpmonster' | 'rom1pey';

// Parse CLI arguments or environment variables
export const config = {
  // Test mode: quick (54 tests) or full (76 tests)
  mode: (process.env.TEST_MODE || 'quick').toLowerCase() as TestMode,

  // UI language: fr or en
  lang: (process.env.TEST_LANG || 'fr').toLowerCase() as TestLang,

  // Account to use
  account: (process.env.TEST_ACCOUNT || 'mathieu').toLowerCase() as TestAccount,

  // Server URL
  serverUrl: process.env.SERVER_URL || 'http://localhost:3000',

  // Timeouts (ms)
  timeouts: {
    health: 10000,
    ask: 120000, // 2 minutes
    content: 180000, // 3 minutes
    audio: 300000, // 5 minutes
  },
};

// Account configurations
export const accounts: Record<TestAccount, { id: string; email: string }> = {
  mathieu: {
    id: 'account-1766565732376',
    email: 'mathieudumont31@gmail.com',
  },
  rpmonster: {
    id: 'account-1767078713573',
    email: 'rpmonster@gmail.com',
  },
  rom1pey: {
    id: 'account-1767079146601',
    email: 'rom1pey@gmail.com',
  },
};

// Notebook URLs per account
export const notebooks: Record<TestAccount, { readOnly: string; e2eTest: string }> = {
  mathieu: {
    readOnly: 'https://notebooklm.google.com/notebook/74912e55-34a4-4027-bdcc-8e89badd0efd', // CNV
    e2eTest: 'https://notebooklm.google.com/notebook/abd21688-02a6-4459-953b-30f0612a984e', // E2E-Test-Notebook
  },
  rpmonster: {
    readOnly: '',
    e2eTest: '',
  },
  rom1pey: {
    readOnly: 'https://notebooklm.google.com/notebook/258f62a1-8658-4f96-8333-a9e16224f602',
    e2eTest: 'https://notebooklm.google.com/notebook/258f62a1-8658-4f96-8333-a9e16224f602', // rom1pey-english-test
  },
};

// Helper to check if running in full mode
export const isFullMode = config.mode === 'full';

// Helper to get current account config
export const currentAccount = accounts[config.account];

// Helper to get current notebooks
export const currentNotebooks = notebooks[config.account];

// Log configuration on import
console.log(`
╔════════════════════════════════════════════════════════════╗
║  E2E Test Configuration                                     ║
╠════════════════════════════════════════════════════════════╣
║  Mode:    ${config.mode.toUpperCase().padEnd(48)}║
║  Lang:    ${config.lang.toUpperCase().padEnd(48)}║
║  Account: ${config.account.padEnd(48)}║
║  Server:  ${config.serverUrl.padEnd(48)}║
╚════════════════════════════════════════════════════════════╝
`);
