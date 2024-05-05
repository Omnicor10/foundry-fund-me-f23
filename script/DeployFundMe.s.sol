//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); /*doing this before the startbroadcast not a "real" transaction 
        therefor saves gas*/

        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        /* If using muiltpe addresses in struct NetworkConfig in HelperConfig.s.sol then the function would need to be written like
        (address ethUsdPriceFeed, address dummyAddress, address dummyAddress1) = helperConfig.activeNetworkConfig();*/

        vm.startBroadcast();
        // After startBroadcast real tx
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
