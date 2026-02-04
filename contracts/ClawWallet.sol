// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ClawWallet
 * @notice One-click wallets for AI agents on Monad
 * @dev Each agent gets a deterministic wallet ID derived from their agent name
 */
contract ClawWallet is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BASIS_POINTS = 50; // 0.5%
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant WELCOME_POINTS = 100;

    address public treasury;
    address public owner;
    
    struct Wallet {
        bool exists;
        uint256 points;
        uint256 totalSent;
        uint256 totalReceived;
        uint256 txCount;
    }
    
    mapping(bytes32 => Wallet) public wallets;
    mapping(bytes32 => uint256) public balances;
    mapping(bytes32 => mapping(address => uint256)) public tokenBalances;
    
    uint256 public totalAgents;
    
    event WalletCreated(bytes32 indexed agentId, string agentName, uint256 points);
    event Deposit(bytes32 indexed agentId, uint256 amount);
    event TokenDeposit(bytes32 indexed agentId, address indexed token, uint256 amount);
    event Sent(bytes32 indexed from, address indexed to, uint256 amount, uint256 fee, uint256 points);
    event TokenSent(bytes32 indexed from, address indexed to, address indexed token, uint256 amount, uint256 fee, uint256 points);
    event AgentToAgent(bytes32 indexed from, bytes32 indexed to, uint256 amount, uint256 fee, uint256 points);
    event PointsEarned(bytes32 indexed agentId, uint256 points, string reason);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier walletExists(bytes32 agentId) {
        require(wallets[agentId].exists, "Wallet does not exist");
        _;
    }

    constructor(address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
    }

    function createWallet(string calldata agentName) external returns (bytes32 agentId) {
        agentId = keccak256(abi.encodePacked(agentName));
        require(!wallets[agentId].exists, "Wallet already exists");
        
        wallets[agentId] = Wallet({
            exists: true,
            points: WELCOME_POINTS,
            totalSent: 0,
            totalReceived: 0,
            txCount: 0
        });
        
        totalAgents++;
        
        emit WalletCreated(agentId, agentName, WELCOME_POINTS);
        emit PointsEarned(agentId, WELCOME_POINTS, "welcome");
        
        return agentId;
    }
    
    function deposit(bytes32 agentId) external payable walletExists(agentId) {
        require(msg.value > 0, "Must deposit something");
        
        balances[agentId] += msg.value;
        wallets[agentId].totalReceived += msg.value;
        
        emit Deposit(agentId, msg.value);
    }
    
    function depositToken(bytes32 agentId, address token, uint256 amount) external walletExists(agentId) {
        require(amount > 0, "Must deposit something");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[agentId][token] += amount;
        
        emit TokenDeposit(agentId, token, amount);
    }
    
    function send(bytes32 agentId, address to, uint256 amount) external nonReentrant walletExists(agentId) {
        require(balances[agentId] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        uint256 fee = (amount * FEE_BASIS_POINTS) / BASIS_POINTS;
        uint256 netAmount = amount - fee;
        
        balances[agentId] -= amount;
        wallets[agentId].totalSent += amount;
        wallets[agentId].txCount++;
        
        uint256 points = _calculatePoints(amount);
        wallets[agentId].points += points;
        
        (bool success, ) = to.call{value: netAmount}("");
        require(success, "Transfer failed");
        
        if (fee > 0) {
            (bool feeSuccess, ) = treasury.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        emit Sent(agentId, to, netAmount, fee, points);
        emit PointsEarned(agentId, points, "send");
    }
    
    function sendToken(bytes32 agentId, address to, address token, uint256 amount) external nonReentrant walletExists(agentId) {
        require(tokenBalances[agentId][token] >= amount, "Insufficient token balance");
        require(to != address(0), "Invalid recipient");
        
        uint256 fee = (amount * FEE_BASIS_POINTS) / BASIS_POINTS;
        uint256 netAmount = amount - fee;
        
        tokenBalances[agentId][token] -= amount;
        wallets[agentId].totalSent += amount;
        wallets[agentId].txCount++;
        
        uint256 points = _calculatePoints(amount) * 2;
        wallets[agentId].points += points;
        
        IERC20(token).safeTransfer(to, netAmount);
        
        if (fee > 0) {
            IERC20(token).safeTransfer(treasury, fee);
        }
        
        emit TokenSent(agentId, to, token, netAmount, fee, points);
        emit PointsEarned(agentId, points, "sendToken");
    }
    
    function sendToAgent(bytes32 fromAgentId, bytes32 toAgentId, uint256 amount) external nonReentrant walletExists(fromAgentId) walletExists(toAgentId) {
        require(balances[fromAgentId] >= amount, "Insufficient balance");
        require(fromAgentId != toAgentId, "Cannot send to self");
        
        uint256 fee = (amount * FEE_BASIS_POINTS) / BASIS_POINTS;
        uint256 netAmount = amount - fee;
        
        balances[fromAgentId] -= amount;
        balances[toAgentId] += netAmount;
        
        wallets[fromAgentId].totalSent += amount;
        wallets[toAgentId].totalReceived += netAmount;
        wallets[fromAgentId].txCount++;
        
        uint256 points = _calculatePoints(amount);
        wallets[fromAgentId].points += points;
        
        if (fee > 0) {
            (bool feeSuccess, ) = treasury.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        emit AgentToAgent(fromAgentId, toAgentId, netAmount, fee, points);
        emit PointsEarned(fromAgentId, points, "sendToAgent");
    }

    function getWallet(bytes32 agentId) external view returns (bool exists, uint256 balance, uint256 points, uint256 totalSent, uint256 totalReceived, uint256 txCount) {
        Wallet memory w = wallets[agentId];
        return (w.exists, balances[agentId], w.points, w.totalSent, w.totalReceived, w.txCount);
    }
    
    function getTokenBalance(bytes32 agentId, address token) external view returns (uint256) {
        return tokenBalances[agentId][token];
    }
    
    function getAgentId(string calldata agentName) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(agentName));
    }

    function _calculatePoints(uint256 amount) internal pure returns (uint256) {
        if (amount >= 100 ether) return 10;
        if (amount >= 10 ether) return 7;
        if (amount >= 1 ether) return 5;
        if (amount >= 0.1 ether) return 3;
        return 1;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    receive() external payable {}
}
