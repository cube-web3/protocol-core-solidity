// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AddressUtils} from "../../src/libs/AddressUtils.sol";

contract MockCaller {
 constructor(address target) {
   (bool success, ) = target.call(abi.encodeWithSignature("checkCallerIsContract()"));
   require(success, "MockCaller: failed to call target");
 }
}

contract MockTarget {
   using AddressUtils for address;

    function checkCallerIsContract() public {
      (msg.sender).assertIsContract();
    }
}