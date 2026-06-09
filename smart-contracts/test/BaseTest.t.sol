// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {FresCrow} from "../src/FresCrow.sol";

contract BaseTest is Test {

    FresCrow internal frescrow;

    address internal platformOwner = address(100);
    address internal client = address(1);
    address internal freelancer = address(2);
    address internal stranger = address(3);

    uint256 internal constant ESCROW_AMOUNT = 1 ether;

    function setUp() public virtual {

        frescrow = new FresCrow(platformOwner);

        vm.deal(client, 10 ether);
        vm.deal(freelancer, 10 ether);
        vm.deal(stranger, 10 ether);
    }

    function createDefaultEscrow() internal returns (uint256) {

        vm.prank(client);

        frescrow.createEscrow(
            freelancer,
            "Build Web3 Dashboard"
        );

        return frescrow.escrowCount();
    }

    function fundDefaultEscrow() internal returns (uint256) {

        uint256 escrowId = createDefaultEscrow();

        vm.prank(client);

        frescrow.fundEscrow{value: ESCROW_AMOUNT}(
            escrowId
        );

        return escrowId;
    }
}