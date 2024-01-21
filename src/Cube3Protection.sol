// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*//////////////////////////////////////////////////////////////
            ROUTER INTERFACE
//////////////////////////////////////////////////////////////*/

interface IRouter {
    function initiateIntegrationRegistration(address admin) external returns (bool);
    function routeToModule(
        address integrationMsgSender,
        uint256 integrationMsgValue,
        bytes calldata integrationCalldata
    ) external returns (bytes32);
}

/*//////////////////////////////////////////////////////////////
            BASE CONTRACT
//////////////////////////////////////////////////////////////*/

abstract contract Cube3ProtectionBase {
    bytes32 private constant PROCEED_WITH_CALL = keccak256("PROCEED_WITH_CALL");

    /// @dev `_payload` isn't used, but is kept a an argument to force the modifier to accept the argument to
    /// remind the implementer to add the payload as the last argument in the function signature.
    function _assertShouldProceedWithCall(address _router, bytes calldata _payload) internal {
        (_payload); // prevent compiler warnins.

        // TODO: replace with assembly
        // forwards the called function's calldata, including the secure payload, to the router to be assessed
        bytes memory routerCalldata =
            abi.encodeWithSelector(IRouter.routeToModule.selector, msg.sender, _getMsgValue(), msg.data);
        (bool success, bytes memory returnOrRevertData) = _router.call(routerCalldata);

        // TODO: handle this revert/success data
        //   if (success || returnOrRevertData.length != 4) {
        if (success && returnOrRevertData.length == 32) {
            bytes32 response = abi.decode(returnOrRevertData, (bytes32));
            if (response != PROCEED_WITH_CALL) {
                revert("TODO not safe");
            }
        } else {
            revert("TODO Failed");
        }
    }

    /// @dev Helper function as a non-payable function cannot read msg.value in the modifier.
    /// @dev Will not clash with `_msgValue` in the event that the derived contract inherits {Context}.
    function _getMsgValue() private view returns (uint256) {
        return msg.value;
    }
}

/*//////////////////////////////////////////////////////////////
            IMMUTABLE VERSION
//////////////////////////////////////////////////////////////*/

/// @dev the immutable version cannot be upgraded, and the connection to the protocol cannot
/// be severed. This saves the SLOAD of retrieving the router address from storage.
/// Connection to the protocol is done on the router side, which means a call will always be made
/// to the router, and the status checked on the router-side. This requires a higher level of trust that the
/// router will not be upgraded to a non-operational version.

abstract contract Cube3ProtectionImmutable is Cube3ProtectionBase {
    address private immutable cube3Router;

    modifier cube3Protected(bytes calldata cube3Payload) {
        _assertShouldProceedWithCall(cube3Router, cube3Payload);
        _;
    }

    /// @dev The `integrationAdmin` can be considered the owner of the this contract, from the CUBE3 protocol's perspective,
    ///       and is the account that will be permissioned to complete the registration with the protocol and enable/disable
    ///       protection for the functions decorated with the {cube3Protected} modifier.
    constructor(address _router, address _integrationAdmin) {
        require(_router != address(0), "Invalid: Router ZeroAddress");
        require(_integrationAdmin != address(0), "Invalid: Admin ZeroAddress");
        cube3Router = _router;

        // TODO: will this succeed if the router address is wrong?
        //   bytes memory preRegisterCalldata = abi.encodeWithSignature("initiateIntegrationRegistration(admin)", integrationAdmin);
        //   (bool success, ) = cube3Router.call(preRegisterCalldata);
        bool preRegistrationSucceeded = IRouter(cube3Router).initiateIntegrationRegistration(_integrationAdmin);
        require(preRegistrationSucceeded, "pre-registration failed");
    }
}

/*//////////////////////////////////////////////////////////////
            MUTABLE VERSION
//////////////////////////////////////////////////////////////*/

