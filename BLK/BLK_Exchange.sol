// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BLK_Exchange is Ownable {
    IERC20 public USDB;
    mapping(address => mapping(address => uint))public record;
    mapping(address => bool)public coinList;
    uint public limit = 100000 ether;
    uint public total;
    bool public status;

    event SwapForCoin(address indexed sender_, address indexed coin_, uint amount_);
    event SwapForUsdb(address indexed sender_, address indexed coin_, uint amount_);

    modifier isOpen(){
        require(status, 'not open');
        _;
    }
    function swapForUsdb(uint amount_, address coin_) isOpen public {
        require(coinList[coin_], 'wrong coin');
        require(total + amount_ <= limit, 'over limit');
        USDB.transfer(msg.sender, amount_);
        IERC20(coin_).transferFrom(msg.sender, address(this), amount_);
        record[msg.sender][coin_] += amount_;
        total += amount_;
        emit SwapForUsdb(msg.sender, coin_, amount_);
    }

    function swapForCoin(uint amount_, address coin_) isOpen public {
        require(coinList[coin_], 'wrong coin');
        require(amount_ <= record[msg.sender][coin_], 'out limit');
        IERC20(coin_).transfer(msg.sender, amount_);
        USDB.transferFrom(msg.sender, address(this), amount_);
        record[msg.sender][coin_] -= amount_;
        total -= amount_;
        emit SwapForCoin(msg.sender, coin_, amount_);
    }

    function setLimit(uint com_) public onlyOwner {
        limit = com_;
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function setToken(address UB_) public onlyOwner {
        USDB = IERC20(UB_);
    }

    function addToken(address addr_) public onlyOwner {
        coinList[addr_] = true;
    }

    function deleteToken(address addr_) public onlyOwner {
        coinList[addr_] = false;
    }

    function setStatus(bool com_) public onlyOwner {
        status = com_;
    }
}