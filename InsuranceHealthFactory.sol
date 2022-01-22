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

    //Modifiers (through function) and restrictions for insured and carriers
    function CheckOnlyInsured(address _insuredAddress) public view{
        require(MappingInsured[_insuredAddress].insuredAuthorized, "Insured not authorized.");
    }
        
    modifier OnlyInsured(address _insuredAddress){
        CheckOnlyInsured(_insuredAddress);
        _;
    }

    modifier OnlyCarrier(address _carrierAddress){
        require(Carrier == _carrierAddress, "Carrier address not authorized.");
        _;
    }

    modifier OnlyInsuredOrCarrier(address _insuredAddress, address _inputAddress){
        require((MappingInsured[_inputAddress].insuredAuthorized) && (_insuredAddress == _inputAddress) || Carrier == _inputAddress,
        "Only carriers or insured are allowed.");
        _;
    }

    //Events
    event eventTokenBuy(uint256);
    event eventLabCreate(address, address);
    event eventInsuredCreate(address, address);
    event eventInsuredDelete(address);
    event eventServiceCreate(string, uint256);
    event eventServiceProvide(address, string);
    event eventServiceDelete(string);

    //New contract for a lab
    function createLab() public{
        labAddresses.push(msg.sender);
        address labAdd = address(new LabContract(msg.sender, Insurance));
        lab memory laboratory = lab(labAdd, true);
        MappingLabs[msg.sender] = laboratory;

        emit eventLabCreate(msg.sender, labAdd);
    }



    

    
}


contract LabContract is BasicOperations{

    address public LabAddress;
    address CarrierContract;
    
    constructor(address _account, address _carrierContractAddress){
        LabAddress = _account;
        CarrierContract = _carrierContractAddress;
    }
}