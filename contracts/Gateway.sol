pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/token/ERC20/IERC20.sol";
// import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

contract Gateway is Initializable {
    address private _owner;
    uint256 public x;

    function initialize(uint256 _x) public initializer {
        _owner = msg.sender;
        x = _x;
    }

    function increment() public {
        x += 1;
    }
}
