// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {FresCrow} from "src/FresCrow.sol";

contract FresCrowTest is Test {
    FresCrow public escrow;

    address public platformOwner = address(0xA11CE);
    address public client = address(0xBEEF);
    address public freelancer = address(0xCAFE);

    function setUp() public {
        vm.deal(client, 10 ether);
        vm.deal(freelancer, 10 ether);
        vm.prank(platformOwner);
        escrow = new FresCrow(platformOwner);
    }

    function testCreateEscrowStoresPaymentAndStatus() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "Landing page design");

        vm.prank(client);
        escrow.fundEscrow{value: 2 ether}(1);

        (address storedClient, address storedFreelancer, uint256 storedAmount, uint256 releasedAmount, FresCrow.Status status, string memory title) = escrow.getEscrow(1);

        assertEq(storedClient, client);
        assertEq(storedFreelancer, freelancer);
        assertEq(storedAmount, 2 ether);
        assertEq(releasedAmount, 0);
        assertEq(uint256(status), uint256(FresCrow.Status.Funded));
        assertEq(title, "Landing page design");
        assertEq(address(escrow).balance, 2 ether);
    }

    function testFreelancerCanMarkCompletedAndClientCanReleaseFunds() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "Smart contract audit");

        vm.prank(client);
        escrow.fundEscrow{value: 3 ether}(1);

        vm.prank(freelancer);
        escrow.acceptJob(1);

        vm.prank(freelancer);
        escrow.markDelivered(1);

        vm.prank(freelancer);
        escrow.markCompleted(1);

        vm.prank(client);
        escrow.releaseFunds(1);

        assertEq(freelancer.balance, 10 ether + 3 ether);
        assertEq(address(escrow).balance, 0);

        (, , , uint256 releasedAmount, FresCrow.Status status, ) = escrow.getEscrow(1);
        assertEq(releasedAmount, 3 ether);
        assertEq(uint256(status), uint256(FresCrow.Status.Released));
    }

    function testClientCanRefundBeforeCompletion() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "Logo design");

        vm.prank(client);
        escrow.fundEscrow{value: 1 ether}(1);

        vm.prank(client);
        escrow.refund(1);

        assertEq(client.balance, 10 ether);
        assertEq(address(escrow).balance, 0);

        (, , , , FresCrow.Status status, ) = escrow.getEscrow(1);
        assertEq(uint256(status), uint256(FresCrow.Status.Refunded));
    }

    function testClientCanCancelCreatedEscrowBeforeFunding() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "Logo design");

        vm.prank(client);
        escrow.refund(1);

        assertEq(client.balance, 10 ether);
        assertEq(address(escrow).balance, 0);

        (, , , , FresCrow.Status status, ) = escrow.getEscrow(1);
        assertEq(uint256(status), uint256(FresCrow.Status.Cancelled));
    }

    function testDisputeCanBeResolvedByPlatformOwner() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "NFT marketplace build");

        vm.prank(client);
        escrow.fundEscrow{value: 4 ether}(1);

        vm.prank(freelancer);
        escrow.raiseDispute(1);

        vm.prank(platformOwner);
        escrow.resolveDispute(1, freelancer);

        assertEq(freelancer.balance, 10 ether + 4 ether);
        assertEq(address(escrow).balance, 0);

        (, , , uint256 releasedAmount, FresCrow.Status status, ) = escrow.getEscrow(1);
        assertEq(releasedAmount, 4 ether);
        assertEq(uint256(status), uint256(FresCrow.Status.Released));
    }

    function testOnlyAuthorizedActorsCanAct() public {
        vm.prank(client);
        escrow.createEscrow(freelancer, "SEO content");

        vm.prank(client);
        escrow.fundEscrow{value: 1 ether}(1);

        vm.prank(client);
        vm.expectRevert(FresCrow.NotFreelancer.selector);
        escrow.markCompleted(1);

        vm.prank(freelancer);
        vm.expectRevert(FresCrow.NotClient.selector);
        escrow.releaseFunds(1);

        vm.prank(client);
        escrow.raiseDispute(1);

        vm.prank(platformOwner);
        escrow.resolveDispute(1, client);
    }
}
