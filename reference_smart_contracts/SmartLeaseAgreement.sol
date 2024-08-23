//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SmartLeaseAgreement is ReentrancyGuard  {

    event WrittenContractProposed(uint timestamp, string ipfsHash);
    event RentPaied(uint256 month, address tenant);
    event TenantSigned(uint timestamp, address tenantAddress);
    event DepositPayed(uint timestamp, address tenantAddress, uint amount);
    event LeaseCreated(address indexed landlord, address indexed tenant, uint256 rentAmount, uint256 leaseStart, uint256 leaseEnd);
    event LeaseTerminated(address tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);
    event SecurityDepositPaid(address indexed tenant, uint256 amount);

    address payable public landlord;
    address payable public tenant;
    string public writtenContractIpfsHash;
    uint256 public rentAmount = 850; // in USD
    uint256 public lateFee = 200; // in USD
    uint256 public securityDeposit = 1700; // in USD
    bool public isDepositPaid = false;
    uint256 public duePayDay = 5 days;
    uint256 public finalPaimentDueDate = 15 days;
    uint256 public currentMonth = 1;
    uint256 public leaseAgreementCreation;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    uint256 public rentDueDate;

    // Define a struct to hold all the information if you prefer structured data
    struct LeaseInfo {
        address landlord;
        address tenant;
        string writtenContractIpfsHash;
        address contractAddress;
        uint256 leaseStart;
        uint256 leaseEnd;
        uint256 duePayDay;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier validRentPayment() {
        require(block.timestamp > leaseStart && block.timestamp <= leaseEnd, "Paiment is required only when the lease agreement is valid.");
        require(isDepositPaid == true, "The deposit was not payed between the time limits.");
        if (block.timestamp >=rentDueDate && block.timestamp <= rentDueDate + duePayDay){
            require(msg.value == rentAmount, "Amount paid not equal to the due amount.");
        } else {
            require(block.timestamp >= rentDueDate, "Rent already paid for this month.");
            require(msg.value == rentAmount + lateFee, "Amount paid not equal to the usual amount since late fee cause applies.");
        }
        _;
    }

    modifier malitiousTenantBehavior(){
        require(block.timestamp > rentDueDate + finalPaimentDueDate, "Tenant has still time to pay the rent.");
        _;
    }

    modifier validDepositPayment() {
        require(block.timestamp <= leaseStart, "Expired time for the deposit payment.");
        require(msg.value == securityDeposit, "Value of payment is not as the required one.");
        _;
    }

    modifier validDepositRefund() {
        require(block.timestamp >= leaseEnd && block.timestamp <= leaseEnd + 15 days);
        _;
    }

    modifier validPeriod() {
        require(leaseEnd > leaseStart);
        _;
    }

    // inheritance would be an issue with external constructors
    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {

        landlord = payable(msg.sender);
        tenant = payable(_tenant);
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        rentDueDate = _leaseStart;
        leaseAgreementCreation = block.timestamp;

        emit LeaseCreated(landlord, tenant, rentAmount, leaseStart, leaseEnd);
    }

    function proposeWrittenContract(string calldata _writtenContractIpfsHash) external onlyLandlord {
        // Update written contract ipfs hash
        writtenContractIpfsHash = _writtenContractIpfsHash;
        emit WrittenContractProposed(block.timestamp, _writtenContractIpfsHash);
    }

    function paySecurityDeposit() external payable onlyTenant validDepositPayment {
        isDepositPaid = true;
        emit SecurityDepositPaid(msg.sender, msg.value);
    }

    function refundSecurityDeposit() external onlyTenant validDepositRefund nonReentrant {
        (bool sent, ) = msg.sender.call{value: securityDeposit}("");
        require(sent, "Failed to refund deposit.");
        emit SecurityDepositRefunded(tenant, securityDeposit);
        securityDeposit = 0;
    }

    function getSecurityDeposit() external onlyLandlord malitiousTenantBehavior nonReentrant {
        uint256 amount = securityDeposit;
        securityDeposit = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to refund deposit to landlord for malitious intent.");
        emit SecurityDepositRefunded(tenant, securityDeposit);
        securityDeposit = 0;
    }

    function earlyTermination() external onlyLandlord nonReentrant {
        (bool sent, ) = tenant.call{value: securityDeposit}("");
        require(sent, "Failed to refund deposit to landlord.");
        emit SecurityDepositRefunded(tenant, securityDeposit);
        securityDeposit = 0;
    }

    function payRent() external payable onlyTenant validRentPayment nonReentrant {
        (bool sent, ) = landlord.call{value: msg.value}("");
        require(sent, "Failed to send rent to the landlord.");
        rentDueDate += 30 days;
        currentMonth += 1;
        emit RentPaied(currentMonth, tenant);
    }

    // Or if you prefer to use the struct
    function getAllInfoStructured() public view returns (LeaseInfo memory) {
        return LeaseInfo(
            landlord,
            tenant,
            writtenContractIpfsHash,
            address(this),
            leaseStart,
            leaseEnd,
            duePayDay
        );
    }

}