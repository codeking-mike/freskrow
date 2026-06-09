// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {BaseTest} from "../BaseTest.t.sol";
import {FresCrow} from "../../src/FresCrow.sol";

contract CreateEscrowTest is BaseTest {

    function testCreateEscrowSuccessfully() public {

        vm.prank(client);

        frescrow.createEscrow(
            freelancer,
            "Website Design"
        );

        (
            uint256 id,
            address escrowClient,
            address escrowFreelancer,
            ,
            ,
            FresCrow.Status status,
            ,
            ,

        ) = frescrow.escrows(1);

        assertEq(id, 1);
        assertEq(escrowClient, client);
        assertEq(escrowFreelancer, freelancer);
        assertEq(uint256(status), 0);
    }

    function testRevertIfFreelancerIsZeroAddress() public {

        vm.prank(client);

        vm.expectRevert(
            FresCrow.InvalidFreelancer.selector
        );

        frescrow.createEscrow(
            address(0),
            "Invalid"
        );
    }

    function testEmitEscrowCreatedEvent() public {

        vm.expectEmit(true, true, false, true);

        emit FresCrow.EscrowCreated(
            1,
            client,
            freelancer,
            0,
            "Event Test"
        );

        vm.prank(client);

        frescrow.createEscrow(
            freelancer,
            "Event Test"
        );
    }
}