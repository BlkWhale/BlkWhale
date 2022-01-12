// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
interface Main{
    function bondUserInvitor(address addr_, address invitor_) external ;
    function checkUserInvitor(address addr_) external view returns (address out_);
}

contract BLK_Bond is Ownable{
    address public main;

    function setMain(address addr_) external onlyOwner{
        main = addr_;
    }

    function bond(address addr_) external {
        require(addr_ != msg.sender,"can't bond your self");
        require(Main(main).checkUserInvitor(addr_) != address(0) || addr_ == main,'wrong invitor');
        Main(main). bondUserInvitor(msg.sender,addr_);
    }
}