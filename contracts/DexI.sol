pragma solidity ^0.5.0;

interface DexI {
    function tradeKyber( 
        address source,
        uint srcAmount,
        address dest,
        address recepient
    )
        external
        payable
        returns(uint);
}