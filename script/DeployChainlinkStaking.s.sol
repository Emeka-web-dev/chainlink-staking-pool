// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ChainLinkStaking} from "../src/ChainlinkStakingPool.sol";

contract DeployChainlinkStaking is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        uint64 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 entryFee;
        uint256 stakingDuration;
        uint256 deployerKey;
    }

     // Map of chain IDs to their network configurations
    mapping(uint256 => NetworkConfig) public networkConfigs;

    function setup() public {
        // Ethereum Mainnet configuration
        networkConfigs[1] = NetworkConfig({
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909, // Mainnet VRF Coordinator V2
            subscriptionId: 1, // Replace with your actual subscription ID
            gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, // 200 gwei premium
            callbackGasLimit: 500000, // 500k gas
            entryFee: 0.01 ether,
            stakingDuration: 5 minutes,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

         // Ethereum Sepolia Testnet configuration
        networkConfigs[11155111] = NetworkConfig({
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // Sepolia VRF Coordinator V2
            subscriptionId: 1, // Replace with your actual subscription ID
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // 150 gwei premium
            callbackGasLimit: 500000, // 500k gas
            entryFee: 0.001 ether,
            stakingDuration: 5 minutes,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });


    }

    function run() external {
        uint256 chainId  = block.chainid;
        
        require(networkConfigs[chainId].vrfCoordinator != address(0), "Chain not supported");

        NetworkConfig memory config = networkConfigs[chainId];

        vm.startBroadcast(config.deployerKey);

        ChainLinkStaking staking = new ChainLinkStaking(
            config.vrfCoordinator,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit,
            config.entryFee,
            config.stakingDuration
        );

        vm.stopBroadcast();

        console.log("ChainlinkLottery deployed to: ", address(staking));
        console.log("Chain ID: ", chainId);
        console.log("Entry Fee: ", config.entryFee);
        console.log("Lottery Duration: ", config.stakingDuration);
    }
}