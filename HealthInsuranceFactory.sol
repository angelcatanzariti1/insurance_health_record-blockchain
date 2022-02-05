// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <=0.8.11;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./ERC20.sol";
import "./BasicOps.sol";

//contract for the insurance company
//-----------------------------------------------------------------------------------------------------------------
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

    function Laboratories() public view ModOnlyCarriers(msg.sender) returns(address[] memory){
        return LabsAddresses;
    }

    function Clients() public view ModOnlyCarriers(msg.sender) returns(address[] memory){
        return ClientsAddresses;
    }

    function viewClientHistory(address _clientAddress, address _consultantAddress) public view ModClientOrCarrier(_clientAddress, _consultantAddress) returns(string memory){
        string memory history = "";
        address clientContract = MappingClients[_clientAddress].ContractAddress;

        for(uint i = 0; i < ServicesNames.length; i++){
            if(MappingServices[ServicesNames[i]].ServiceStatus && HealthInsuranceRecord(clientContract).viewClientServiceStatus(ServicesNames[i])){
                (string memory serviceName, uint servicePrice) = HealthInsuranceRecord(clientContract).viewClientHistory(ServicesNames[i]);
                history = string(abi.encodePacked(history, "(", serviceName, ", ", uint2str(servicePrice), ") ------"));
            } 
        }

        return history;
    }

    function deleteClient(address _clientAddress) public ModOnlyCarriers(msg.sender){
        MappingClients[_clientAddress].ClientAuthorization = false;
        HealthInsuranceRecord(MappingClients[_clientAddress].ContractAddress).DeleteClient;
        emit EventClientDeleted(_clientAddress);
    }

    function newService(string memory _serviceName, uint256 _servicePrice) public ModOnlyCarriers(msg.sender){
        MappingServices[_serviceName] = service(_serviceName, _servicePrice, true);
        ServicesNames.push(_serviceName);
        emit EventServiceCreated(_serviceName, _servicePrice);

    }

    function deleteService(string memory _serviceName) public ModOnlyCarriers(msg.sender){
        require(serviceStatus(_serviceName) == true, "Service doesn't exist.");
        MappingServices[_serviceName]. ServiceStatus = false;
        emit EventServiceDeleted(_serviceName);        
    }

    function serviceStatus(string memory _serviceName) public view returns(bool){
        return MappingServices[_serviceName].ServiceStatus;
    }

    function getServicePrice(string memory _serviceName) public view returns(uint256 tokens){
        require(serviceStatus(_serviceName) == true, "Service doesn't exist.");
        return MappingServices[_serviceName].ServiceTokenPrice;
    }

    function getActiveServices() public view returns(string[] memory){
        string[] memory activeServices = new string[](ServicesNames.length);
        uint counter = 0;
        for(uint i = 0; i < ServicesNames.length; i++){
            if(serviceStatus(ServicesNames[i])){
                activeServices[counter] = ServicesNames[i];
                counter++;
            }
        }
        return activeServices;
    }

    /*
    ------------------------------------------------------
    ----------------------- TOKENS -----------------------
    ------------------------------------------------------
    */

    function buyTokens(address _client, uint _numTokens) public payable ModOnlyClients(_client){
        uint256 balance = balanceOf();
        require(_numTokens <= balance, "Buy a lower amount of tokens.");
        require(_numTokens > 0, "Number of tokens to buy must be > 0.");

        token.transfer(msg.sender, _numTokens);

        emit EventTokenBought(_numTokens);
    }

    function balanceOf() public view returns(uint256 tokens){
        return (token.balanceOf(Insurance));
    }

    function generateTokens(uint _numTokens) public ModOnlyCarriers(msg.sender){
        token.increaseTotalSuply(_numTokens);
    }




}

//contract for labs
//-----------------------------------------------------------------------------------------------------------------
contract Lab is BasicOperations{

    address public LabAddress;
    address carrierContract;

    //constructor
    constructor(address _account, address _carrierContract){
        LabAddress = _account;
        carrierContract = _carrierContract;
    }

    mapping(address => string) public MappingServicesRequested;
    
    //service request to labs
    address[] public ServiceRequests;

    struct resultsServices{
        string diagnosis;
        string IPFS_code;
    }
    mapping(address => resultsServices) MappingResultsServicesLab;

    //lab services
    string[] labServicesNames;

    struct labServices{
        string LabServiceName;
        uint LabServicePrice;
        bool LabServiceStatus;

    }
    mapping(string => labServices) public MappingLabServices;

    event EventServiceLabStatus(string, uint);
    event EventServiceLabProvide(address, string);
    
    modifier ModLabOnly(address _address){
        require(_address == LabAddress, "Not allowed.");
        _;
    }

    function createLabService(string memory _serviceName, uint _price) public ModLabOnly(msg.sender){
        MappingLabServices[_serviceName] = labServices(_serviceName, _price, true);
        labServicesNames.push(_serviceName);
        emit EventServiceLabStatus(_serviceName, _price);
    }

    function getLabServices() public view returns(string[]memory){
        return(labServicesNames);
    }

    function getServicePrice(string memory _serviceName) public view returns(uint256){
        return MappingLabServices[_serviceName].LabServicePrice;
    }

    function provideService(address _client, string memory _serviceName) public{
        HealthInsuranceFactory IF = HealthInsuranceFactory(carrierContract);
        IF.FuncOnliClients(_client);
        require(MappingLabServices[_serviceName].LabServiceStatus);
        MappingServicesRequested[_client] = _serviceName;
        ServiceRequests.push(_client);
        emit EventServiceLabProvide(_client, _serviceName);
    }

    function loadResults(address _clientAddress, string memory _diagnosis, string memory _IPFScode) public ModLabOnly(msg.sender){
        MappingResultsServicesLab[_clientAddress] = resultsServices(_diagnosis, _IPFScode);
    }

    function getResults(address _clientAddress) public view returns(string memory _diagnosis, string memory _IPFScode){
        _diagnosis = MappingResultsServicesLab[_clientAddress].diagnosis;
        _IPFScode = MappingResultsServicesLab[_clientAddress].IPFS_code;
        return(_diagnosis, _IPFScode);
    }
}

