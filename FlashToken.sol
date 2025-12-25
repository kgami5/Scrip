// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    // --- FEES ---
    uint256 public feePercentage = 5;
    address public feeWallet;

    // --- PROTECTIONS ---
    uint256 public maxTxAmount;
    uint256 public cooldownTime = 30; // en secondes
    mapping(address => uint256) private lastTxTime;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        owner = msg.sender;
        feeWallet = msg.sender;

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        uint256 supply = initialSupply * (10 ** uint256(decimals));
        totalSupply = supply;
        balanceOf[msg.sender] = supply;

        // default maxTxAmount = 1% du supply
        maxTxAmount = supply / 100;

        emit Transfer(address(0), msg.sender, supply);
    }

    // --- INTERNAL ---
    function _fee(uint256 amount) internal view returns (uint256) {
        return (amount * feePercentage) / 100;
    }

    function _checkLimits(address from, uint256 amount) internal {
        if (from != owner) {
            require(amount <= maxTxAmount, "Max tx limit exceeded");
            require(
                block.timestamp - lastTxTime[from] >= cooldownTime,
                "Cooldown active"
            );
            lastTxTime[from] = block.timestamp;
        }
    }

    // --- ERC20 ---
    function transfer(address to, uint256 amount) public returns (bool) {
        _checkLimits(msg.sender, amount);

        uint256 fee = _fee(amount);
        uint256 sendAmount = amount - fee;

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += sendAmount;
        balanceOf[feeWallet] += fee;

        emit Transfer(msg.sender, feeWallet, fee);
        emit Transfer(msg.sender, to, sendAmount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        allowance[from][msg.sender] -= amount;
        _checkLimits(from, amount);

        uint256 fee = _fee(amount);
        uint256 sendAmount = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += sendAmount;
        balanceOf[feeWallet] += fee;

        emit Transfer(from, feeWallet, fee);
        emit Transfer(from, to, sendAmount);
        return true;
    }

    // --- BURN ---
    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, DEAD, amount);
    }

    // --- OWNER SETTINGS ---
    function setFeePercentage(uint256 fee) external onlyOwner {
        require(fee <= 25, "Fee too high");
        feePercentage = fee;
    }

    function setFeeWallet(address wallet) external onlyOwner {
        feeWallet = wallet;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount * (10 ** uint256(decimals));
    }

    function setCooldownTime(uint256 seconds_) external onlyOwner {
        cooldownTime = seconds_;
    }
}
