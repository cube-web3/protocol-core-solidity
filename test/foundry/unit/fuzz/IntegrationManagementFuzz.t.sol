// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";

import { IntegrationManagement } from "../../../../src/abstracts/IntegrationManagement.sol";

import {IntegrationManagementHarness} from "../../harnesses/IntegrationManagementHarness.sol";

contract IntegrationManagement_Fuzz_Unit_Test is BaseTest {

IntegrationManagementHarness integrationManagementHarness;

 function setUp() public {
   integrationManagementHarness = new IntegrationManagementHarness();
 }

   /*//////////////////////////////////////////////////////////////
           updateFunctionProtectionStatus
    //////////////////////////////////////////////////////////////*/
 
    // succeeds updating function protection status as admin for registered integration
    function testFuzz_SucceedsWhen_UpdatingFunctionProtectionStatus_AsIntegrationAdmin(uint256 numSelectors, uint256 selectorSeed) public {
     numSelectors = bound(numSelectors, 1,10);
     selectorSeed = bound(selectorSeed, 1, type(uint256).max - numSelectors);
     
     address integration = _randomAddress();
     address admin = _randomAddress();
     assertNotEq(integration, admin, "integration and admin match");

    // set the integration admin
     integrationManagementHarness.setIntegrationAdmin(integration, admin);

    // set the integration registration status
     integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);



     // create the selectors to update
     Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](numSelectors);
     for (uint i; i < numSelectors; i++) {
       uint256 j = uint256(_randomBytes32(selectorSeed));
       bytes4 selector = bytes4(bytes32(j));
       bool status = j % 2 ==0 ;

       updates[i] = Structs.FunctionProtectionStatusUpdate({
         fnSelector: selector,
         protectionEnabled: status
       });
     }

      vm.startPrank(admin);
      integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
      vm.stopPrank();

      // check the statuses
      for (uint i; i < updates.length; i++) {
      bool result = integrationManagementHarness.getIsIntegrationFunctionProtected(integration, updates[i].fnSelector);
      assertEq(result, updates[i].protectionEnabled, "status mismatch");
      }


     
    }

    // fails updating function protection status as non admin

    // fails updating function protection status for unregistered integration

    // fails updating function protection status as non admin

   

}