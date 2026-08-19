# infra-web3-toolkit

`infra-web3-toolkit` is a personal production-grade toolkit that bridges high-traffic Linux server operations with decentralized payment gateway primitives on Solana Pay.

## Architecture

```text
infra-web3-toolkit/
├── infrastructure/
│   └── core_optimizer.sh          # Linux kernel/network/firewall baseline for high-connection services
├── src/
│   ├── backend/
│   │   ├── app.js                 # Express API entrypoint with security middleware and rate limiting
│   │   └── routes/
│   │       └── v1/
│   │           └── status.js      # /api/v1/status health endpoint
│   └── web3/
│       └── solana_pay_service.js  # Solana Pay URL generation + devnet signature validation skeleton
└── package.json
```

## Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create environment file:

   ```bash
   cp .env.example .env
   ```

3. Start the backend service:

   ```bash
   npm start
   ```

4. Run lightweight syntax checks:

   ```bash
   npm run check
   ```

## Environment Variables

Create `.env` with the following structure:

```dotenv
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:3000,http://127.0.0.1:3000
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=120
SOLANA_RPC_ENDPOINT=https://api.devnet.solana.com
```

## Security Notes

- `infrastructure/core_optimizer.sh` must be executed with root privileges on Linux hosts.
- Firewall rules included are skeletons; restrict panel ports (e.g., `7000/tcp`) to trusted private CIDRs before production rollout.
- Solana RPC providers enforce strict request quotas; implement retries with exponential backoff and jitter when validating transaction signatures.
- Never commit private keys, seed phrases, or production RPC credentials to source control.
