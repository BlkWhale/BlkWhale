// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ATE_Exchange is Ownable{
    address public ATE;
    uint public price = 1 ether;
    mapping (address => bool) public tokenList;
    bool public status;

    event Buy(address indexed sender_,address indexed token_,uint amount_);
    function setPrice(uint com_)public onlyOwner{
        price = com_;
    }

    function coutingCost(uint amount_)public view returns(uint){
        return amount_ * 1e18 / price;
    }

    function setAddress(address ATE_,address USDT_,address USDB_ )external onlyOwner{
        ATE = ATE_;
        tokenList[USDT_] = true;
        tokenList[USDB_] = true;
    }

    function addToken(address token_,bool com_) external onlyOwner{
        tokenList[token_] = com_;
    }

    function setStatus(bool com_) external onlyOwner{
        status = com_;
    }

    function buy(uint amount_,address token_) external {
        require(status,'not open');
        require(tokenList[token_],'wrong token');
        uint temp = coutingCost(amount_);
        IERC20(token_).transferFrom(_msgSender(),address(this),amount_);
        IERC20(ATE).transfer(_msgSender(),temp);
        emit Buy(_msgSender(),token_,temp);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

}