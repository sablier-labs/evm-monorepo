// ERC20.spec — CVL Ghost-Based ERC20 Model (Pattern A103)
//
// Models ERC20 behavior entirely in CVL using ghost mappings keyed by
// (token_address, account). Uses `calledContract` to identify which token
// is being operated on, so it works for contracts that store tokens
// per-vault or per-order (not as top-level storage variables).
//
// SafeERC20 internal library functions are summarized to route through
// the CVL model, matching the Sablier contracts' usage of OZ SafeERC20.

/*//////////////////////////////////////////////////////////////////////////
                        GHOST STATE
//////////////////////////////////////////////////////////////////////////*/

persistent ghost mapping(address => mapping(address => uint256)) ghostERC20Balances;
persistent ghost mapping(address => mapping(address => mapping(address => uint256))) ghostERC20Allowances;

/*//////////////////////////////////////////////////////////////////////////
                        CVL ERC20 FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

function balanceOfCVL(address token, address account) returns uint256 {
    return ghostERC20Balances[token][account];
}

function transferCVL(address token, address from, address to, uint256 amount) returns bool {
    require ghostERC20Balances[token][from] >= amount,
        "ERC20: insufficient balance";

    if (from != to) {
        ghostERC20Balances[token][from] =
            require_uint256(ghostERC20Balances[token][from] - amount);
        ghostERC20Balances[token][to] =
            require_uint256(ghostERC20Balances[token][to] + amount);
    }
    return true;
}

function transferFromCVL(
    address token, address spender, address from, address to, uint256 amount
) returns bool {
    require ghostERC20Balances[token][from] >= amount,
        "ERC20: insufficient balance";

    // Check and deduct allowance (max_uint256 = infinite approval)
    if (spender != from) {
        mathint currentAllowance = ghostERC20Allowances[token][from][spender];
        require currentAllowance >= to_mathint(amount),
            "ERC20: insufficient allowance";
        if (currentAllowance != to_mathint(max_uint256)) {
            ghostERC20Allowances[token][from][spender] =
                require_uint256(currentAllowance - amount);
        }
    }

    if (from != to) {
        ghostERC20Balances[token][from] =
            require_uint256(ghostERC20Balances[token][from] - amount);
        ghostERC20Balances[token][to] =
            require_uint256(ghostERC20Balances[token][to] + amount);
    }
    return true;
}

function approveCVL(address token, address owner, address spender, uint256 amount) returns bool {
    ghostERC20Allowances[token][owner][spender] = amount;
    return true;
}

/*//////////////////////////////////////////////////////////////////////////
                    SAFEERC20 INTERNAL SUMMARIES
//////////////////////////////////////////////////////////////////////////*/

/// @notice SafeERC20.safeTransfer — transfers from currentContract to `to`
function safeTransferCVL(address token, address to, uint256 amount) {
    require transferCVL(token, currentContract, to, amount),
        "safeTransfer failed";
}

/// @notice SafeERC20.safeTransferFrom — transfers from `from` to `to`
function safeTransferFromCVL(address token, address from, address to, uint256 amount) {
    require transferFromCVL(token, currentContract, from, to, amount),
        "safeTransferFrom failed";
}

/*//////////////////////////////////////////////////////////////////////////
                    METHODS BLOCK SUMMARIES
//////////////////////////////////////////////////////////////////////////*/

methods {
    // SafeERC20 internal library summaries — these are the PRIMARY token transfer
    // mechanism for Sablier contracts. They receive the token address as a parameter,
    // enabling per-token balance tracking without needing the `link` directive.
    //
    // IMPORTANT: External _.transfer/_.transferFrom wildcards are intentionally omitted.
    // If both internal SafeERC20 summaries AND external wildcards are present, the prover
    // applies both (SafeERC20 internally calls token.transferFrom, which triggers the
    // external wildcard), causing double ghost updates and false violations.
    function SafeERC20.safeTransfer(address token, address to, uint256 value) internal
        => safeTransferCVL(token, to, value);
    function SafeERC20.safeTransferFrom(address token, address from, address to, uint256 value) internal
        => safeTransferFromCVL(token, from, to, value);

    // Read-only ERC20 calls — safe to use external wildcards since they don't modify state
    function _.balanceOf(address account) external
        => balanceOfCVL(calledContract, account) expect uint256;
    function _.allowance(address owner, address spender) external
        => ghostERC20Allowances[calledContract][owner][spender] expect uint256;

    // Approve — external wildcard is safe (no double-update risk, SafeERC20 doesn't wrap approve)
    function _.approve(address spender, uint256 amount) external
        => approveCVL(calledContract, currentContract, spender, amount) expect bool;
}
