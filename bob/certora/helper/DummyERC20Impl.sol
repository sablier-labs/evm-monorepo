// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal ERC-20 implementation for Certora verification.
///         Provides concrete token behavior so the prover can track balances
///         instead of havocing transfers. Does not track totalSupply changes
///         in transfer/transferFrom — only balance accounting matters for
///         the properties being verified.
contract DummyERC20Impl {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    uint8 public decimals = 18;

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        uint256 newBal = balanceOf[to] + amount;
        require(newBal >= balanceOf[to]);
        balanceOf[to] = newBal;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount && allowance[from][msg.sender] >= amount);
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        uint256 newBal = balanceOf[to] + amount;
        require(newBal >= balanceOf[to]);
        balanceOf[to] = newBal;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function symbol() external pure returns (string memory) {
        return "DUMMY";
    }
}
