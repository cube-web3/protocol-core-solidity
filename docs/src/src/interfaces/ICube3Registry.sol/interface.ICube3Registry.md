# ICube3Registry

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/interfaces/ICube3Registry.sol)

**Author:**
CUBE3.ai

This contract serves as a registry for storing and managing the signing authorities
assigned to specific Cube3 customer integrations.

_A "signing authority" is the EOA address belonging to the private key from the keypair that
generates the signature of the secure payload supplied by the Risk API. See {Cube3Integration}._

_All Signing Authority Keypairs are managed by the CUBE3 KMS on behalf of integrations._

_All active signing authorities are tied to the current value of {\_invalidationNonce}._

_Incrememnting {\_invalidationNonce} will invalidate all registered signing authories - given that
the contract has 2^256 storage slots, we simply discard the reference to the existing
items in storage (by incrementing the nonce) instead of zeroing-out each slot._

_Invalidating the active nonce requires an admin to supply a temporary signer override address, and
sets the contract into recovery mode, which means the "global" temporary signing authority is returned
as the signing authority for all integrations until recovery mode is deactivated._

_Contract is upgradeable via the Universal Upgradeable Proxy Standard (UUPS)._

_Includes a `__storageGap` to prevent storage collisions following upgrades._

## Functions

### setClientSigningAuthority

Sets, or updates, the signing authority address for an integration contract.

_Can only be called by a key manager._

_Each integration has a unique signing authority stored in the `integrationToSigningAuthority` map._

_The signing authority is intrinsicly linked to the current `_invalidationNonce`, if the nonce
is incremented, the signing authority is no longer valid._

```solidity
function setClientSigningAuthority(address integrationContract, address clientSigningAuthority) external;
```

**Parameters**

| Name                     | Type      | Description                                                                 |
| ------------------------ | --------- | --------------------------------------------------------------------------- |
| `integrationContract`    | `address` | The contract address of the integration.                                    |
| `clientSigningAuthority` | `address` | The public address generated for the integration's private-public key-pair. |

### batchSetSigningAuthority

Sets multiple integration contracts and their corresponding signing authorities for the active
`_invalidationNonce`.

_No array-length check, therefore subject to out-of-gas error, up to the key manager to use their
discretion when calling._

```solidity
function batchSetSigningAuthority(address[] calldata integrations, address[] calldata signingAuthorities) external;
```

**Parameters**

| Name                 | Type        | Description                                                                                                                                       |
| -------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `integrations`       | `address[]` | The addresses of the integration contracts.                                                                                                       |
| `signingAuthorities` | `address[]` | The addresses of the signingAuthorities, where each index corresponds to the ingtegration contract in the `integrations` array at the same index. |

### revokeSigningAuthorityForIntegration

Revokes a signing authority for the provided contract address.

_Can only be called by a key manager._

_Removes the signing authority from the `integrationToSigningAuthority` map._

```solidity
function revokeSigningAuthorityForIntegration(address integration) external;
```

**Parameters**

| Name          | Type      | Description                         |
| ------------- | --------- | ----------------------------------- |
| `integration` | `address` | The integration contract's address. |

### batchRevokeSigningAuthoritiesForIntegrations

Revokes multiple signing authorities in the same transaction.

_If used in an emergency, gas price should be set high to front-run mempool TXs that
contain soon-to-be-revoked signing authorities._

_Is subject to experiencing out-of-gas error if the `integrationsRevoked` array is too long._

```solidity
function batchRevokeSigningAuthoritiesForIntegrations(address[] calldata integrationsToRevoke) external;
```

**Parameters**

| Name                   | Type        | Description                                  |
| ---------------------- | ----------- | -------------------------------------------- |
| `integrationsToRevoke` | `address[]` | The list of integration addresses to revoke. |

### getSigningAuthorityForIntegration

Retrieves the signing authority's address for the supplied integration.

_Each integration contract has a unique signature authority managed by Cube3's KMS._

_Function will return address(0) for a non-existent authority, so it's up to the caller
to handle it accordingly._

_If the registry is in recovery mode, ie a nonce set has been invalidated, the temporary
signing authority override is returned._

_The calling contract relies on the returned address to validate whether the integration has
been registered. When `isRecoveryMode` is true, this check is invalid as the temporary
override signer is returned by default._

```solidity
function getSigningAuthorityForIntegration(address integration) external view returns (address);
```

**Parameters**

| Name          | Type      | Description                          |
| ------------- | --------- | ------------------------------------ |
| `integration` | `address` | The ingtegration contract's address. |

**Returns**

| Name     | Type      | Description                                                                        |
| -------- | --------- | ---------------------------------------------------------------------------------- |
| `<none>` | `address` | The signing authority (account address) of the authority's private-public keypair. |

## Events

### SigningAuthorityUpdated

Emitted when a new signing authority is set.

```solidity
event SigningAuthorityUpdated(address indexed integration, address indexed signer);
```

**Parameters**

| Name          | Type      | Description                              |
| ------------- | --------- | ---------------------------------------- |
| `integration` | `address` | The integration contract's address.      |
| `signer`      | `address` | The signing authority's account address. |

### SigningAuthorityRevoked

Emitted when a signing authority is revoked.

```solidity
event SigningAuthorityRevoked(address indexed integration, address indexed revokedSigner);
```

**Parameters**

| Name            | Type      | Description                              |
| --------------- | --------- | ---------------------------------------- |
| `integration`   | `address` | The integration contract's address.      |
| `revokedSigner` | `address` | The signing authority's account address. |

### TemporaryRecoverySigningAuthorityAssigned

Emitted when the `_invalidationNonce` is incremented and a temporary recovery signing authority is set

```solidity
event TemporaryRecoverySigningAuthorityAssigned(address indexed tempSignerOverride, uint256 newInvalidationNonce);
```

**Parameters**

| Name                   | Type      | Description                                                                        |
| ---------------------- | --------- | ---------------------------------------------------------------------------------- |
| `tempSignerOverride`   | `address` | The override account that will serve as the signing authority for all integrations |
| `newInvalidationNonce` | `uint256` | The invalidation nonce whose set the temporary signing authority belongs to        |
