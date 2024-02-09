# Cube3Registry
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/Cube3Registry.sol)

**Inherits:**
AccessControl, [ICube3Registry](/src/interfaces/ICube3Registry.sol/interface.ICube3Registry.md), [ProtocolAdminRoles](/src/common/ProtocolAdminRoles.sol/abstract.ProtocolAdminRoles.md)

*See {ICube3Registry}*

*In the event of a catestrophic breach of the KMS, the registry contract will be detached from the module*


## State Variables
### integrationToSigningAuthority

```solidity
mapping(address integration => address signingAuthority) internal integrationToSigningAuthority;
```


## Functions
### constructor


```solidity
constructor();
```

### setClientSigningAuthority


```solidity
function setClientSigningAuthority(
    address integrationContract,
    address clientSigningAuthority
)
    external
    onlyRole(CUBE3_KEY_MANAGER_ROLE);
```

### batchSetSigningAuthority


```solidity
function batchSetSigningAuthority(
    address[] calldata integrations,
    address[] calldata signingAuthorities
)
    external
    onlyRole(CUBE3_KEY_MANAGER_ROLE);
```

### revokeSigningAuthorityForIntegration


```solidity
function revokeSigningAuthorityForIntegration(address integration) external onlyRole(CUBE3_KEY_MANAGER_ROLE);
```

### batchRevokeSigningAuthoritiesForIntegrations


```solidity
function batchRevokeSigningAuthoritiesForIntegrations(address[] calldata integrationsToRevoke)
    external
    onlyRole(CUBE3_KEY_MANAGER_ROLE);
```

### supportsInterface

*override for AccessControlUpgradeable*


```solidity
function supportsInterface(bytes4 interfaceId) public view override returns (bool);
```

### _setClientSigningAuthority

*reusable utility function that sets the authority, checks addresses, and emits the event*


```solidity
function _setClientSigningAuthority(address integration, address authority) internal;
```

### _revokeSigningAuthorityForIntegration

*encapsulates revocation code to be reusable*


```solidity
function _revokeSigningAuthorityForIntegration(address _integration) internal;
```

### getSignatureAuthorityForIntegration


```solidity
function getSignatureAuthorityForIntegration(address integration) external view returns (address);
```

### getSignatureAuthority


```solidity
function getSignatureAuthority(address integration) external view returns (address);
```

