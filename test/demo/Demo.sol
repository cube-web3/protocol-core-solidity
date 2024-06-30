// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Cube3Protection} from "@cube3/Cube3Protection.sol";

contract Demo is Cube3Protection {
    event BalanceUpdated(address indexed account, uint256 newBalance);
    event Success();

    mapping(address => uint256) public balances;

    constructor(address _router) Cube3Protection(_router, msg.sender, true) {}

    function mint(uint256 qty, bytes calldata payload) external cube3Protected(payload) returns (uint256) {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = balance + qty;
        emit BalanceUpdated(msg.sender, balance);
        return balance;
    }

    function mintAssertion(uint256 qty, bytes calldata payload) external returns (uint256) {
        _assertProtectWhenConnected(payload);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = balance + qty;
        emit BalanceUpdated(msg.sender, balance);
        return balance;
    }

    function protected(
        uint256 newVal,
        bool newState,
        bytes32 newBytes,
        bytes calldata cubePayload
    ) public cube3Protected(cubePayload) {
        (newVal, newState, newBytes);
        emit Success();
    }

    function protectedAssertion(uint256 newVal, bool newState, bytes32 newBytes, bytes calldata cubePayload) public {
        _assertProtectWhenConnected(cubePayload);
        (newVal, newState, newBytes);
        emit Success();
    }

    function dynamic(
        uint256[] calldata vals,
        bool flag,
        string memory str,
        bytes calldata cubePayload
    ) external cube3Protected(cubePayload) {
        (vals, flag, str);
        emit Success();
    }

    function dynamicAssertion(
        uint256[] calldata vals,
        bool flag,
        string memory str,
        bytes calldata cubePayload
    ) external {
        _assertProtectWhenConnected(cubePayload);
        (vals, flag, str);
        emit Success();
    }

    function bytesProtected(
        bytes calldata firstBytes,
        uint256 newVal,
        bytes calldata secondBytes,
        uint256[] calldata uint256s,
        string memory str,
        bool flag,
        bytes calldata cubePayload
    ) external cube3Protected(cubePayload) {
        (firstBytes, newVal, secondBytes, uint256s, str, flag);
        emit Success();
    }

    function bytesProtectedAssertion(
        bytes calldata firstBytes,
        uint256 newVal,
        bytes calldata secondBytes,
        uint256[] calldata uint256s,
        string memory str,
        bool flag,
        bytes calldata cubePayload
    ) external {
        _assertProtectWhenConnected(cubePayload);
        (firstBytes, newVal, secondBytes, uint256s, str, flag);
        emit Success();
    }

    function noArgs(bytes calldata cubePayload) public cube3Protected(cubePayload) {
        emit Success();
    }

    function noArgsAssertion(bytes calldata cubePayload) public {
        _assertProtectWhenConnected(cubePayload);
        emit Success();
    }

    function payableProtected(
        uint256 newVal,
        bool newState,
        bytes32 newBytes,
        bytes calldata cubePayload
    ) external payable cube3Protected(cubePayload) {
        require(msg.value > 0, "value = 0");
        (newVal, newState, newBytes);
        emit Success();
        emit BalanceUpdated(address(this), address(this).balance);
    }

    function payableProtectedAssertion(
        uint256 newVal,
        bool newState,
        bytes32 newBytes,
        bytes calldata cubePayload
    ) external payable {
        _assertProtectWhenConnected(cubePayload);
        require(msg.value > 0, "value = 0");
        (newVal, newState, newBytes);
        emit Success();
        emit BalanceUpdated(address(this), address(this).balance);
    }

    function deposit(bytes calldata cubePayload) external cube3Protected(cubePayload) {
        emit Success();
    }

    receive() external payable {}
}

contract DemoAssertProtect is Cube3Protection {
    event ProtectionChecked(bool connected, uint256 payloadLength);

    constructor(address _router) Cube3Protection(_router, msg.sender, true) {}

    function exposedAssertProtectWhenConnected(bytes calldata payload) external {
        _assertProtectWhenConnected(payload);
        emit ProtectionChecked(connectedToCUBE3(), payload.length);
    }

    /// @dev in a production contract, this function MUST be access controlled
    function updateConnection(bool shouldConnect) external {
        _updateShouldUseProtocol(shouldConnect);
    }
}
