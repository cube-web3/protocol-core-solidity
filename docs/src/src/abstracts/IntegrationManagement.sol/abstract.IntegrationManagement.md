# IntegrationManagement

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/abstracts/IntegrationManagement.sol)

**Inherits:**
AccessControlUpgradeable, [RouterStorage](/src/abstracts/RouterStorage.sol/abstract.RouterStorage.md)

_This contract contains all the logic for managing customer integrations_

## Functions

### onlyIntegrationAdmin

```solidity
modifier onlyIntegrationAdmin(address integration);
```

### onlyPendingIntegrationAdmin

```solidity
modifier onlyPendingIntegrationAdmin(address integration);
```

### transferIntegrationAdmin

_Begins the 2 step transfer the admin account for an integration contract._

_Can only be called by the integration's existing admin._

```solidity
function transferIntegrationAdmin(address integration, address newAdmin) external onlyIntegrationAdmin(integration);
```

### acceptIntegrationAdmin

_Facilitates tranfer of admin rights for an integration contract._

_Called by the account accepting the admin rights._

```solidity
function acceptIntegrationAdmin(address integration) external onlyPendingIntegrationAdmin(integration);
```

### updateFunctionProtectionStatus

_Protection can only be enabled for a function if the status is REGISTERED._

_Can only be called by the integration's admin._

_Only an integration that has pre-registered will have an assigned admin, so there's no
need to check if the status is UNREGISTERED._

_An integration that's had its registration status revoked can only disable protection._

```solidity
function updateFunctionProtectionStatus(
    address integration,
    Structs.FunctionProtectionStatusUpdate[] calldata updates
)
    external
    onlyIntegrationAdmin(integration);
```

### initiateIntegrationRegistration

_Called by integration contract during construction, thus the integration contract is `msg.sender`._

_We cannot restrict who calls this function, including EOAs, however an integration has no
access to the protocol until `registerIntegrationWithCube3` is called by the integration admin, for
which a registrarSignature is required and must be signed by the integration's signing authority via CUBE3._

_Only a contract who initiated registration can complete registration via codesize check._

```solidity
function initiateIntegrationRegistration(address admin_) external returns (bool);
```

### registerIntegrationWithCube3

_Can only be called by the integration admin set in `initiateIntegrationRegistration`._

_Passing an empty array of selectors to enable none by default._

_Only a contract who initiated registration can complete registration via codesize check._

```solidity
function registerIntegrationWithCube3(
    address integration,
    bytes calldata registrarSignature,
    bytes4[] calldata enabledByDefaultFnSelectors
)
    external
    onlyIntegrationAdmin(integration);
```

### batchUpdateIntegrationRegistrationStatus

```solidity
function batchUpdateIntegrationRegistrationStatus(
    address[] calldata integrations,
    Structs.RegistrationStatusEnum[] calldata statuses
)
    external
    onlyRole(CUBE3_INTEGRATION_MANAGER_ROLE);
```

### updateIntegrationRegistrationStatus

_Can be used to revoke an integration's registration status, preventing it from enabling function protection
and blocking access to the protocol by skipping protection checks._

```solidity
function updateIntegrationRegistrationStatus(
    address integration,
    Structs.RegistrationStatusEnum registrationStatus
)
    external
    onlyRole(CUBE3_INTEGRATION_MANAGER_ROLE);
```

### fetchRegistryAndSigningAuthorityForIntegration

_Utility function for returning the integration's signing authority, which is used to validate
the registrar signature. If the registry is not set, the function will return the zero address as the signing
authority. It is up to the module to handle this case._

```solidity
function fetchRegistryAndSigningAuthorityForIntegration(address integration)
    public
    view
    returns (address registry, address authority);
```

### \_updateIntegrationRegistrationStatus

_Updates the integration status for an integration or an integration's proxy._

_Only accessible by the Cube3RouterImpl contract, allowing changes from, and to, any state_

_Prevents the status from being set to the same value._

```solidity
function _updateIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) internal;
```
