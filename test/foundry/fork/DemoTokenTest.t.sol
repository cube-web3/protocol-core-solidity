// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";

import {DemoTokenImpl} from "../../../script/foundry/demo/DemoTokenImpl.sol";
import {PayloadCreationUtils} from "../../libs/PayloadCreationUtils.sol";
import {Structs} from "../../../src/common/Structs.sol";
import {Cube3SignatureModule} from "../../../src/modules/Cube3SignatureModule.sol";

contract DemotTokenForkTest is Test {
    uint256 internal constant EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH = 320;

    string sepoliaRpc;

    address demoUser = 0x57912CC40188Ddd1124646B74D8722f939918375;
    address integration = 0x7347678e3Af5eb8975FD790AB25065FFa785aBC0;
    address integrationAdmin = 0x57912CC40188Ddd1124646B74D8722f939918375;
    address signingAuthority = 0xf4D6aF64C964703b77656C26dd2B0B0F5CeAf2c3;
    address signatureModule = 0x4f0aF0eba773Bc0698A70985642c740cB460Ab9b;
    uint256 signerPvtKey = 0xe720558f6f84efef3dc6ebd9ef968aba9e70e4ae130c524af6a983e906236bba;

    address recipient = 0xA0319F59B84D3581b22F85f47daEf3882567F830;
    uint256 amount = 1 ether;

    uint256 expirationTimestamp = 1715544564;

    uint256 forkId;

    DemoTokenImpl token;

    event log_call_components(Structs.TopLevelCallComponents components);

    function setUp() public {
        sepoliaRpc = vm.envString("SEPOLIA_RPC");

        forkId = vm.createFork("http://127.0.0.1:8545");

        token = DemoTokenImpl(integration);
    }

    function test_Signature() public {
        vm.selectFork(forkId);

        vm.startPrank(demoUser);

        // step 0: recreate the call data
        bytes memory emptyBytes = new bytes(352); //352
        bytes memory mintCalldataWithEmptyPayload = abi.encodeWithSelector(
            token.mint.selector,
            recipient,
            amount,
            emptyBytes
        );
        emit log_named_bytes("mintCalldataWithEmptyPayload", mintCalldataWithEmptyPayload);

        Structs.TopLevelCallComponents memory callComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            demoUser,
            integration,
            0, // value
            mintCalldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        emit log_call_components(callComponents);

        uint256 expiration = block.timestamp + 7 days;
        emit log_named_uint("expiration", expiration);
        // equal up to here:

        bytes memory payload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            integration,
            demoUser,
            signerPvtKey,
            7 days, // expiration window
            true, // track nonce
            Cube3SignatureModule(signatureModule),
            callComponents
        );

        emit log_named_bytes("payload", payload);

        token.mint(recipient, amount, payload);
        vm.stopPrank();
    }
}
