// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";





interface IQuota {
    function getUserQuota(address user) external view returns (int);
}

contract UserQuota is Ownable, IQuota {

    mapping(address => uint256) public userQuota;
    uint256 constant quota = 500 ether; //For example 375u on eth

    function setUserQuota(address[] memory users) external onlyOwner {

        for(uint256 i = 0; i< users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quota;
        }
    }

    function getUserQuota(address user) override external view returns (int) {
        return int(userQuota[user]);
    }
}