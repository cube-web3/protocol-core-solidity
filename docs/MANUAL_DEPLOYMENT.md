# MAnual Deployment

Ensure the private keys and RPC url are set in the `.env` file.

Then, eg.:

```
source .env && forge script script/foundry/DeploySeplia.s.sol --rpc-url <rpc_url> -vvvvv --broadcast --verify

```

source .env && forge script script/foundry/demo/DeployDemoTokenFactory.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/7EV4zME4TAynmG7U4GMmhEHncVOVOdY3 -vvvvv --broadcast --verify
