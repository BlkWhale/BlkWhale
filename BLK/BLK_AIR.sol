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

contract BLKairDrop is Ownable {
    IERC20 public BLK;
    IERC20 public token;
    uint public amount = 50 * 1e18;
    uint public quota;
    uint public quota2;
    bool public status;
    bool public useToken;

    struct UserInfo {
        string mail;
        string twLink;
        string YouTuLink;
    }

    mapping(address => bool) public userStatus;
    mapping(address => UserInfo) public userInfo;

    event Claim(address indexed addr_, string indexed input1, string indexed input2, string input3);


    function setBlk(address com_) public onlyOwner {
        BLK = IERC20(com_);
    }

    function setAmount(uint com_) public onlyOwner {
        amount = com_;
    }

    function setStatus(bool com_) public onlyOwner {
        status = com_;
    }

    function setQuota(uint com_) public onlyOwner {
        quota = com_;

    }

    function usingToken(address com_, uint quota_) public onlyOwner {
        token = IERC20(com_);
        quota2 = quota_;
    }

    function useingToken(bool com_) public onlyOwner {
        useToken = com_;
    }

    function claim(string memory input1, string memory input2, string memory input3) public {
        if (useToken) {
            require(token.balanceOf(msg.sender) >= quota2, 'too low token');
        }
        require(!userStatus[msg.sender], 'been claimed');
        require(status, 'not open');
        require(msg.sender.balance >= quota, 'BNB too low');
        BLK.transfer(msg.sender, amount);
        userStatus[msg.sender] = true;
        userInfo[msg.sender].mail = input1;
        userInfo[msg.sender].twLink = input2;
        userInfo[msg.sender].YouTuLink = input3;
        emit Claim(msg.sender, input1, input2, input3);
    }

    function safePull(address addr_) public onlyOwner {
        BLK.transfer(addr_, BLK.balanceOf(address(this)));
    }
}