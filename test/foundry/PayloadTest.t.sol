// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";

import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";
import {Structs} from "@src/common/Structs.sol";
import {DemoTokenImpl} from "../../script/foundry/demo/DemoTokenImpl.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";
contract MockModule {
    bytes16 public constant moduleId = bytes16(keccak256("module"));

    function integrationUserNonce(address a, address b) public view returns (uint256) {
        return 1;
    }
}

contract PayloadTest is Test {
    uint256 internal constant EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH = 320;

    event log_components(Structs.TopLevelCallComponents components);

    MockModule mockmodule;
    function setUp() public {
        mockmodule = new MockModule();
    }

    function test_Payload() public {
        address integration = 0x5324A4292c3A8E06432b090a18F47B64e9f61161;
        address caller = 0xbD834d3756376b80FD4B1c5ff19916c17c4569f0;
        uint256 pvtKey = 0x19cd9682639d3c38ec6d80eae459bbffb37d5dff09b40f091fb398911746ca9f;
        uint256 window = block.timestamp + 7 days;
        bool trackNonce = true;
        // address signatureModule = 0x3A3D7bB8A514790EA20A757317092d5123F8bdaF;
        address recipient = 0xf202dc11eCaB698eA4d3Ee989f32E7637013Dcc2;
        uint256 amount = 1 ether;

        emit log_named_address("sig mod", address(mockmodule));

        emit log_named_uint("window", window);

        bytes4 selector = DemoTokenImpl.mint.selector;
        emit log_named_bytes32("selector", bytes32(selector));
        bytes memory mockCalldata = abi.encodeWithSelector(
            DemoTokenImpl.mint.selector,
            recipient,
            amount,
            new bytes(352)
        );

        emit log_named_bytes("mintCalldata", mockCalldata);

        // bytes memory slicedCalldata = PayloadCreationUtils.sliceBytes(
        //     mockCalldata,
        //     0,
        //     mockCalldata.length - EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH - 64
        // );

        Structs.TopLevelCallComponents memory callComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            caller,
            integration,
            0,
            mockCalldata,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        emit log_components(callComponents);

        bytes memory payload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            integration,
            caller,
            pvtKey,
            window,
            trackNonce,
            Cube3SignatureModule(address(mockmodule)),
            callComponents
        );

        emit log_named_bytes("payload", payload);
    }
}
