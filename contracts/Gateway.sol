pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";
import "./DexI.sol";

contract Gateway is Initializable, Ownable {
    uint256 public serviceFee;
    DexI private X;
    mapping(address => mapping(uint => PaymentObj)) public payment;
    
    struct PaymentObj {
        address _payer; 
        address seller;
        address _token;
        uint _amount; 
        bytes32 _data;
        bool isPaid;
    }

    event ProofOfPayment(address indexed _payer, address indexed seller, address _token, uint _amount, bytes32 _data);

    function initialize(address Dex) public initializer {
        serviceFee = 0;
        X = DexI(Dex);
    }

    function isOrderPaid(address _sellerAddress, uint _orderId, uint256 amount, address token) public view returns(bool success){
        return payment[_sellerAddress][_orderId].isPaid && 
            payment[_sellerAddress][_orderId]._amount == amount &&
            payment[_sellerAddress][_orderId]._token == token;
    }

    function setFee(uint256 fee) public onlyOwner returns (bool success) {
        serviceFee = fee;
        return true;
    }

    function () external payable {

    }
}
