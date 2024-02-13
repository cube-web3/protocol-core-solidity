# ICube3Registry
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/ICube3Registry.sol)

This contract serves as a registry for storing and managing the signing authorities
assigned to specific Cube3 customer integrations.
Notes:
- A "signing authority" is the EOA address belonging to the private key from the keypair that
generates the signature of the secure payload supplied by the Risk API.
- Events are defined in {ProtocolEvents}


## Functions
### setClientSigningAuthority

Sets or updates the signing authority address for an integration contract.

*Emits a {SigningAuthorityUpdated} event.
Notes:
- External wrapper for the {Cube3Registry-_setClientSigningAuthority}
-
Requirements:
- `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
- `integrationContract` cannot be the zero address.
- `clientSigningAuthority` cannot be the zero address.*


```solidity
function setClientSigningAuthority(address integrationContract, address clientSigningAuthority) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrationContract`|`address`|The contract address of the integration.|
|`clientSigningAuthority`|`address`|The public address generated for the integration's private-public key-pair managed by the CUBE3 KMS.|


### batchSetSigningAuthority

Sets signing authorities for multiple integration contracts

*Emits an {SigningAuthorityUpdated} for integration.
Notes:
- Can lead to out-of-gas errors due to no array  length check; use discretion when calling.
-
Requirements:
- `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
- `integrations` and `signingAuthorities` arrays must be of equal length.
- No address in the `integrations` array can be the zero address.
- No address in the `signingAuthorities` array can be the zero address.*


```solidity
function batchSetSigningAuthority(address[] calldata integrations, address[] calldata signingAuthorities) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrations`|`address[]`|The addresses of the integration contracts.|
|`signingAuthorities`|`address[]`|The addresses of the signing authorities, indexed to match the `integrations` array.|


### revokeSigningAuthorityForIntegration

Revokes a signing authority for a specified integration contract.

*Emits a {SigningAuthorityRevoked} event.
Notes:
- This operation is irreversible through this function call.
- Removes the signing authority from the `integrationToSigningAuthority` map.
Requirements:
- `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
- The signing authority for the `integration` must have been set previously.*


```solidity
function revokeSigningAuthorityForIntegration(address integration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration contract's address to have its signing authority revoked.|


### batchRevokeSigningAuthoritiesForIntegrations

Revokes multiple signing authorities for the integration contracts provided.

*Emits a {SigningAuthorityRevoked} event for each revocation.
Notes:
- This operation is irreversible through this function call.
- Removes each signing authority from the `integrationToSigningAuthority` map.
- No checks on gas limits, use with caution.
Requirements:
- `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
- The signing authority for each integration must have been set previously.*


```solidity
function batchRevokeSigningAuthoritiesForIntegrations(address[] calldata integrationsToRevoke) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrationsToRevoke`|`address[]`|Array containing the integration contracts to revoke signing authorities for.|


### getSigningAuthorityForIntegration

Retrieves the signing authority's address for the provided `integration`.
Notes:
- Each integration contract has a unique signature authority managed by Cube3's KMS.
- Will return address(0) for a non-existent authority, so it's up to the caller
to handle such a case accordingly.


```solidity
function getSigningAuthorityForIntegration(address integration) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The ingtegration contract's address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The signing authority (account address) of the authority's private-public keypair.|


