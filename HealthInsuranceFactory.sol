// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <=0.8.11;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./ERC20.sol";
import "./BasicOps.sol";

//contract for the insurance company
contract HealthInsuranceFactory is BasicOperations{

    //instance of token contract
    ERC20Basic private token;

    constructor(){
        token = new ERC20Basic(100);
        Insurance = address(this);
        Carrier = msg.sender;
    }

    //addresses declaration
    address Insurance;
    address payable public Carrier;

    address[] InsuredAddresses;

    


}