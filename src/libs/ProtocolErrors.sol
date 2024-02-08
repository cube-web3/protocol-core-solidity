// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title CUBE3 Protocol Errors
/// @notice Defines errors for the CUBE3 Protocol.

library ProtocolErrors {

    /////////////////////////////////////////////////////////////////////////////////
    //                                  Shared Protocol                            //
    /////////////////////////////////////////////////////////////////////////////////

   /// @notice Throws when the target address is not an EOA or a contract under construction.
   error Cube3Protocol_TargetNotAContract(address target);

   /// @notice Throws when the target address is a contract.
   error Cube3Protocol_TargetIsContract(address target);


    /////////////////////////////////////////////////////////////////////////////////
    //                                       Router                                //
    /////////////////////////////////////////////////////////////////////////////////

   /// @notice Throws when the provided registry address is the Zero address. 
   error Cube3Router_InvalidRegistry();

   /// @notice Throws when the module address being retrieved using the ID doesn't exist.
   error Cube3Router_ModuleNotInstalled(bytes16 moduleId);

   /// @notice Throws when the module returns data that doesn't match the expected MODULE_CALL_SUCCEEDED hash.
   error Cube3Router_ModuleReturnedInvalidData();
 
   /// @notice Throws when the data returned by the module is not 32 bytes in length.
   error Cube3Router_ModuleReturnDataInvalidLength(uint256 size);
}