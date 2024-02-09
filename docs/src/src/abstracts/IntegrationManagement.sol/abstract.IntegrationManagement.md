# IntegrationManagement
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/abstracts/IntegrationManagement.sol)

**Inherits:**
AccessControlUpgradeable, [RouterStorage](/src/abstracts/RouterStorage.sol/abstract.RouterStorage.md)

*This contract contains all the logic for managing customer integrations*


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

*Begins the 2 step transfer the admin account for an integration contract.*

*Can only be called by the integration's existing admin.*


```solidity
function transferIntegrationAdmin(address integration, address newAdmin) external onlyIntegrationAdmin(integration);
```

### acceptIntegrationAdmin

*Facilitates tranfer of admin rights for an integration contract.*

*Called by the account accepting the admin rights.*


```solidity
function acceptIntegrationAdmin(address integration) external onlyPendingIntegrationAdmin(integration);
```

### updateFunctionProtectionStatus

*Protection can only be enabled for a function if the status is REGISTERED.*

*Can only be called by the integration's admin.*

*Only an integration that has pre-registered will have an assigned admin, so there's no
need to check if the status is UNREGISTERED.*

*An integration that's had its registration status revoked can only disable protection.*


```solidity
function updateFunctionProtectionStatus(
    address integration,
    Structs.FunctionProtectionStatusUpdate[] calldata updates
)
    external
    onlyIntegrationAdmin(integration);
```

### initiateIntegrationRegistration

*Called by integration contract during construction, thus the integration contract is `msg.sender`.*

*We cannot restrict who calls this function, including EOAs, however an integration has no
access to the protocol until `registerIntegrationWithCube3` is called by the integration admin, for
which a registrarSignature is required and must be signed by the integration's signing authority via CUBE3.*

*Only a contract who initiated registration can complete registration via codesize check.*


```solidity
function initiateIntegrationRegistration(address admin_) external returns (bool);
```

### registerIntegrationWithCube3

*Can only be called by the integration admin set in `initiateIntegrationRegistration`.*

*Passing an empty array of selectors to enable none by default.*

*Only a contract who initiated registration can complete registration via codesize check.*


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

*Can be used to revoke an integration's registration status, preventing it from enabling function protection
and blocking access to the protocol by skipping protection checks.*


```solidity
function updateIntegrationRegistrationStatus(
    address integration,
    Structs.RegistrationStatusEnum registrationStatus
)
    external
    onlyRole(CUBE3_INTEGRATION_MANAGER_ROLE);
```

### fetchRegistryAndSigningAuthorityForIntegration

*Utility function for returning the integration's signing authority, which is used to validate
the registrar signature. If the registry is not set, the function will return the zero address as the signing
authority. It is up to the module to handle this case.*


```solidity
function fetchRegistryAndSigningAuthorityForIntegration(address integration)
    public
    view
    returns (address registry, address authority);
```

### _updateIntegrationRegistrationStatus

*Updates the integration status for an integration or an integration's proxy.*

*Only accessible by the Cube3Router contract, allowing changes from, and to, any state*

*Prevents the status from being set to the same value.*


```solidity
function _updateIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) internal;
```

