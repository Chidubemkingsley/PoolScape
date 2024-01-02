// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract BUNNPool {
    address payable owner;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;

    address private immutable linkAddress =
        0x07C725d58437504CA5f814AE406e70E21C5e8e9e;
    IERC20 private link;

    uint256 private constant dailyInterestRate = 2; // 2% daily interest
    uint256 private constant secondsInADay = 86400; // 24 hours * 60 minutes * 60 seconds

    mapping(address => uint256) private stakedBalances;
    mapping(address => uint256) private lastStakeTimestamp;
    mapping(address => uint256) private lastWithdrawTimestamp;

    uint256 public constant withdrawalCooldown = 7 days; // Withdrawals allowed weekly

    constructor(address _addressProvider) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        owner = payable(msg.sender);
        link = IERC20(linkAddress);
    }

    function stake(address _tokenAddress, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Transfer tokens to the contract
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // Update staking information
        stakedBalances[_tokenAddress] += _amount;
        lastStakeTimestamp[_tokenAddress] = block.timestamp;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        require(block.timestamp >= lastWithdrawTimestamp[_tokenAddress] + withdrawalCooldown, "Withdrawal cooldown not met");
        uint256 interestEarned = calculateInterest(_tokenAddress);
        uint256 totalAmount = stakedBalances[_tokenAddress] + interestEarned;

        // Transfer total amount to the owner
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, totalAmount), "Transfer failed");

        // Reset staking information
        stakedBalances[_tokenAddress] = 0;
        lastWithdrawTimestamp[_tokenAddress] = block.timestamp;
    }

    function calculateInterest(address _tokenAddress) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastStakeTimestamp[_tokenAddress];
        uint256 interestRate = dailyInterestRate * elapsedTime / secondsInADay;

        return stakedBalances[_tokenAddress] * interestRate / 100;
    }

    function supplyLiquidity(address _tokenAddress, uint256 _amount) external {
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        POOL.supply(asset, amount, onBehalfOf, referralCode);
    }
     function withdrawlLiquidity(address _tokenAddress, uint256 _amount)
        external
        returns (uint256)
    {
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address to = address(this);

        return POOL.withdraw(asset, amount, to);
    }

    function getUserAccountData(address _userAddress)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return POOL.getUserAccountData(_userAddress);
    }

    function approveLINK(uint256 _amount, address _poolContractAddress)
        external
        returns (bool)
    {
        return link.approve(_poolContractAddress, _amount);
    }

    function allowanceLINK(address _poolContractAddress)
        external
        view
        returns (uint256)
    {
        return link.allowance(address(this), _poolContractAddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}

