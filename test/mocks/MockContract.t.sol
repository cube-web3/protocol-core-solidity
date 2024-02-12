// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import {AddressUtils} from "@src/libs/AddressUtils.sol";

contract MockCaller {
 constructor(address target) {
   (bool success, bytes memory returnOrRevertData ) = target.call(abi.encodeWithSignature("checkCallerIsContract()"));
           if (!success) {
            // Bubble up the revert data from the module call.
            assembly {
                revert(
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    add(returnOrRevertData, 0x20),
                    // Length of revert data.
                    mload(returnOrRevertData)
                )
            }
        }
 }
}

contract MockTarget {
   using AddressUtils for address;

    function checkCallerIsContract() public {
      (msg.sender).assertIsContract();
    }
}