// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <=0.8.11;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./ERC20.sol";
import "./BasicOps.sol";

//Contract for the insurance company
contract InsuranceFactory is BasicOperations{

    //Addresses declarations
    address Insurance;
    address payable public Carrier;
    

    //Instance of token contract
    ERC20Basic private token;

    //Constructor
    constructor(){
        token = new ERC20Basic(100);
        Insurance = address(this);
        Carrier = msg.sender;
    }

    //Data structures
    struct insured{
        address insuredAddress;
        bool insuredAuthorized;
        address insuredContractAddress;
    }

    struct service{
        string serviceName;
        uint servicePriceInTokens;
        bool serviceStatus;
    }

    struct lab{
        address labContractAddress;
        bool labAuthorized;        
    }

    //Mappings and arrays for insured, services and labs
    mapping(address => insured) public MappingInsured;
    mapping(string => service) public MappingServices;
    mapping(address => lab) public MappingLabs;

    address[] InsuredAddresses;
    string[] private serviceNames;
    address[] labAddresses;
    

    
}
