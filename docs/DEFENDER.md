# Protocol Management

The protocol is deployed and managed using [Openzeppelin Defender V2](https://docs.openzeppelin.com/defender/v2/).

`Relayers` are managed accounts, a public-private keypair is generated for each relayer account. OZ controls the private key, it cannot be exported. Transactions can be triggered for the relay account via an API endpoint (or SDK) using the API key generated in the dashboard.

Eg. A 'Key Manager' relayer. CUBE3 picks up event offchain, generates a signature.

- Possible uses:
  - One of the manager roles

# Notes

- Deploy via foundry
- Upgrade via multisig

# Accounts and Roles

## Admin

`CUBE3_PROTOCOL_ADMIN_ROLE`

Assigned to members of the CUBE3 team with the ability to configure the protocol. The protocol admin role has the ability to update the protocol's configuration, install and deprecate modules, and execute privileged calls on modules via the router. Primarily controls access to functions in `ProtocolManagement.sol`. This role should be assigned to a multi-sig controlled by the CUBE3 team.

## Key Manager

`CUBE3_INTEGRATION_MANAGER_ROLE`

Assigned to members of the CUBE3 team who can modify an integration's access to the protocol. Accounts assigned this role have the ability to make integration-level changes, such as modifying integration registration status (access to the protocol). This role can be assigned to a programmatic account that is controlled by the CUBE3 team. For example, a programmatic account that revokes registration in the event a user stops paying for the off-chain CUBE3 services.

## Integration Manager

`CUBE3_KEY_MANAGER_ROLE`

Accounts responsible for modifying state of the `Cube3Registry`. This role acts on behalf of the CUBE3 KMS and can set/revoke signing authorities for integration contracts. The scope of this role is limited to the `Cube3Registry` contract.

# Steps

- Create a gnosis safe (on each network) with desired number of signers. This safe is responsible for upgrading contracts [TODO what else?]
- Setup the test env
  - Create approval process deploy using a relayer
  - Create approval process for upgrade using a multisig
- Save team api key + secret to repo .env
- Add Etherscan API key to testnet env configuration
-

# Deployment & Verification

We use [openzeppelin-foundry-upgrades](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades). Note the requirements for the foundry.toml:

```
Note The above remappings mean that both @openzeppelin/contracts/ (including proxy contracts deployed by this library) and @openzeppelin/contracts-upgradeable/ come from your installation of the openzeppelin-contracts-upgradeable submodule and its subdirectories, which includes its own transitive copy of openzeppelin-contracts of the same release version number. This format is needed for Etherscan verification to work. Particularly, any copies of openzeppelin-contracts that you install separately are NOT used.
```

### Deployment commands

ensure that `DEFENDER_KEY` and `DEFENDER_SECRET`, and `DEFENDER_NETWORK` are set correctly in the `.env` file.

```
forge clean \
&& forge build \
&& forge script script/foundry/DefenderDeploySepolia.s.sol \
--force \
--rpc-url <rpc_url> \
--verify
```
