// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";




contract BFLY is ERC20, Ownable {
    using SafeMath for uint;
    using Address for address;
    mapping(address => bool) admin;

    constructor (string memory symbol_, string memory name_) ERC20(name_, symbol_){
        admin[_msgSender()] = true;
        _mint(_msgSender(),200000000 ether);
    }
    function decimals() public view virtual override returns (uint8){
        return 18;
    }

    function mint(address addr_, uint amount_) public onlyAdmin {
        _mint(addr_, amount_);
    }
    modifier onlyAdmin {
        require(admin[_msgSender()],"not damin");
        _;
    }
    function setAdmin(address com_) public onlyOwner{
        require(com_!=address(0),"wrong adress");
        admin[com_] = true;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }
}