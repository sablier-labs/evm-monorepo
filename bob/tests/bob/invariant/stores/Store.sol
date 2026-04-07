// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Storage contract that tracks vault state for invariant assertions.
contract Store {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps vault ID to its list of users.
    mapping(uint256 vaultId => mapping(address user => bool)) internal _isUser;

    /// @dev Tokens available for vault creation.
    IERC20[] internal _tokens;

    /// @dev Maps vault ID to its list of users.
    mapping(uint256 vaultId => address[]) internal _vaultUsers;

    /// @dev Previous value of isStakedInAdapter, captured at the start of each handler call.
    mapping(uint256 vaultId => bool) public prevIsStakedInAdapter;

    /// @dev Previous vault status, captured at the start of each handler call.
    mapping(uint256 vaultId => uint8) public prevStatus;

    /// @dev Cumulative amount deposited per vault.
    mapping(uint256 vaultId => uint256) public totalDeposited;

    /// @dev Cumulative shares burned per vault.
    mapping(uint256 vaultId => uint256) public totalSharesBurned;

    /// @dev Cumulative tokens withdrawn from vault (transferAmount + fee on yield).
    mapping(uint256 vaultId => uint256) public totalWithdrawn;

    /// @dev Array of all created vault IDs.
    uint256[] public vaultIds;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20[] memory tokens_) {
        for (uint256 i = 0; i < tokens_.length; ++i) {
            _tokens.push(tokens_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addTotalDeposited(uint256 vaultId, uint256 amount) external {
        totalDeposited[vaultId] += amount;
    }

    function addTotalSharesBurned(uint256 vaultId, uint256 amount) external {
        totalSharesBurned[vaultId] += amount;
    }

    function addTotalWithdrawn(uint256 vaultId, uint256 amount) external {
        totalWithdrawn[vaultId] += amount;
    }

    function addUser(uint256 vaultId, address user) external {
        if (!_isUser[vaultId][user]) {
            _isUser[vaultId][user] = true;
            _vaultUsers[vaultId].push(user);
        }
    }

    function getTokens() external view returns (IERC20[] memory) {
        return _tokens;
    }

    function getUsers(uint256 vaultId) external view returns (address[] memory) {
        return _vaultUsers[vaultId];
    }

    function pushVaultId(uint256 vaultId) external {
        vaultIds.push(vaultId);
    }

    function setPrevIsStakedInAdapter(uint256 vaultId, bool value) external {
        prevIsStakedInAdapter[vaultId] = value;
    }

    function setPrevStatus(uint256 vaultId, uint8 status) external {
        prevStatus[vaultId] = status;
    }

    function vaultCount() external view returns (uint256) {
        return vaultIds.length;
    }
}
