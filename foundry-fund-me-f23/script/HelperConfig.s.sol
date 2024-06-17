// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract HelperConfig {
    //If we are on a local anvilm we deploy mocks
    // Otherwise, grab the existing addresses from the live network
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else  {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        // price feed address for sepolia
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public view returns (NetworkConfig memory) {
        // price feed address for anvil
    }
}