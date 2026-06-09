// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {FresCrow} from "../src/FresCrow.sol";

contract DeployFresCrow is Script {
    function run() external {
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        vm.startBroadcast(deployerPrivateKey);

        address platformOwner = 0x572510f1b17905dec7Fe4EAeFf458b2aE8c5A452;
        FresCrow frescrow = new FresCrow(platformOwner);

        vm.stopBroadcast();
    }
}