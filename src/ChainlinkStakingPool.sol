// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {VRFCoordinatorV2Interface} from "@chainlink/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/automation/interfaces/AutomationCompatibleInterface.sol";

contract ChainLinkStaking is VRFConsumerBaseV2, AutomationCompatibleInterface {
    enum StakingStatus {
        ACTIVE,
        INACTIVE
    }
    StakingStatus public stakingState;

    uint public immutable entyFee;
    uint public immutable stakingDuration;
    uint public lastStakedAt;
    address payable[] public stakers;
    address public recentWinner;

    //VFR configuration
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint64 private immutable subscriptionId;
    bytes32 private immutable gasLane;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    // Events
     event StakeEnter(address indexed player);
    event RequestedStakeWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner, uint256 amount);
    event StakeRestarted(uint256 timestamp);

    constructor(
        address vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        uint _entryFee,
        uint _stakingDuration
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        subscriptionId = _subscriptionId;
        gasLane = _gasLane;
        callbackGasLimit = _callbackGasLimit;
        entyFee = _entryFee;
        stakingDuration = _stakingDuration;
        stakingState = StakingStatus.ACTIVE;
        lastStakedAt = block.timestamp;
    }


    // User to stake by sending ether
    function enterStake() external payable {
        require(stakingState == StakingStatus.ACTIVE, "Staking is not active");
        require(msg.value == entyFee, "Not enough ether sent");

        stakers.push(payable(msg.sender));
        lastStakedAt = block.timestamp;
        emit StakeEnter(msg.sender);
    }

    // Check if the lottery should be performed
    function checkUpkeep(bytes memory) public view override returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = (stakingState == StakingStatus.ACTIVE);
        bool timePassed = ((block.timestamp - lastStakedAt) >= stakingDuration);
        bool hasPlayers = (stakers.length > 0);
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

        return (upkeepNeeded, "");
    }

    // Perform the upkeep
    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");

        stakingState = StakingStatus.INACTIVE;

        uint requestId = vrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedStakeWinner(requestId);
    }

    // Callback function for VRF
    function fulfillRandomWords(uint256, uint256[] memory ramdomWords) internal override {
        require(stakingState == StakingStatus.INACTIVE, "Not in inactive state");
        require(ramdomWords.length > 0, "No random words returned");

        uint256 indexOfWinner = ramdomWords[0] % stakers.length;
        address payable winner = stakers[indexOfWinner];
        recentWinner = winner;

        uint256 prize = address(this).balance;

        stakers = new address payable[](0);
        stakingState = StakingStatus.ACTIVE;
        lastStakedAt = block.timestamp;

        (bool success, ) = winner.call{value: prize}("");
        require(success, "Failed to send prize");

        emit WinnerPicked(winner, prize);
        emit StakeRestarted(block.timestamp);
    }

    // Get number of players
    function getNumberOfPlayers() external view returns (uint) {
        return stakers.length;
    }

    // Get latest Timestamp
    function getLatestTimestamp() external view returns (uint) {
        return lastStakedAt;
    }

    //Get current staking state
    function getCurrentStakingState() external view returns (StakingStatus) {
        return stakingState;
    }

    // Get entry fee
    function getEntryFee() external view returns (uint) {
        return entyFee;
    }

    // get time left
    function getTimeLeftUntilDrawing() public view returns (uint256) {
        if (block.timestamp > lastStakedAt + stakingDuration) {
            return 0;
        } 
          return stakingDuration - (block.timestamp - lastStakedAt);               
        
    }

}
