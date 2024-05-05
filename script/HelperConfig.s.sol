// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is
    Script // needs to be is Script to allow StartBroadcast to be called
{
    // If we are on a local anvil, we deploy mocks
    //Otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INTIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
        //dummyAddress
        //dummyAddress1
    }

    constructor() {
        // use constructor instead of function to ensure proper initialization and maintain consistency
        if (block.chainid == 11155111 /*sepolia*/) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1 /*Eth/USD mainnet*/) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config;
        config.priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        return config;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config;
        config.priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        return config;
    }

    // to create anvil need to create a mock
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //cannot be a pure function
        /* Because a pure function Produces the same output for the same input every time it's called, however 
        vm.startBroadcast() and vm.stopBroadcast(): These functions likely interact with the blockchain's virtual machine 
        (VM) state or external systems, potentially modifying them. This goes against the rules of pure functions. */
        if (activeNetworkConfig.priceFeed != address(0)) {
            //!= is dosent not equal
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INTIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