//contract for clients' record
//-----------------------------------------------------------------------------------------------------------------
contract HealthInsuranceRecord is BasicOperations{

    enum status{yes,no}
    
    struct ownerData{
        address ownerAddress;
        uint ownerBalance;
        status ownerStatus;
        IERC20 tokens;
        address insurance;
        address payable carrier;
    }

    ownerData owner;

    //services requested by clients
    struct requestedServices{
        string serviceName;
        uint256 servicePrice;
        bool serviceStatus;
    }

    //services assigned to a lab
    struct requestedServicesLab{
        string serviceName;
        uint256 servicePrice;
        address labAddress;
    }

    //mappings
    mapping(string => requestedServices) MappingClientHistory;
    requestedServicesLab[] ClientsLabHistory;

    //constructor
    constructor(address _owner, IERC20 _token, address _insurance, address payable _carrier){
        owner.ownerAddress = _owner;
        owner.ownerBalance = 0;
        owner.ownerStatus = status.yes;
        owner.tokens = _token;
        owner.insurance = _insurance;
        owner.carrier = _carrier;
    }

    event EventSelfDestruct(address);
    event EventReturnTokens(address, uint256);
    event EventServicePayed(address, string, uint256);
    event EventServiceRequestToLab(address, address, string);

    modifier ModOwnerOnly(address _address){
        require(_address == owner.ownerAddress, "You need to be the insurance owner!.");
        _;
    }

    function viewClientsLabHistory() public view returns(requestedServicesLab[] memory){
        return ClientsLabHistory;
    }

    function viewClientHistory(string memory _service) public view returns(string memory serviceName, uint servicePrice){
        return (MappingClientHistory[_service].serviceName, MappingClientHistory[_service].servicePrice);
    }

    function viewClientServiceStatus(string memory _service) public view returns(bool){
        return MappingClientHistory[_service].serviceStatus;
    }

    function DeleteClient() public ModOwnerOnly(msg.sender){
        emit EventSelfDestruct(msg.sender);
        selfdestruct(msg.sender);
    }

    function buyTokens(uint _numTokens) public payable ModOwnerOnly(msg.sender){
        require(_numTokens > 0, "You need to buy a number of tokens greaer than 0.");
        uint cost = calculateTokensPrice(_numTokens);
        require(msg.value >= cost, "You don't have enough ETH to buy this amount of tokens.");
        uint returnValue = msg.value - cost;
        msg.sender.transfer(returnValue);
        HealthInsuranceFactory(owner.insurance).buyTokens(msg.sender, _numTokens);
    }

    function balanceOf() public view ModOwnerOnly(msg.sender) returns(uint256 _balance){
        return(owner.tokens.balanceOf(address(this)));
    }

    function returnTokens(uint _numTokens) public payable ModOwnerOnly(msg.sender){
        require(_numTokens > 0, "You need to return a number of tokens greaer than 0.");
        require(_numTokens <= balanceOf(), "You don't have enough tokens to return that amount.");
        owner.tokens.transfer(owner.carrier, _numTokens);
        msg.sender.transfer(calculateTokensPrice(_numTokens));

        emit EventReturnTokens(msg.sender, _numTokens);
    }

    function requestService(string memory _serviceName) public ModOwnerOnly(msg.sender){
        require(HealthInsuranceFactory(owner.insurance).serviceStatus(_serviceName), "Service not available by carrier.");
        uint256 tokensPay = HealthInsuranceFactory(owner.insurance).getServicePrice(_serviceName);
        require(tokensPay <= balanceOf(), "You need to buy more tokens to request this srvice.");
        owner.tokens.transfer(owner.insurance, tokensPay);
        MappingClientHistory[_serviceName] = requestedServices(_serviceName, tokensPay, true);
        emit EventServicePayed(msg.sender, _serviceName, tokensPay);
    }

    function requestServiceToLab(address _labAddress, string memory _serviceName) public payable ModOwnerOnly(msg.sender){
        Lab labContract = Lab(_labAddress);
        require(msg.value == labContract.getServicePrice(_serviceName) * 1 ether, "Wrong payment amount.");
        labContract.provideService(msg.sender, _serviceName);
        payable(labContract.LabAddress()).transfer(labContract.getServicePrice(_serviceName) * 1 ether);
        ClientsLabHistory.push(requestedServicesLab(_serviceName, labContract.getServicePrice(_serviceName), _labAddress));
        emit EventServiceRequestToLab(_labAddress, msg.sender, _serviceName);
    }


}