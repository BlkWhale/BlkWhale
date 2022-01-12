// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BLK_IDO is Ownable {
    IERC20 public Token;
    uint acc = 1e10;
    uint totalTime = 240 days;
    uint poudage = 450;

    struct UserInfo {
        uint counting;
        uint total;
        uint timestamp;
        uint endTime;
        uint rate;
        uint claimed;

    }

    mapping(address => UserInfo) public userInfo;

    event ClaimIDO(address indexed addr_, uint claimamount_);

    function setToken(address com_) public onlyOwner {
        Token = IERC20(com_);
    }

    function setAmount(address addr_, uint amount_) public onlyOwner {
        userInfo[addr_].total = amount_;
    }

    function setPoudage(uint com_) public onlyOwner {
        poudage = com_;
    }

    function countingClaim(address addr_) public view returns (uint)  {
        //        require(userInfo[addr_].total != 0, 'no amonut');
        //        require(userInfo[msg.sender].claimed < userInfo[msg.sender].total, 'claim over');
        if (userInfo[addr_].total == 0) {
            return 0;
        }
        uint out;
        if (userInfo[msg.sender].counting == 0) {
            return userInfo[msg.sender].total * 2 / 10;
        }
        if (block.timestamp < userInfo[addr_].endTime) {
            out = userInfo[addr_].rate * (block.timestamp - userInfo[addr_].timestamp) / acc;

        } else {
            out = userInfo[addr_].rate * (userInfo[addr_].endTime - userInfo[addr_].timestamp) / acc;

        }
        return out;

    }

    function display(address addr_) public view returns (uint){
        return countingClaim(addr_) * (10000 - poudage) / 10000;
    }

    function checkUserAmount(address addr_) public view returns (uint){
        return userInfo[addr_].total;
    }

    function claimIDO() public {
        require(userInfo[msg.sender].total != 0, 'no amonut');
        require(userInfo[msg.sender].claimed < userInfo[msg.sender].total, 'claim over');
        uint temp;
        if (userInfo[msg.sender].counting == 0) {
            temp = userInfo[msg.sender].total * 2 / 10;
            Token.transfer(msg.sender, temp * (10000 - poudage) / 10000);
            userInfo[msg.sender].claimed += userInfo[msg.sender].total * 2 / 10;
            userInfo[msg.sender].counting++;
            userInfo[msg.sender].timestamp = block.timestamp;
            userInfo[msg.sender].rate = userInfo[msg.sender].total * acc * 8 / 10 / totalTime;
            userInfo[msg.sender].endTime = block.timestamp + totalTime;
        } else {
            temp = countingClaim(msg.sender);
            userInfo[msg.sender].claimed += temp;
            Token.transfer(msg.sender, temp);
            userInfo[msg.sender].timestamp = block.timestamp;

        }
        emit ClaimIDO(msg.sender, temp);

    }

    function claimLeftToken(address addr_) public onlyOwner {
        uint temp = Token.balanceOf(address(this));
        Token.transfer(addr_, temp);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

}