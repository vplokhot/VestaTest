// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./ERC20Callback.sol";

contract MyToken is ERC20Callback {

    uint8 constant _decimals = 18;
    uint256 constant _totalSupply = 100 * (10**6) * 10**_decimals;  // 100m tokens for distribution

    constructor() ERC20Callback("MyToken", "MT") {        
        _mint(msg.sender, _totalSupply);
    }
}