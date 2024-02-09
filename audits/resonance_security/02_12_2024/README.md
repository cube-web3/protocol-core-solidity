# CUBE3 Protocol Audit Overview

## Introduction

This scoping document covers both this repository (protocol-core-solidity) and the [protection-solidity](https://github.com/cube-web3/protection-solidity) repository.

This repo contains V2 of the CUBE3 protocol. V2 is a complete rewrite of the original protocol. While functionally similar, this new version of the protocol contains significant differences when compared to the [first version](https://github.com/cube-web3/cube3-protocol). The primary motivation for the re-write is to address customer concerns and focus on the following:

- Reduce complexity
- Improve readability
- Lower contract size of inheritable protection contracts
- Reduce gas usage
- Improve the user and developer experience

The main areas of change include:

**Architecture**

- The core protocol and inheritable protection contract have been separated into separate repositories. There's no need for a user to add the protocol or its dependencies to their codebase. The contracts required to create an integration can be found in the [protection-solidity](https://github.com/cube-web3/protection-solidity) repo.
- The `Cube3Registry` is now a singleton and is no longer upgradeable.
- The `Cube3GateKeeper` has been removed from the protocol.

**Integration/Protection Contracts**

- Removed all external dependencies, ie `OpenZeppelin`.
- No longer includes or requires access control.
- All protection logic has been moved to the `Cube3Router`.
- Introduced ERC7201 storage layout.
- All implementations, ie proxy/singletons, share a single base contract.

**Router**

- Contains all protection logic for integration contracts. Users now call the Router directly to update protection logic.
- New inheritance structure, with integration management and protocol management separated into separate abstract contracts.
- Implements ERC7201 namespaced storage layout.
- Dedicated getters and setters are used for all storage read/writes.
- Removed the concept of `AuthorizationStatus`.
- The Router itself no longer has the ability to revert user transactions. The Router can only return early, forcing the top-level call to bypass routing functionality if access is revoked.
- The Router is now pausible, which will bypass routing and return early.

**Registry**

- The registry is now a singleton and no longer upgradeable.
- No longer uses an invalidation nonce.
- The registry contract can be deprecated and replaced with a new registry contract. This would likely only happen in the event of a KMS compromise.

**Payload Layout**

- Routing information is now included as the last word of the payload, instead of as a header, making it easier to extract from calldata.
- All routing data is packed into a `uint256` bitmap.

# Protocol Properties

TODO: complete

- The Core Protocol provides on-chain security features for smart contracts that inherit the ancillary protection contracts.
- In order to make use of CUBE3's on-chain protocol, the integration contract must receive data provided by CUBE3's off-chain services.
- An integration can disconnect from the protocol at any time, or be disconnected from the protocol by CUBE3. From a user-standpoint, disconnecting prevents calls to the router from taking place. Disconnection from the protocol side still requires a call to the Router, which will return early and bypass the protocol's functionality.

## Storage

Both the Core Protocol and Protection abstractions make use of `ERC7201` namespaced storage layout. This serves a dual purpose of helping to prevent storage collisions for upgradeable contracts, and to help reduce transaction costs by facilitating the use of an `accessList` to pre-warm the storage slots we know will be accessed during all transactions - introduced in `EIP-2930`.

Both the protection contracts and the core protocol share the storage namespace of `cube3.storage`, with the start of storage layout assigned to the slot: `0xd26911dcaedb68473d1e75486a92f0a8e6ef3479c0c1c4d6684d3e2888b6b600`, which is derived from:

```solidity
keccak256(abi.encode(uint256(keccak256("cube3.storage")) - 1)) & ~bytes32(uint256(0xff));
```

## Access Control and Roles

### Integration Access Control

Privileged access to integration-specific functionality is controlled by the `Cube3Router`. Each integration is assigned an `integrationAdmin`, which is set by the integration contract during deployment. The `integrationAdmin` is the only address that can update the integration's protection logic and access is inforced by the `onlyIntegrationAdmin` modifier. This admin account is modelled after OpenZeppelin's `Ownable2Step` pattern, which requires a nominated account to confirm the change of ownership. All functions exposed externally to integration admins can be located in the abstract `IntegrationManagement.sol` contract.

### Protocol Access Control

Administration and management of the protocol is restricted to the CUBE3 team and makes use of OpenZeppelin's `AccessControl` (and its upgradeable variant). Separation of concerns is achieved through different roles and permissions. All roles are defined in the abstract `ProtocolAdminRoles.sol` contract, which is inherited by both the Router and the Registry contracts. The roles and their permissions are as follows:

`CUBE3_PROTOCOL_ADMIN_ROLE` - Assigned to members of the CUBE3 team with the ability to configure the protocol. The protocol admin role has the ability to update the protocol's configuration, install and deprecate modules, and execute privileged calls on modules via the router. Primarily controls access to functions in `ProtocolManagement.sol`. This role should be assigned to a multi-sig controlled by the CUBE3 team.

`CUBE3_INTEGRATION_MANAGER_ROLE` - Assigned to members of the CUBE3 team who can modify an integration's access to the protocol. Accounts assigned this role have the ability to make integration-level changes, such as modifying integration registration status (access to the protocol). This role can be assigned to a programmatic account that is controlled by the CUBE3 team. For example, a programmatic account that revokes registration in the event a user stops paying for the off-chain CUBE3 services.

`CUBE3_KEY_MANAGER_ROLE` - Accounts responsible for modifying state of the `Cube3Registry`. This role acts on behalf of the CUBE3 KMS and can set/revoke signing authorities for integration contracts. The scope of this role is limited to the `Cube3Registry` contract.

`DEFAULT_ADMIN_ROLE` - Assigned to the protocol deployer account. This role is used to assign the abovementioned roles to other accounts. The deployer revokes this role from itself after the protocol is deployed and additional roles are assigned.

## Entry Points

### User Entry Points

- A user deploys their integration, which sets the admin account on the router via `{IntegrationManagement-initiateIntegrationRegistration}`.
- A user completes registration by calling `IntegrationManagement-registerIntegrationWithCube3}` on the router. This requires that an off-chain registrar signature is issued by CUBE3. Only the `integrationAdmin` set in the previous step can call this function.
- A user can transfer admin privileges to a new account by calling `{IntegrationManagement-transferIntegrationAdmin}` on the Router. The `pendingAdmin` needs to call `{IntegrationManagement-acceptIntegrationAdmin}` for the transfer of privileges to complete.
- A user can call `{IntegrationManagement-updateFunctionProtectionStatus}` to update the protection status to update the protection status of one or more functions protected by the `cube3Protected` modifier inherited from the abstract `ProtectionBase.sol` contract.

### CUBE3 Entry points

- A CUBE3 account possessing the `CUBE3_INTEGRATION_MANAGER_ROLE` role can update the registration status of one or more integrations using `{IntegrationManagement-batchUpdateIntegrationRegistrationStatus}`.
- A CUBE3 account possessing the `CUBE3_INTEGRATION_MANAGER_ROLE` role can update the registration status of a single integration using `{IntegrationManagement-updateIntegrationRegistrationStatus}`.
- A CUBE3 account possessing the `CUBE3_PROTOCOL_ADMIN_ROLE` role can update the protocol's config, ie the registry address and paused state, by calling `{ProtocolManagement-setProtocolConfig}` on the router.
- A CUBE3 account possessing the `CUBE3_PROTOCOL_ADMIN_ROLE` role can call privileged module functions, for who access is restricted to the router, by calling `{ProtocolManagement-callModuleFunctionAsAdmin}` on the router.
- A CUBE3 account possessing the `CUBE3_PROTOCOL_ADMIN_ROLE` role can install new modules by calling `{ProtocolManagement-installModule}` on the router.
- A CUBE3 account possessing the `CUBE3_PROTOCOL_ADMIN_ROLE` role can deprecate modules by calling `{ProtocolManagement-deprecateModule}` on the router.
- A CUBE3 account possessing the `CUBE3_KEY_MANAGER_ROLE` role can set the signing authority for an integration by calling`{Cube3Registry-setClientSigningAuthority}` on the Registry.
- A CUBE3 account possessing the `CUBE3_KEY_MANAGER_ROLE` role can batch set signing authorities for multiple integrations by `{Cube3Registry-batchSetSigningAuthority}` on the Registry.
- A CUBE3 account possessing the `CUBE3_KEY_MANAGER_ROLE` role can revoke the signing authority for an integration by calling`{Cube3Registry-revokeSigningAuthorityForIntegration}` on the Registry.
- A CUBE3 account possessing the `CUBE3_KEY_MANAGER_ROLE` role can batch revoke signing authorities for multiple integrations by `{Cube3Registry-batchRevokeSigningAuthoritiesForIntegrations}` on the Registry.

### Contract entry points

- Integration contracts access the protocol via the `{Cube3Router-routeToModule}` function.
- The protocol validates the signature generated by the integration's signing authority via the `{Cube3SignatureModule-validateSignature}` function. Access to the function is restricted to the Router.

## Function flow diagrams

## Attack Considerations

The protocol is ultimately operated and managed by CUBE3. Account compromise of an account owned by CUBE3 with a privileged role is the primary attack vector for any actor wishing to exploit an integration. The same can be said for the KMS managed by CUBE3 for storing signing authorities. While the operational security of these elements is nonetheless important, it's beyond the scope of this audit.

There are no funds transferred or custodied by the protocol, so the financial incentives to target the protocol are limited.

V1 of the protocol exposed a limited risk of phishing by controlling function protection via the integration contract's own storage. This risk has been mitigated by moving all function protection logic to the Router.

If an integration's admin was to lose access to their account, or were it to be compromised, CUBE3 cannot recover or change this account. Mitigation would be in the form of disconnecting the integration from the protocol. An integration should use separate accounts for management of the integration from a CUBE3 protocol perspective, and any privileged access on the integration contract itself.

Disconnecting the integration from the integration side via the `{_updateShouldUseProtocol}` **must** only be called within an external/public function protected by access control. It is up to the integration's designer to determine whether or not this feature is required and to implement the mechanism accordingly.

Bypassing the protection logic for an integration is possible via compromised `integrationAdmin` account. The integrity of this account is the sole responsibility of account owner. Another route, albeit more complex, by a malicious actor could involve a combination of phishing and an illegitimate integration registration. Because protection status is stored per integration, per function selector, a malicious actor could in theory attain a registrar signature from CUBE3 and register a malicious integration and disable protection on a function matching the selector of a target integration's contract. The exploit would then require phishing an integration's user to call the unprotected function on the malicious contract. This is of course possible without any involvement of the CUBE3 protocol, with the only perceived benefit being that a "successfully" executed transaction's trace would include traces through the CUBE3 protocol. However, if the malicious contract is detected by CUBE3's RASP service, the transaction would be blocked were it to be routed to the `Cube3SignatureModule`. This is a very high effort, low reward attack vector.

Because access to the protocol

## Scoping Details and Considerations

The protocol and [protection-solidity repo](https://github.com/cube-web3/protection-solidity) are both in scope for this audit and can be considered a single codebase. The core protocol contracts and inheritable protection contracts have been separated into separate repositories to improve the developer experience for anyone wishing to utilize CUBE3's services.

The Protection contracts are included as a dependency in this repo and utilized for all integration testing. The dependencies are included as a git submodule, defined in `.gitmodules`, and are locked to a specific branch for the audit. (TODO: update ref here)

The protocol will be deployed on multiple chains, including Ethereum mainnet and various L2s. There is no cross-chain message passing or function execution. All interactions with the protocol on a specific chain are isolated to that chain. Some target EVM chains, such as Avalanche, do not yet support Solidity `>0.8.19` or the `PUSH0` opcode. This was taken into consideration when designing V2 of the protocol.

TODO: update this
The following protocol contracts are in scope for this audit (including SLOC):

```
 132 ./Cube3Registry.sol
 216 ./Cube3Router.sol
  23 ./libs/SignatureUtils.sol
  59 ./libs/PayloadUtils.sol
  52 ./libs/BitmapUtils.sol
  20 ./libs/AddressUtils.sol
  48 ./common/Structs.sol
  52 ./common/ProtocolEvents.sol
  17 ./common/ProtocolAdminRoles.sol
  17 ./common/ProtocolConstants.sol
 164 ./abstracts/RouterStorage.sol
 233 ./abstracts/IntegrationManagement.sol
  98 ./abstracts/ProtocolManagement.sol
 215 ./modules/Cube3SignatureModule.sol
  16 ./modules/ModuleBaseEvents.sol
 123 ./modules/ModuleBase.sol
  92 ./interfaces/ICube3Registry.sol
  45 ./interfaces/ICube3SignatureModule.sol
 175 ./interfaces/ICube3Router.sol
  42 ./interfaces/ICube3Module.sol
1839 total
```

- How many contracts are in scope?
- Total SLoC for these contracts?
- How many separate interfaces and struct definitions are there for the contracts within scope?
- What is the overall line coverage percentage provided by your tests?
- Check all that apply: ERC20, Multi-Chain, Uses L2
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?
- Is this either a fork of or an alternate implementation of another project?
- Does it use a side-chain?

TODO:

## Test Coverage

## Acknowledgements

- This is not a fully decentralized protocol, as the current iteration relies on CUBE3's off-chain services.
- "Disconnecting" from the protocol comes at the expense of an `SLOAD` per transaction, which is a gas cost that is not currently covered by the protocol. This is a trade-off that was made to improve the developer experience and reduce the complexity of the protocol. The protocol is designed to be as simple as possible, while still providing the necessary security features for smart contracts. Disabling access to the protocol post-deployment requires that the integration contract implements some form of access control.
- The protocol is designed in such a way that new functionality can be introduced without requiring a protocol upgrade. This is achieved by using a `payload` to route transactions to the appropriate contract modules. The only module included in the scope of this audit is the `Cube3SignatureModule`.
- CUBE3 does not have the ability to modify protection status of individual functions for an integration. If an integration's owner were to lose control of the `integrationAdmin` account, there is no way for the protocol to modify this account. This is to increase decentralization. In the event of account compromise or loss of access to an `integrationAdmin` account, CUBE3 has the ability to revoke an integration's registration, which will force the integration to bypass the protocol's functionality and return early, effectively disabling the protocol for the integration and allowing the function call to proceed as normal. Noting that this comes at the expense of additional `SLOAD` operations per transaction, compared to the integration disabling access to the protocol themselves.
- TODO: we dont check the payload length as it will cause a revert and an integration can disconnect on their side, or protection is off and saves gas from memory expansion
- TODO: No error is thrown when a function is not protected, an integration admin could use the wrong selector, it's up to the integration to check that the protocol is being used.
- TODO: revoking the registry will cause registrations to fail, but txs can continue if signed by the backup, if choosing not to pause.

- TODO: cucrrently, revoking the registry will prevent new users from joining, but will not prevent existing users from using the protocol. the signature module will use a backup signer (which hsould be stored separate from teh registry/kms), so TXs can still be signed. However, the registration of new contracts will be paused (should be paused on the front-end anyway).
