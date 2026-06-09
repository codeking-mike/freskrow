// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {BaseTest} from "../BaseTest.t.sol";

contract FuzzEscrowTest is BaseTest {

    function testFuzzFundingAmounts(
        uint96 amount
    ) public {

        vm.assume(amount > 0);
        vm.assume(amount < 100 ether);

        uint256 escrowId = createDefaultEscrow();

        vm.deal(client, amount);

        vm.prank(client);

        frescrow.fundEscrow{value: amount}(
            escrowId
        );

        (
            ,
            ,
            ,
            uint256 fundedAmount,
            ,
            ,
            ,
            ,
            
        ) = frescrow.escrows(escrowId);

        assertEq(fundedAmount, amount);
    }
}