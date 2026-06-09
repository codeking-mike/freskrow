// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import {BaseTest} from "../BaseTest.t.sol";
import {FresCrow} from "../../src/FresCrow.sol";

contract FundEscrowTest is BaseTest {

    function testFundEscrowSuccessfully() public {

        uint256 escrowId = createDefaultEscrow();

        vm.prank(client);

        frescrow.fundEscrow{value: ESCROW_AMOUNT}(
            escrowId
        );

        (
            ,
            ,
            ,
            uint256 amount,
            ,
            FresCrow.Status status,
            ,
            ,

        ) = frescrow.escrows(escrowId);

        assertEq(amount, ESCROW_AMOUNT);
        assertEq(uint256(status), 1);
    }

    function testNonClientCannotFundEscrow() public {

        uint256 escrowId = createDefaultEscrow();

        vm.prank(stranger);

        vm.expectRevert(
            FresCrow.NotClient.selector
        );

        frescrow.fundEscrow{value: ESCROW_AMOUNT}(
            escrowId
        );
    }

    function testCannotFundWithZeroAmount() public {

        uint256 escrowId = createDefaultEscrow();

        vm.prank(client);

        vm.expectRevert(
            FresCrow.InvalidAmount.selector
        );

        frescrow.fundEscrow{value: 0}(
            escrowId
        );
    }

    function testEmitEscrowFundedEvent() public {

        uint256 escrowId = createDefaultEscrow();

        vm.expectEmit(true, false, false, true);

        emit FresCrow.EscrowFunded(
            escrowId,
            ESCROW_AMOUNT
        );

        vm.prank(client);

        frescrow.fundEscrow{value: ESCROW_AMOUNT}(
            escrowId
        );
    }

    function testFreelancerReceivesFunds() public {

        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(freelancer);
        frescrow.markDelivered(escrowId);

        vm.prank(freelancer);
        frescrow.markCompleted(escrowId);

        uint256 balanceBefore = freelancer.balance;

        vm.prank(client);
        frescrow.releaseFunds(escrowId);

        uint256 balanceAfter = freelancer.balance;

        assertEq(
            balanceAfter,
            balanceBefore + ESCROW_AMOUNT
        );
    }


function testCannotReleaseBeforeDelivery() public {

    uint256 escrowId = fundDefaultEscrow();

    vm.prank(client);

    vm.expectRevert(
        FresCrow.InvalidStatus.selector
    );

    frescrow.releaseFunds(escrowId);
}


}