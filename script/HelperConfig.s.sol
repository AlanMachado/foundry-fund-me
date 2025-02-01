//SPDX-Identifier-License: MIT

/* 
* 1. Deploy mocks when we are on a local anvil chain
* 2. Keep track of contract address across different chains
*/

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 111551111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory sepoliaConfig){
        sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    /*
    * Deploy the mocks and return the mock address
    */
    function getAnvilEthConfig() public returns(NetworkConfig memory anvilConfig){
        vm.startBroadcast();
        MockV3Aggregator mockPricedFeed = new MockV3Aggregator(8, 2000e8);
        vm.stopBroadcast();

        anvilConfig = NetworkConfig({
            priceFeed: address(mockPricedFeed)
        });
    }
}

