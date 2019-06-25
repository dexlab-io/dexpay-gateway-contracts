pragma solidity ^0.5.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/ownership/Ownable.sol";

interface DexI {
    function sell(
        address source, //0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee, // eth token in kyber
        uint srcAmount,
        address dest,
        address recepient
    )
        external
        payable
        returns (uint256 swappedAmount);
    
    function buy(
        address source,
        uint srcAmount,
        address dest,
        address recepient
    )
        external
        payable
        returns (uint256 swappedAmount);
        
    function checkAllowance(address erc20, uint256 amount) external view returns (bool success);
}

contract GlobalVar{
    address public ETHToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public OMGtoken = 0x4BFBa4a8F28755Cb2061c413459EE562c6B9c51b;
    address public DAItoken = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
}

contract Gateway is Ownable, GlobalVar {
    uint256 public serviceFee;
    address payable feeAccount;
    DexI private X;
    mapping(address => mapping(bytes32 => PaymentObj)) public payment;
    
    struct PaymentObj {
        address _payer; 
        address seller;
        address _token;
        uint _amount; 
        bytes32 _data;
        bool isPaid;
    }

    event ProofOfPayment(address indexed _payer, address indexed seller, address _token, uint _amount, bytes32 _data);

    constructor (address Dex) public {
        serviceFee = 0;
        X = DexI(Dex);
        
        IERC20 DAItkn = IERC20(DAItoken);
        DAItkn.approve(Dex, 2**256 - 1);
    }
    
    //=============
    //== Setters
    //=============
    
    function setFee(uint256 fee) public onlyOwner returns (bool success) {
        serviceFee = fee;
        return true;
    }
    
    function setFeeAccount(address payable account) public onlyOwner returns (bool success) {
        feeAccount = account;
        return true;
    }
    
    //=============
    //== Helper Functions
    //=============
    
    function isOrderPaid(address _sellerAddress, string memory _orderId, uint256 amount) public view returns(bool success){
        return payment[_sellerAddress][stringToBytes32(_orderId)].isPaid && 
            payment[_sellerAddress][stringToBytes32(_orderId)]._amount == amount;
    }
    
    function stringToBytes32(string memory source) public view returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function calculateAmountWithFee(uint256 swappedAmount) public view returns (uint256 amount){
        uint256 transferAmount;
        if (serviceFee > 0) {
            uint256 feeToSub = (swappedAmount * serviceFee) / (1 ether);
            transferAmount = swappedAmount - feeToSub;
        } else {
            transferAmount = swappedAmount;
        }
        
        return transferAmount;
    }


    //=============
    //== Gateway Functions
    //=============
    
    /**
     * @dev To avoid exchange just use destToken = 0x0000000000000000000000000000000000000000
     * @param seller is the merchant
     * @param _orderId should have a store prefix, for instance: mystore-1
     * @param amount to be paid
     * @param destToken is the token to exchange to
     */
    function payWithEth(address payable seller, string memory _orderId, uint256 amount, address destToken) public payable returns  (bool success){
        require(seller != address(0), "Seller is an empty address"); 
        require(msg.value > 0 && msg.value == amount, "msg.value doesn not match amount");
        require( isOrderPaid(seller, _orderId, amount) == false, "Order already paid");
        
        uint256 finalAmount = calculateAmountWithFee(amount);

        if(destToken != address(0)) {
            X.buy.value(msg.value)(ETHToken, finalAmount, destToken, seller);
        } else {
            seller.transfer(finalAmount);
        }
        
        bytes32 data = keccak256(abi.encodePacked( seller,_orderId ) );
            
        payment[seller][stringToBytes32(_orderId)] = PaymentObj(msg.sender, seller, ETHToken, amount, data, true);
        emit ProofOfPayment(msg.sender, seller, ETHToken, amount, data);
        return true;
    }
    
    function paymentWithTokenAllowed( address token, uint256 amount ) public view returns (bool res) {
        return X.checkAllowance( token, amount );
    }
    
    
    /**
     * @dev To avoid exchange just use as destToken 0x0000000000000000000000000000000000000000
     * @param seller is the merchant
     * @param _orderId should have a store prefix, for instance: mystore-1
     * @param amount to be paid
     * @param destToken is the token to exchange to
     */
    function payWithToken(address seller, string memory _orderId, uint256 amount, address inputToken, address destToken) public payable returns  (bool success){
      require(seller != address(0), "Seller address in null"); 
      require(inputToken != address(0), "Input Token is null");
      require(paymentWithTokenAllowed(inputToken, amount) == true, "Input Token not allowed");
      require( isOrderPaid(seller, _orderId, amount) == false, "Order already paid");
      
      IERC20 tokenInstance = IERC20(inputToken);
      require(tokenInstance.allowance(msg.sender, address(this)) >= amount, "Allowance required");
      
      uint256 finalAmount = calculateAmountWithFee(amount);
      
      if(destToken != address(0)) {
            require(tokenInstance.transferFrom(msg.sender, address(this), finalAmount), "Transfer to Gateway failed");
            X.sell(inputToken, amount, destToken, seller);
        } else {
            require(tokenInstance.transferFrom(msg.sender, seller, finalAmount), "Transfer failed");
        }
      
      bytes32 data = keccak256(abi.encodePacked( seller,_orderId ) );
          
      payment[seller][stringToBytes32(_orderId)] = PaymentObj(msg.sender, seller, inputToken, amount, data, true);
      emit ProofOfPayment(msg.sender, seller, inputToken, amount, data);
      return true;
    }

    function () external payable {
        revert();
    }
}
