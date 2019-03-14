pragma solidity ^0.5.0;

import "zos-lib/contracts/Initializable.sol";

contract GlobalVar is Initializable{
    /**
    * Address Exchanges
    */
    address public KyberAddress; // = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755KN Proxy, same for ropsten and mainnet
    
    address public ETHToken; // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public OMGtoken; // 0x4BFBa4a8F28755Cb2061c413459EE562c6B9c51b;
    address public DAItoken; // 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    address public BATtoken; // 0xDb0040451F373949A4Be60dcd7b6B8D6E42658B6;
    address public KNCtoken; // 0x4E470dc7321E84CA96FcAEDD0C8aBCebbAEB68C6;

    function initialize(address _KyberAddress, address _OMGtoken, address _DAItoken, address _BATtoken, address _KNCtoken) public initializer {
        KyberAddress = _KyberAddress; // KN Proxy, same for ropsten and mainnet
        ETHToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        OMGtoken = _OMGtoken;
        DAItoken = _DAItoken;
        BATtoken = _BATtoken;
        KNCtoken = _KNCtoken;
    }
}