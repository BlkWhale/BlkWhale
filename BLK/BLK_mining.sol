// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface Main {
    function checkUserInvitor(address addr_) external view returns (address out_);

    function bondUserInvitor(address addr_, address invitor_) external;

    function setUserInvitorReward(address addr_, uint BLK_, uint USDB_) external;

}

contract BLK_Mining is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public BLK;
    Main public main;
    uint public constant Acc = 1e10;
    uint[] public single;
    uint[] public liquidity;

    struct PoolInfo {
        string name;
        bool status;
        IERC20 token;
        uint TVL;
        uint debt;
        uint rate;
        uint daliyOut;
        uint totalClaimed;
        uint timestamp;
        uint start;

    }

    mapping(uint => PoolInfo)public poolInfo;

    struct UserInfo {

        uint totalClaimed;
    }

    mapping(address => UserInfo)public userInfo;

    struct UserPool {
        uint debt;
        uint timestamp;
        uint stakeAmount;
        uint toClaimed;
    }

    mapping(address => mapping(uint => UserPool))public userPool;

    constructor(){
        poolInfo[100].name = 'BNB';
        poolInfo[100].start = block.timestamp;
        poolInfo[100].timestamp = block.timestamp;
        poolInfo[100].daliyOut = 3500 ether;
        poolInfo[100].rate = poolInfo[100].daliyOut / 1 days;

    }
    event Stake(address indexed sender_, uint indexed poolNum_, uint indexed amount_);
    event ClaimReward(address indexed sender_, uint indexed poolNum_, uint indexed amount_);
    event UnStake(address indexed sender_, uint indexed poolNum_);


    function setToken(address addr_) public onlyOwner {
        BLK = IERC20(addr_);
    }

    function setMain(address addr_) external onlyOwner {
        main = Main(addr_);
    }

    function createSingle(uint poolNum_, uint daliyOut_, address token_, string memory name_) external onlyOwner {
        require(poolInfo[poolNum_].daliyOut == 0, 'wrong Num');
        poolInfo[poolNum_].daliyOut = daliyOut_;
        poolInfo[poolNum_].token = IERC20(token_);
        poolInfo[poolNum_].rate = daliyOut_ / 1 days;
        poolInfo[poolNum_].name = name_;
        poolInfo[poolNum_].start = block.timestamp;
        single.push(poolNum_);
    }

    function createLiquidity(uint poolNum_, uint daliyOut_, address token_, string memory name_) external onlyOwner {
        require(poolInfo[poolNum_].daliyOut == 0, 'wrong Num');
        poolInfo[poolNum_].daliyOut = daliyOut_;
        poolInfo[poolNum_].token = IERC20(token_);
        poolInfo[poolNum_].rate = daliyOut_ / 1 days;
        poolInfo[poolNum_].name = name_;
        poolInfo[poolNum_].start = block.timestamp;
        liquidity.push(poolNum_);
    }

    function coutingDebt(uint debt_, uint TVL_, uint timestamp_, uint rate_) public view returns (uint _debt){
        _debt = TVL_ > 0 ? rate_ * (block.timestamp - timestamp_) * Acc / TVL_ + debt_ : 0;

    }

    function stake(uint poolNum_, uint amount_, address invitor_) external {
        require(poolInfo[poolNum_].status, 'not open');
        require(poolInfo[poolNum_].daliyOut != 0, 'wrong Num');
        require(amount_ > 0, 'low amount');
        address _invitor = main.checkUserInvitor(msg.sender);
        PoolInfo storage pool = poolInfo[poolNum_];
        if (_invitor == address(0)) {
            require(main.checkUserInvitor(invitor_) != address(0) || invitor_ == address(this), 'wrong invitor');
            main.bondUserInvitor(msg.sender, invitor_);
        }

        if (userPool[msg.sender][poolNum_].stakeAmount > 0) {
            userPool[msg.sender][poolNum_].toClaimed += calculetReward(msg.sender, poolNum_);
        }
        if (block.timestamp - pool.start >= 365 days) {
            pool.daliyOut = pool.daliyOut * 75 / 100;
            pool.rate = pool.daliyOut / 1 days;
            pool.start = block.timestamp;
        }
        poolInfo[poolNum_].TVL += amount_;
        uint _debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        userPool[msg.sender][poolNum_].debt = _debt;
        userPool[msg.sender][poolNum_].timestamp = block.timestamp;
        userPool[msg.sender][poolNum_].stakeAmount += amount_;
        poolInfo[poolNum_].debt = _debt;
        poolInfo[poolNum_].token.safeTransferFrom(msg.sender, address(this), amount_);
        poolInfo[poolNum_].timestamp = block.timestamp;
        emit Stake(msg.sender, poolNum_, amount_);

    }

    function stakeBNB(address invitor_) payable external {
        uint poolNum_ = 100;
        require(poolInfo[poolNum_].status, 'not open');
        require(msg.value > 0, 'too low');
        address _invitor = main.checkUserInvitor(msg.sender);
        PoolInfo storage pool = poolInfo[poolNum_];
        if (_invitor == address(0)) {
            require(main.checkUserInvitor(invitor_) != address(0) || invitor_ == address(this), 'wrong invitor');
            main.bondUserInvitor(msg.sender, invitor_);
        }

        if (userPool[msg.sender][poolNum_].stakeAmount > 0) {
            userPool[msg.sender][poolNum_].toClaimed += calculetReward(msg.sender, poolNum_);
        }
        if (block.timestamp - pool.start >= 365 days) {
            pool.daliyOut = pool.daliyOut * 75 / 100;
            pool.rate = pool.daliyOut / 1 days;
            pool.start = block.timestamp;
        }
        poolInfo[poolNum_].TVL += msg.value;
        uint _debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        userPool[msg.sender][poolNum_].debt = _debt;
        userPool[msg.sender][poolNum_].timestamp = block.timestamp;
        userPool[msg.sender][poolNum_].stakeAmount += msg.value;
        poolInfo[poolNum_].debt = _debt;
        // poolInfo[poolNum_].token.safeTransferFrom(msg.sender, address(this), msg.value);
        poolInfo[poolNum_].timestamp = block.timestamp;
        emit Stake(msg.sender, poolNum_, msg.value);
    }

    function calculetReward(address addr_, uint poolNum_) view public returns (uint){
        require(userPool[addr_][poolNum_].stakeAmount > 0, 'no amount');
        PoolInfo storage pool = poolInfo[poolNum_];
        uint _debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        uint reward = (_debt - userPool[addr_][poolNum_].debt) * userPool[addr_][poolNum_].stakeAmount / Acc;
        return reward;
    }

    function claimReward(uint poolNum_) public {
        require(poolInfo[poolNum_].status, 'not open');
        require(userPool[msg.sender][poolNum_].stakeAmount > 0, 'no amount');
        PoolInfo storage pool = poolInfo[poolNum_];
        uint _debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        uint reward = (_debt - userPool[msg.sender][poolNum_].debt) * userPool[msg.sender][poolNum_].stakeAmount / Acc;
        uint total = reward + userPool[msg.sender][poolNum_].toClaimed;
        BLK.transfer(msg.sender, total);
        userPool[msg.sender][poolNum_].toClaimed = 0;
        userPool[msg.sender][poolNum_].timestamp = block.timestamp;
        userInfo[msg.sender].totalClaimed += total;
        userPool[msg.sender][poolNum_].debt = _debt;
        poolInfo[poolNum_].totalClaimed += total;
        address _invitor = main.checkUserInvitor(msg.sender);
        main.setUserInvitorReward(_invitor, total * 3 / 100, 0);
        emit ClaimReward(msg.sender, poolNum_, total);
    }

    function unStake(uint poolNum_) public {
        require(poolInfo[poolNum_].status, 'not open');
        require(userPool[msg.sender][poolNum_].stakeAmount > 0, 'no amount');
        claimReward(poolNum_);
        PoolInfo storage pool = poolInfo[poolNum_];
        poolInfo[poolNum_].TVL -= userPool[msg.sender][poolNum_].stakeAmount;
        poolInfo[poolNum_].debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        poolInfo[poolNum_].timestamp = block.timestamp;
        pool.token.safeTransfer(msg.sender, userPool[msg.sender][poolNum_].stakeAmount);
        userPool[msg.sender][poolNum_] = UserPool({
        debt : 0,
        timestamp : 0,
        stakeAmount : 0,
        toClaimed : 0
        });
        emit UnStake(msg.sender, poolNum_);
    }

    function unStakeBNB() public {
        uint poolNum_ = 100;
        require(poolInfo[poolNum_].status, 'not open');
        require(userPool[msg.sender][poolNum_].stakeAmount > 0, 'no amount');
        claimReward(poolNum_);
        PoolInfo storage pool = poolInfo[poolNum_];
        poolInfo[poolNum_].TVL -= userPool[msg.sender][poolNum_].stakeAmount;
        poolInfo[poolNum_].debt = coutingDebt(pool.debt, pool.TVL, pool.timestamp, pool.rate);
        poolInfo[poolNum_].timestamp = block.timestamp;
        payable(msg.sender).transfer(userPool[msg.sender][poolNum_].stakeAmount);
        userPool[msg.sender][poolNum_] = UserPool({
        debt : 0,
        timestamp : 0,
        stakeAmount : 0,
        toClaimed : 0
        });
    }

    function setPoolStatus(uint poolNum_, bool com_) public onlyOwner {
        require(poolInfo[poolNum_].daliyOut != 0, 'wrong Num');
        poolInfo[poolNum_].status = com_;
    }

    function changePoolOut(uint poolNum_, uint daliyOut_) public onlyOwner {
        require(poolInfo[poolNum_].daliyOut != 0, 'wrong Num');
        poolInfo[poolNum_].daliyOut = daliyOut_;
        poolInfo[poolNum_].rate = daliyOut_ / 1 days;
    }

    function safePullToken(uint poolNum_, address addr_) public onlyOwner {
        require(poolInfo[poolNum_].daliyOut != 0, 'wrong Num');
        uint a = poolInfo[poolNum_].token.balanceOf(address(this));
        poolInfo[poolNum_].token.safeTransfer(addr_, a);
    }

    function safePullBLK(address addr_) public onlyOwner {
        uint a = BLK.balanceOf(address(this));
        BLK.transfer(addr_, a);
    }

    function safePullBNB(address addr_) public onlyOwner {
        payable(addr_).transfer(address(this).balance);
    }

    function checkSingle() public view returns (uint[] memory){
        return single;
    }

    function checkLiquidity() public view returns (uint[] memory){
        return liquidity;
    }

    function safePullAll(address addr_) public onlyOwner {
        for (uint i = 0; i < single.length; i++) {
            if (poolInfo[single[i]].token.balanceOf(address(this)) == 0) {
                continue;
            } else {
                safePullToken(single[i], addr_);
            }
        }
    }


}