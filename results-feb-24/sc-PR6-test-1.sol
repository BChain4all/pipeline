pragma solidity ^0.8.0;

contract LeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint public leaseStart;
    uint public leaseEnd;
    uint public monthlyRent;
    uint public securityDeposit;
    bool public securityDepositPaid = false;
    bool public leaseActive = false;

    event RentPaid(address tenant, uint amount, uint date);
    event SecurityDepositPaid(address tenant, uint amount);
    event LeaseTerminated(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    constructor(address _tenant, uint _leaseStart, uint _leaseEnd, uint _monthlyRent, uint _securityDeposit) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        monthlyRent = _monthlyRent;
        securityDeposit = _securityDeposit;
    }

    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        require(!securityDepositPaid, "Security deposit already paid.");
        landlord.transfer(msg.value);
        securityDepositPaid = true;
        leaseActive = true;
        emit SecurityDepositPaid(tenant, msg.value);
    }

    function payRent() external payable onlyTenant {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease is not active.");
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    function terminateLease() external onlyLandlord {
        leaseActive = false;
        emit LeaseTerminated(tenant);
        // Additional logic for security deposit refund can be added here
    }

    // Additional functions to handle late fees, maintenance requests, etc., can be added here.
}