// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;
import {Script} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract DeployScript is Script {
    address deployer;
    function run() public returns (Auction) {
        deployer = msg.sender;
        vm.startBroadcast(deployer);
        Auction auction = new Auction(deployer);
        vm.stopBroadcast();
        return auction;
    }
}
