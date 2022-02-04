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

    //functions
    function LabCreation() public{
        LabsAddresses.push(msg.sender);
        address labAddress = address(new Lab(msg.sender, Insurance));
        MappingLabs[msg.sender] = lab(labAddress, true);
        emit EventLabCreated(msg.sender, labAddress);
    }

    function ClientCreation() public{
        ClientsAddresses.push(msg.sender);
        address clientAddress = address(new HealthInsuranceRecord(msg.sender, token, Insurance, Carrier));
        MappingClients[msg.sender] = client(msg.sender, true, clientAddress);
        emit EventClientCreated(msg.sender, clientAddress);
    }

}

contract Lab is BasicOperations{

    address public LabAddress;
    address carrierContract;
    
    //constructor
    constructor(address _account, address _carrierContract){
        LabAddress = _account;
        carrierContract = _carrierContract;
    }
}

contract HealthInsuranceRecord is BasicOperations{

    enum Status{yes,no}
    
    struct Owner{
        address ownerAddress;
        uint ownerBalance;
        Status status;
        IERC20 tokens;
        address insurance;
        address payable carrier;
    }

    Owner owner;

    //constructor
    constructor(address _owner, IERC20 _token, address _insurance, address payable _carrier){
        owner.ownerAddress = _owner;
        owner.ownerBalance = 0;
        owner.status = Status.yes;
        owner.tokens = _token;
        owner.insurance = _insurance;
        owner.carrier = _carrier;
    }

}