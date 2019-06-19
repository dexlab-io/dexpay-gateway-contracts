pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";
import './KyberNetworkI.sol';
import './GlobalVar.sol';

contract Dex is Initializable, Ownable, GlobalVar {
    uint256 public serviceFee;
    KyberNetworkI private kyberExchange;

    function initialize() public initializer {
        serviceFee = 0;
        kyberExchange = KyberNetworkI(KyberAddress);

        //Preapprove Tokens
        // IERC20 OMGtkn = IERC20(OMGtoken);
        // OMGtkn.approve(KyberAddress, 2**256 - 1);
        
        // IERC20 KNCtkn = IERC20(KNCtoken);
        // KNCtkn.approve(KyberAddress, 2**256 - 1);
        
        // IERC20 BATtkn = IERC20(BATtoken);
        // BATtkn.approve(KyberAddress, 2**256 - 1);
        
        // IERC20 DAItkn = IERC20(DAItoken);
        // DAItkn.approve(KyberAddress, 2**256 - 1);
    }

    function approve(IERC20 erc20, address spender, uint tokens) public onlyOwner returns (bool success) {
        require(erc20.approve(spender, tokens), "Token Aprove aborted");
        return true;
    }

    function withdraw() public onlyOwner returns (bool success) {
        require(address(this).balance > 0, "Balance is zero");
        msg.sender.transfer(address(this).balance);
        return true;
    }

    function withdrawTokens(IERC20 token) public onlyOwner returns (bool success) {
        uint256 balance = token.balanceOf(address(this));

        // Double checking
        require(balance > 0, "Balance is zero");
        require(token.transfer(msg.sender, balance), "Token transfer aborted");
        return true;
    }

    /**
        * Instant super simple trading with kyber
        * dest is the only parameter, it represent the token to buy
        * because of minConversionRate=1, trade will execute according to market price in the time of the transaction confirmation.
        * walletId is null here

        Usecases:

        Send ETH from any wallet to omg.gdepprotocol.eth to convert the ETH to OMG through a fallback function. This could use a relayer broker contract to inject minimum values and prevent frontrunning.
        Converting OMG to ETH by sending OMG to omg.uniswap.eth, and converting OMG to KNC by sending OMG to knc.uniswap.eth could be done using a trusted system of off-chain event watchers.
        Send ETH from any wallet to OMG.alexintoth.gdepprotocol.eth to convert that ETH to OMG and transfer it to alexintoth.
    */
    function tradeKyber(
        address source, //0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee, // eth token in kyber
        uint srcAmount,
        address dest,
        address recepient
    )
        public
        payable
        returns (uint256 swappedAmount)
    {
        
        /**
        * If we are receiving ether, than 
        */
        uint amountToSend;
        if (source == ETHToken) {
            amountToSend = msg.value;
        } else {
            /*
            * It's not ether, we need to transfer the token from the user to this contract
            * This will assume the user has called approve(source) with this contract address
            * Otherwise function will trow
            */
            amountToSend = srcAmount;
            IERC20 tokenFunctions = IERC20(source);
            //TODO add require
            tokenFunctions.transferFrom(msg.sender, address(this), amountToSend);
        }
        
        
        uint256 actualDestAmount = kyberExchange.trade.value(amountToSend)(
            source, // eth token in kyber
            amountToSend, //amount of tokens to convert. If sending ETH must be equal to msg.value. Otherwise, must not be higher than user token allowance to kyber network contract address.
            dest, 
            address(this),
            2**256 - 1, //maxDestAmount: maximum destination amount. The actual converted amount will be the minimum of srcAmount and required amount to get maxDestAmount of dest tokens. For an exchange application, we recommend to set it to MAX_UINT (i.e., 2**256 - 1).
            1, //minConversionRate: the minimal conversion rate. If the current rate is too high, then the transaction is reverted. For an exchange application this value can be set according to the priceSlippage return value of getExpectedRate. However, in this case, the execution of the transaction is not guaranteed in case big changes in market price happens before the confirmation of the transaction. A value of 1 will execute the trade according to market price in the time of the transaction confirmation.
            0x398d297BAB517770feC4d8Bb7a4127b486c244bB
        );
        
        
        /**
        * Fee calculation
        */
        uint256 transferAmount;
        if (serviceFee > 0) {
            uint256 feeToSub = (actualDestAmount * serviceFee) / (1 ether);

            transferAmount = actualDestAmount - feeToSub;
        }
        else {
            transferAmount = actualDestAmount;
        }
        
        address deliverTo;
        if( recepient == address(0) ) {
            deliverTo = msg.sender;
        } else {
            deliverTo = recepient;
        }

        /**
        * Tokens are send back to the users
        */
        require(IERC20(dest).transfer(deliverTo, transferAmount));
        return transferAmount;
    }

}