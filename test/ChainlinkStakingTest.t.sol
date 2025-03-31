// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/ChainlinkStakingPool.sol";
import "@chainlink/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract ChainLinkStakingTest is Test {
    ChainLinkStaking staking;
    VRFCoordinatorV2Mock vrfCoordinatorMock;

    // Test Account
    address public deployer = makeAddr("deployer");
    address public player1 = makeAddr("player1");
    address public player2 = makeAddr("player2");
    address public player3 = makeAddr("player3");

     // Lottery configuration
    uint256 public constant ENTRY_FEE = 0.01 ether;
    uint256 public constant LOTTERY_DURATION = 5 minutes;
    uint64 public constant SUBSCRIPTION_ID = 1;
    bytes32 public constant GAS_LANE = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 public constant CALLBACK_GAS_LIMIT = 500000;

      // VRF coordinator mock configuration
    uint96 public constant FUND_AMOUNT = 1 ether;
    uint32 public constant GAS_PRICE_LINK = 1e9; // 1 gwei LINK

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);

        vm.startBroadcast(deployer);
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(GAS_PRICE_LINK, 1e9);

        // create and fund a subscription;
        vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(SUBSCRIPTION_ID, FUND_AMOUNT);

        staking = new ChainLinkStaking(
            address(vrfCoordinatorMock),
            SUBSCRIPTION_ID,
            GAS_LANE,
            CALLBACK_GAS_LIMIT,
            ENTRY_FEE,
            LOTTERY_DURATION
        );

        vrfCoordinatorMock.addConsumer(SUBSCRIPTION_ID, address(staking));
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(uint8(staking.getCurrentStakingState()), uint8(0));
        assertEq(staking.getEntryFee(), ENTRY_FEE);
        assertEq(staking.getNumberOfPlayers(), 0);
    }

    // function testCheckUpkeep() public {
    //     (bool upkeepNeeded, ) = staking.checkUpkeep("");
    // }
}