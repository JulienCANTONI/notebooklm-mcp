# Multi-Account Management System

## Overview

The multi-account system enables industrial-grade authentication management for NotebookLM MCP by supporting:

- **Multiple Google accounts** with encrypted credential storage
- **Account pool rotation** with configurable strategies
- **Quota tracking** per account (50 queries/day free tier)
- **Automated login** with credential replay and interstitial handling
- **TOTP 2FA support** for accounts with two-factor authentication

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Account Management                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  Account 1  │    │  Account 2  │    │  Account N  │         │
│  │  (Primary)  │    │  (Backup)   │    │  (Pool)     │         │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘         │
│         │                  │                  │                 │
│         └──────────────────┴──────────────────┘                 │
│                            │                                    │
│                   ┌────────▼────────┐                           │
│                   │ AccountManager  │                           │
│                   │ - Pool logic    │                           │
│                   │ - Rotation      │                           │
│                   │ - Quota         │                           │
│                   └────────┬────────┘                           │
│                            │                                    │
│                   ┌────────▼────────┐                           │
│                   │ AutoLoginManager│                           │
│                   │ - Credential    │                           │
│                   │   replay        │                           │
│                   │ - 2FA/TOTP      │                           │
│                   │ - Interstitial  │                           │
│                   │   handling      │                           │
│                   └─────────────────┘                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Credential Encryption (`src/accounts/crypto.ts`)

- **Algorithm**: AES-256-GCM
- **Key Management**: Auto-generated encryption key stored securely
- **Storage**: Encrypted credentials in JSON format

```typescript
// Example encrypted credential structure
{
  emailEncrypted: "base64...",
  passwordEncrypted: "base64...",
  totpSecretEncrypted: "base64...", // Optional
  encryptedAt: "2024-01-15T10:30:00Z"
}
```

### 2. Account Manager (`src/accounts/account-manager.ts`)

Manages the account pool with:

- **Account lifecycle**: Add, remove, enable/disable
- **Quota tracking**: Per-account usage limits
- **Rotation strategies**:
  - `least_used`: Prefer accounts with lowest usage
  - `round_robin`: Sequential rotation
  - `failover`: Use primary until failure
  - `random`: Random selection from pool

### 3. Auto-Login Manager (`src/accounts/auto-login-manager.ts`)

Handles automated Google authentication:

- **Credential replay**: Email and password entry with human-like typing
- **TOTP 2FA**: Automatic code generation and entry
- **Interstitial handling**: Dismisses Google prompts (passkeys, security, etc.)
- **State persistence**: Saves authenticated session for reuse

## CLI Commands

```bash
# Add account (without 2FA)
npm run accounts add "user@gmail.com" "password"

# Add account (with TOTP)
npm run accounts add "user@gmail.com" "password" "JBSWY3DPEHPK3PXP"

# List all accounts
npm run accounts list

# Test auto-login
npm run accounts test <account-id>
npm run accounts test <account-id> --show  # With visible browser

# Check account health
npm run accounts health

# Set rotation strategy
npm run accounts strategy least_used

# Remove account
npm run accounts remove <account-id>
```

## Configuration

### Data Storage

Account data is stored in the platform-specific data directory:

- **Windows**: `%APPDATA%\notebooklm-mcp\Data\accounts\`
- **Linux**: `~/.local/share/notebooklm-mcp/accounts/`
- **macOS**: `~/Library/Application Support/notebooklm-mcp/accounts/`

### Files

| File                                     | Description                           |
| ---------------------------------------- | ------------------------------------- |
| `accounts.json`                          | Account configurations and state      |
| `encryption.key`                         | AES-256 encryption key (BACKUP THIS!) |
| `accounts/<id>/credentials.enc`          | Encrypted credentials per account     |
| `accounts/<id>/browser_state/state.json` | Session cookies per account           |

## Security Considerations

1. **Encryption Key**: The encryption key (`encryption.key`) must be backed up securely. Lost key = lost credentials.

2. **Credential Storage**: Credentials are encrypted at rest using AES-256-GCM.

3. **Browser Profiles**: Each account has isolated browser profile data.

4. **TOTP Secrets**: If stored, TOTP secrets are also encrypted.

## Limitations

1. **Google Account Requirements**: Accounts must have:
   - Completed profile (date of birth, etc.)
   - Standard password authentication enabled
   - Optional: TOTP 2FA configured (not SMS/phone)

2. **Google Security**: Google may still require additional verification for:
   - New device/location
   - Suspicious activity detection
   - Captcha challenges

3. **Rate Limits**: Google may rate-limit login attempts. Space out auto-login tests.

## Usage Example

```typescript
import { getAccountManager, AutoLoginManager } from './accounts/index.js';

// Get account manager
const manager = await getAccountManager();

// Add an account
const accountId = await manager.addAccount(
  'user@gmail.com',
  'password',
  'TOTP_SECRET' // optional
);

// Get best account based on rotation strategy
const selection = await manager.getBestAccount();
if (selection) {
  console.log(`Using: ${selection.account.config.email}`);
  console.log(`Reason: ${selection.reason}`);
}

// Perform auto-login
const autoLogin = new AutoLoginManager(manager);
const result = await autoLogin.performAutoLogin(accountId, { showBrowser: true });

if (result.success) {
  console.log('Login successful!');
} else {
  console.log(`Login failed: ${result.error}`);
  if (result.requiresManualIntervention) {
    console.log('Manual verification required');
  }
}

// Record usage (for quota tracking)
await manager.recordUsage(accountId);

// Check health of all accounts
const health = await manager.healthCheck();
```

## Future Enhancements

1. **Session Manager Integration**: Coordinate account selection with SessionManager
2. **Auto-refresh**: Background session keep-alive with cookie refresh
3. **Quota Alerts**: Notifications when approaching quota limits
4. **Account Analytics**: Usage patterns and optimization suggestions
