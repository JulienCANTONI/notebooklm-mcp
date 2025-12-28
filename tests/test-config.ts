/**
 * Test Configuration Loader
 *
 * Loads test configuration from the local file.
 * If the local file doesn't exist, provides instructions.
 */

import { existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const localConfigPath = resolve(__dirname, 'test-config.local.ts');

// Check if local config exists
if (!existsSync(localConfigPath)) {
  console.error(`
╔════════════════════════════════════════════════════════════════════╗
║                    TEST CONFIGURATION MISSING                       ║
╠════════════════════════════════════════════════════════════════════╣
║  The local test configuration file is missing.                     ║
║                                                                    ║
║  To set up your test environment:                                  ║
║                                                                    ║
║  1. Copy the example configuration:                                ║
║     cp tests/test-config.example.ts tests/test-config.local.ts     ║
║                                                                    ║
║  2. Edit tests/test-config.local.ts with your values:              ║
║     - Your notebook UUIDs                                          ║
║     - Your account IDs                                             ║
║     - Any other test-specific data                                 ║
║                                                                    ║
║  Note: test-config.local.ts is git-ignored and will never be       ║
║  overwritten by git operations.                                    ║
╚════════════════════════════════════════════════════════════════════╝
`);
  process.exit(1);
}

// Dynamic import of local config
export const { testConfig } = await import('./test-config.local.js');
export type { TestConfig } from './test-config.local.js';
