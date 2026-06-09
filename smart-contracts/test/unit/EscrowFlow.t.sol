// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {BaseTest} from "../BaseTest.t.sol";
import {FresCrow} from "../../src/FresCrow.sol";

contract RevertingReceiver {
    fallback() external payable {
        revert("transfer failed");
    }
}

contract EscrowFlowTest is BaseTest {
    RevertingReceiver internal badReceiver;

    function setUp() public override {
        super.setUp();
        badReceiver = new RevertingReceiver();
    }

    function testFundEscrowAlreadyFundedReverts() public {
        uint256 escrowId = createDefaultEscrow();

        vm.prank(client);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.InvalidStatus.selector);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(escrowId);
    }

    function testAcceptJobMustBeFreelancerAndFunded() public {
        uint256 escrowId = createDefaultEscrow();

        vm.prank(client);
        vm.expectRevert(FresCrow.NotFreelancer.selector);
        frescrow.acceptJob(escrowId);

        vm.prank(client);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.NotFreelancer.selector);
        frescrow.acceptJob(escrowId);
    }

    function testMarkDeliveredRequiresInProgress() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.InvalidStatus.selector);
        frescrow.markDelivered(escrowId);
    }

    function testMarkCompletedRequiresDelivered() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.InvalidStatus.selector);
        frescrow.markCompleted(escrowId);
    }

    function testReleaseFundsOnlyClient() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(freelancer);
        frescrow.markDelivered(escrowId);

        vm.prank(freelancer);
        frescrow.markCompleted(escrowId);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.NotClient.selector);
        frescrow.releaseFunds(escrowId);
    }

    function testRefundAfterReleaseReverts() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(freelancer);
        frescrow.markDelivered(escrowId);

        vm.prank(freelancer);
        frescrow.markCompleted(escrowId);

        vm.prank(client);
        frescrow.releaseFunds(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowNotPending.selector);
        frescrow.refund(escrowId);
    }

    function testRaiseDisputeOnlyParticipant() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(stranger);
        vm.expectRevert(FresCrow.NotClientOrFreelancer.selector);
        frescrow.raiseDispute(escrowId);
    }

    function testRaiseDisputeAfterResolvedReverts() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(freelancer);
        frescrow.markDelivered(escrowId);

        vm.prank(freelancer);
        frescrow.markCompleted(escrowId);

        vm.prank(client);
        frescrow.releaseFunds(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowAlreadyResolved.selector);
        frescrow.raiseDispute(escrowId);
    }

    function testResolveDisputeRequiresPlatformOwner() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.raiseDispute(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.Unauthorized.selector);
        frescrow.resolveDispute(escrowId, client);
    }

    function testResolveDisputeInvalidWinnerReverts() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.raiseDispute(escrowId);

        vm.prank(platformOwner);
        vm.expectRevert(FresCrow.InvalidWinner.selector);
        frescrow.resolveDispute(escrowId, address(0x1234));
    }

    function testResolveDisputeRefundsClient() public {
        uint256 escrowId = fundDefaultEscrow();
        uint256 clientBalanceBefore = client.balance;

        vm.prank(freelancer);
        frescrow.raiseDispute(escrowId);

        vm.prank(platformOwner);
        frescrow.resolveDispute(escrowId, client);

        assertEq(client.balance, clientBalanceBefore + ESCROW_AMOUNT);

        (, , , , FresCrow.Status status, ) = frescrow.getEscrow(escrowId);
        assertEq(uint256(status), uint256(FresCrow.Status.Refunded));
    }

    function testReleaseFundsTransferFailureReverts() public {
        vm.prank(client);
        frescrow.createEscrow(address(badReceiver), "Bad freelancer");

        vm.prank(client);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(1);

        vm.prank(address(badReceiver));
        frescrow.acceptJob(1);

        vm.prank(address(badReceiver));
        frescrow.markDelivered(1);

        vm.prank(address(badReceiver));
        frescrow.markCompleted(1);

        vm.prank(client);
        vm.expectRevert(FresCrow.TransferFailed.selector);
        frescrow.releaseFunds(1);
    }

    function testRefundTransferFailureReverts() public {
        address badClient = address(new RevertingReceiver());
        vm.deal(badClient, 10 ether);

        vm.prank(badClient);
        frescrow.createEscrow(freelancer, "Bad client");

        vm.prank(badClient);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(1);

        vm.prank(badClient);
        vm.expectRevert(FresCrow.TransferFailed.selector);
        frescrow.refund(1);
    }

    function testRefundInProgressEscrow() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(freelancer);
        frescrow.acceptJob(escrowId);

        vm.prank(client);
        frescrow.refund(escrowId);

        (, , , , FresCrow.Status status, ) = frescrow.getEscrow(escrowId);
        assertEq(uint256(status), uint256(FresCrow.Status.Refunded));
    }

    function testEscrowNotFoundForMissingEscrow() public {
        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(999);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.acceptJob(999);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.markDelivered(999);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.markCompleted(999);

        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.releaseFunds(999);

        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.refund(999);

        vm.prank(client);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.raiseDispute(999);

        vm.prank(platformOwner);
        vm.expectRevert(FresCrow.EscrowNotFound.selector);
        frescrow.resolveDispute(999, client);
    }

    function testMarkDeliveredAndCompletedRequireFreelancer() public {
        uint256 escrowId = fundDefaultEscrow();

        vm.prank(client);
        vm.expectRevert(FresCrow.NotFreelancer.selector);
        frescrow.markDelivered(escrowId);

        vm.prank(client);
        vm.expectRevert(FresCrow.NotFreelancer.selector);
        frescrow.markCompleted(escrowId);
    }

    function testEscrowListsReturnIds() public {
        uint256 firstEscrow = createDefaultEscrow();
        uint256 secondEscrow = createDefaultEscrow();

        vm.prank(client);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(firstEscrow);

        vm.prank(client);
        frescrow.fundEscrow{value: ESCROW_AMOUNT}(secondEscrow);

        uint256[] memory clientEscrows = frescrow.getClientEscrows(client);
        uint256[] memory freelancerEscrows = frescrow.getFreelancerEscrows(freelancer);

        assertEq(clientEscrows.length, 2);
        assertEq(freelancerEscrows.length, 2);
        assertEq(clientEscrows[0], firstEscrow);
        assertEq(clientEscrows[1], secondEscrow);
        assertEq(freelancerEscrows[0], firstEscrow);
        assertEq(freelancerEscrows[1], secondEscrow);
    }
}
