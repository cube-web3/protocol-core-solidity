# MAnual Deployment

Ensure the private keys and RPC url are set in the `.env` file.

Then, eg.:

```
source .env && forge script script/foundry/DeploySeplia.s.sol --rpc-url <rpc_url> -vvvvv --broadcast --verify

```

source .env && forge script script/foundry/demo/DeployDemoTokenFactory.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY -vvvvv --broadcast --verify
