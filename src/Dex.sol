// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dex {
    constructor(address tokenX, address tokenY) {

    }

    function addLiquidity(uint256 amountX, uint256 amountY, uint256 minLPToken) external returns (uint lpTokens) {}
    
    function removeLiquidity(uint256 lpTokens, uint256 minAmountX, uint256 minAmountY) external returns (uint amountX, uint amountY) {}
    
    function swap(uint256 amountXIn, uint256 amountYIn, uint256 minAmountOut) external returns (uint amountOut)  {}
}
