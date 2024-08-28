// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Dex is ERC20 {
    IERC20 public tokenX;
    IERC20 public tokenY;

    uint256 private reserveX;
    uint256 private reserveY;

    constructor(address _tokenX, address _tokenY) ERC20("DEX LP TOKEN", "LPT"){
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
    }

    function addLiquidity(uint256 amountX, uint256 amountY, uint256 minLPToken) external returns (uint lpTokens) {
        require(tokenX.allowance(msg.sender, address(this)) >= amountX, "ERC20: insufficient allowance");
        require(tokenY.allowance(msg.sender, address(this)) >= amountY, "ERC20: insufficient allowance");
        require(tokenX.balanceOf(msg.sender) >= amountX, "ERC20: transfer amount exceeds balance");
        require(tokenY.balanceOf(msg.sender) >= amountY, "ERC20: transfer amount exceeds balance"); 

        tokenX.transferFrom(msg.sender, address(this), amountX);
        tokenY.transferFrom(msg.sender, address(this), amountY);

        lpTokens = mint(msg.sender, amountX, amountY);
        require(minLPToken <= lpTokens, "minimum LP too much");
    }
    
    function removeLiquidity(uint256 lpTokens, uint256 minAmountX, uint256 minAmountY) external returns (uint amountX, uint amountY) {
        transferFrom(msg.sender, address(this), lpTokens);
        
        (amountX, amountY) = burn(msg.sender);
        require(amountX >= minAmountX, "INSUFFICIENT_X_AMOUNT");
        require(amountY >= minAmountY, "INSUFFICIENT_Y_AMOUNT");

    }
    
    function swap(uint256 amountXIn, uint256 amountYIn, uint256 minAmountOut) external returns (uint amountOut)  {
        require(amountXIn > 0 || amountYIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 _reserveX, uint256 _reserveY) = getReserve();

        if (amountXIn > 0 && amountYIn == 0)
        {
            tokenX.transferFrom(msg.sender, address(this), amountXIn);
            amountOut = _reserveY - (_reserveX * _reserveY) / (_reserveX + amountXIn);
            amountOut = amountOut * 999 / 1000;
            tokenY.transfer(msg.sender, amountOut);
        }
        else if (amountXIn == 0 && amountYIn > 0)
        {
            tokenY.transferFrom(msg.sender, address(this), amountYIn);
            amountOut = _reserveX - (_reserveX * _reserveY) / (_reserveY + amountYIn);
            amountOut = amountOut * 999 / 1000;
            tokenX.transfer(msg.sender, amountOut);
        }
        else
        {
            revert("INVALID_INPUT");
        }
        require(amountOut >= minAmountOut, "INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function mint(address to, uint256 amountX, uint256 amountY) private returns (uint256 liquidity) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountX * amountY);
        }
        else {
            liquidity = Math.min(amountX * _totalSupply / reserveX, amountY * _totalSupply / reserveY);
        }

        require(liquidity > 0, "DEX: INSUFFICIENT_QLIQUIDITY_MINTED");
        
        _mint(to, liquidity);
        update(tokenX.balanceOf(address(this)), tokenY.balanceOf(address(this)));
        return (liquidity);
    }

    function burn(address to) private returns (uint256 amountX, uint256 amountY) {
        uint256 balanceX = tokenX.balanceOf(address(this));
        uint256 balanceY = tokenY.balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));
        uint256 _totalSupply = totalSupply();

        amountX = balanceX * liquidity / _totalSupply;
        amountY = balanceY * liquidity / _totalSupply;
        require(amountX > 0 && amountY > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        tokenX.transfer(to, amountX);        
        tokenY.transfer(to, amountY);
        
        update(tokenX.balanceOf(address(this)), tokenY.balanceOf(address(this)));
    }

    function getReserve() private view returns (uint256 _reserveX, uint256 _reserveY) {
        _reserveX = reserveX;
        _reserveY = reserveY;
    }

    function update(uint256 _balanceX, uint256 _balanceY) private {
        reserveX = _balanceX;
        reserveY = _balanceY;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (to == address(this))
            _transfer(from, to, value);
        else
            super.transferFrom(from, to, value);
        return true;
    }
}
