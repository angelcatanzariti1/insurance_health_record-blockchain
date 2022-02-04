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

    //structures
    constructor(){
        token = new ERC20Basic(100);
        Insurance = address(this);
        Carrier = msg.sender;
    }

    struct client{
        address ClientAddress;
        bool ClientAuthorization;
        address ContractAddress;
    }

    struct service{
        string ServiceName;
        uint256 ServiceTokenPrice;
        bool ServiceStatus;
    }

    struct lab{
        address LabContractAddress;
        bool LabValidation;
    }

    //addresses declaration
    address Insurance;
    address payable public Carrier;

    //mappings for clients, services and labs
    mapping(address => client) public MappingClients;
    mapping(string => service) public MappingServices;
    mapping(address => lab) public MappingLabs;
    
    //arrays for clients, services and labs
    string[] private ServicesNames;
    address[] LabsAddresses;
    address[] ClientsAddresses;

    
    //modifiers and restrictions on clients and carriers
    function FuncOnliClients(address _clientAddress) public view{
        require(MappingClients[_clientAddress].ClientAuthorization == true, "Client address not authorized.");
    }
    modifier ModOnlyClients(address _clientAddress){
        FuncOnliClients(_clientAddress);
        _;
    }

    function FuncOnlyCarriers(address _carrierAddress) public view{
        require(Carrier == _carrierAddress, "Carrier address not authorized.");
    }
    modifier ModOnlyCarriers(address _carrierAddress){
        FuncOnlyCarriers(_carrierAddress);
        _;
    }

    modifier ModClientOrCarrier(address _clientAddress, address _enteredAddress){
        require((MappingClients[_clientAddress].ClientAuthorization == true && _clientAddress == _enteredAddress) || Carrier == _enteredAddress,
        "Only clients or carriers allowed.");
        _;
    }

    //events
    event EventTokenBought(uint256);
    event EventServiceProvided(address, string, uint256);
    event EventLabCreated(address, address);
    event EventClientCreated(address, address);
    event EventClientDeleted(address);
    event EventServiceCreated(string, uint256);
    event EventServiceDeleted(string);

    



}