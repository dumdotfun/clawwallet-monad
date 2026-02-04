# ClawWallet - Monad

One-click wallets for AI agents on Monad.

## Deployed

**Testnet Contract:** `0x00A99375c201E91e58257D67529D48846d32B854`
**Chain ID:** 10143
**RPC:** https://testnet-rpc.monad.xyz

## Features

- **Free wallet creation** — 100 welcome points per wallet
- **MON + Token support** — Native and ERC20 transfers
- **Agent-to-Agent** — Send by agent ID, not addresses
- **Points system** — 1-10 points per tx (2x for tokens)
- **0.5% fee** — Sustainable, transparent

## Usage

### Create Wallet
```solidity
bytes32 agentId = clawWallet.createWallet("my-agent");
```

### Deposit MON
```solidity
clawWallet.deposit{value: 1 ether}(agentId);
```

### Send MON
```solidity
clawWallet.send(agentId, recipientAddress, amount);
```

### Agent-to-Agent Transfer
```solidity
clawWallet.sendToAgent(fromAgentId, toAgentId, amount);
```

### Send Tokens
```solidity
clawWallet.sendToken(agentId, recipientAddress, tokenAddress, amount);
```

## Contract Interface

```solidity
function createWallet(string calldata agentName) external returns (bytes32 agentId);
function deposit(bytes32 agentId) external payable;
function depositToken(bytes32 agentId, address token, uint256 amount) external;
function send(bytes32 agentId, address to, uint256 amount) external;
function sendToken(bytes32 agentId, address to, address token, uint256 amount) external;
function sendToAgent(bytes32 fromAgentId, bytes32 toAgentId, uint256 amount) external;
function getWallet(bytes32 agentId) external view returns (...);
function getAgentId(string calldata agentName) external pure returns (bytes32);
```

## Hackathon

Built for **Moltiverse Hackathon** (Feb 2-15, 2026)
Track: Agent Track

## Links

- [Monad Testnet Explorer](https://testnet.monadexplorer.com/address/0x00A99375c201E91e58257D67529D48846d32B854)
- [GitHub](https://github.com/dumdotfun/clawwallet)
- [Solana Version](https://dumdotfun.github.io/clawwallet) (Colosseum Hackathon)

## License

MIT
