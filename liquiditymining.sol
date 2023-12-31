// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract liquiditymining is Ownable(msg.sender) {
    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastStakeTime;
        uint256 cumulativeReward;
    }

     VRFCoordinatorV2Interface COORDINATOR;
     uint64 s_subscriptionId;

     uint256 lastRequestId;
     bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;


    mapping(address => mapping(address => UserInfo)) public userStakes;
    mapping(address => bool) public supportedTokens;

    uint256 public constant INTEREST_RATE = 2; // 2% daily interest
    uint256 public constant WEEK_SECONDS = 604800; // 7 days in seconds

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 reward);

    modifier onlySupportedToken(address _token) {
        require(supportedTokens[_token], "Token not supported");
        _;
    }

    function addSupportedToken(address _token) external onlyOwner {
        supportedTokens[_token] = true;
    }

    function stake(address _token, uint256 _amount) external onlySupportedToken(_token) {
        require(_amount > 0, "Amount must be greater than zero");

        UserInfo storage user = userStakes[msg.sender][_token];

        // Calculate cumulative rewards
        updateCumulativeRewards(msg.sender, _token);

        // Transfer tokens from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Update user stakes
        user.stakedAmount += _amount;
        user.lastStakeTime = block.timestamp;

        emit Staked(msg.sender, _token, _amount);
    }

    function withdraw(address _token) external onlySupportedToken(_token) {
        UserInfo storage user = userStakes[msg.sender][_token];
        require(user.stakedAmount > 0, "No staked amount");

        // Calculate cumulative rewards
        updateCumulativeRewards(msg.sender, _token);

        uint256 stakedAmount = user.stakedAmount;
        uint256 cumulativeReward = user.cumulativeReward;

        // Transfer staked amount and rewards to user
        IERC20(_token).transfer(msg.sender, stakedAmount);
        IERC20(_token).transfer(msg.sender, cumulativeReward);

        // Reset user stakes
        user.stakedAmount = 0;
        user.lastStakeTime = 0;
        user.cumulativeReward = 0;

        emit Withdrawn(msg.sender, _token, stakedAmount, cumulativeReward);
    }

    function updateCumulativeRewards(address _user, address _token) internal {
        UserInfo storage user = userStakes[_user][_token];

        uint256 elapsedTime = block.timestamp - user.lastStakeTime;
        uint256 dailyReward = (user.stakedAmount * INTEREST_RATE * elapsedTime) / (100 * 1 days);

        // Update cumulative rewards
        user.cumulativeReward += dailyReward;

        // Reset last stake time to current time
        user.lastStakeTime = block.timestamp;
    }
}