/// @dev The mutable version allows the connection to the protocol to be severed by setting the router address to the zero address.
///      This comes at the expense of an SLOAD to retrieve the router address from storage, but makes the integration fully trustless.
abstract contract Cube3ProtectionMutable is Cube3ProtectionBase {
    address private cube3Router;

    event RouterUpdated(address indexed newRouter);

    /// @dev The `integrationAdmin` can be considered the owner of the this contract, from the CUBE3 protocol's perspective,
    ///       and is the account that will be permissioned to complete the registration with the protocol and enable/disable
    ///       protection for the functions decorated with the {cube3Protected} modifier.
    constructor(address _router, address integrationAdmin) {
        cube3Router = _router;

        // TODO: will this succeed if the router address is wrong?
        //   bytes memory preRegisterCalldata = abi.encodeWithSignature("initiateIntegrationRegistration(admin)", integrationAdmin);
        //   (bool success, ) = cube3Router.call(preRegisterCalldata);
        bool preRegistrationSucceeded = IRouter(cube3Router).initiateIntegrationRegistration(integrationAdmin);
        require(preRegistrationSucceeded, "pre-registration failed");
    }

    /// @dev Setting the cube3Router to the zero address will disconnect this contract from the CUBE3 protocol
    ///      and skip all calls to the router.
    modifier cube3Protected(bytes calldata cube3Payload) {
        if (cube3Router != address(0)) {
            _assertShouldProceedWithCall(cube3Router, cube3Payload);
        }
        _;
    }

    /// @dev Setting this to the zero address will disable the protection functionality by
    /// severing the connection to the protocol.
    /// @dev MUST only be called within an external fn protected by access control.
    function _updateCube3Router(address newRouter) internal {
        cube3Router = newRouter;
        emit RouterUpdated(newRouter);
    }
}

/*//////////////////////////////////////////////////////////////
            UPGRADEABLE VERSION
//////////////////////////////////////////////////////////////*/

/// @dev The upgradeable version follows ERC-7201 to prevent storage collisions in the event of an upgrade.
/// @dev The initialize functions should be caleld in the derived contract's initializer.

abstract contract Cube3ProtectionUpgradeable is Cube3ProtectionBase {
    // keccak256(abi.encode(uint256(keccak256("cube3.protected.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant CUBE3_PROTECTED_STORAGE_LOCATION =
        0xa8b0d2f2aabfdf699f882125beda6a65d773fc80142b8218dc795eaaa2eeea00;

    /// @custom:storage-location erc7201:cube3.protected.storage
    struct ProtectedStorage {
        address router;
    }

    modifier cube3Protected(bytes calldata cube3Payload) {
        _assertShouldProceedWithCall(_protectedStorage().router, cube3Payload);
        _;
    }

    /// @dev The `integrationAdmin` can be considered the owner of the this contract, from the CUBE3 protocol's perspective,
    ///      and is the account that will be permissioned to complete the registration with the protocol and enable/disable
    ///      protection for the functions decorated with the {cube3Protected} modifier.
    /// @dev MUST be called in the derived contract's initializer.
    function __Cube3ProtectionUpgradeable_init(address _router, address _integrationAdmin) internal {
        __Cube3ProtectionUpgradeable_init_unchained(_router, _integrationAdmin);
    }

    function __Cube3ProtectionUpgradeable_init_unchained(address _router, address _integrationAdmin) private {
        require(_integrationAdmin != address(0), "TODO: invalid admin");
        require(_router != address(0), "TODO: invalid router");
        ProtectedStorage storage protectedStorage = _protectedStorage();
        protectedStorage.router = _router;

        // TODO: will this succeed if the router address is wrong? TEST
        //   bytes memory preRegisterCalldata = abi.encodeWithSignature("initiateIntegrationRegistration(admin)", integrationAdmin);
        //   (bool success, ) = cube3Router.call(preRegisterCalldata);
        bool preRegistrationSucceeded = IRouter(_router).initiateIntegrationRegistration(_integrationAdmin);
        require(preRegistrationSucceeded, "pre-registration failed");
    }

    function _protectedStorage() internal pure returns (ProtectedStorage storage cubeStorage) {
        assembly {
            cubeStorage.slot := CUBE3_PROTECTED_STORAGE_LOCATION
        }
    }
}
