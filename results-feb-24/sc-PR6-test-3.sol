pragma solidity ^0.8.0;

contract LeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint public rentAmount = 850 ether; // Assuming ether is used as a currency, in a real scenario, a stablecoin might be more appropriate
    uint public securityDeposit = 1700 ether;
    uint public leaseStart;
    uint public leaseEnd;
    bool public securityDepositPaid = false;
    bool public securityDepositReturned = false;
    uint public lateFee = 200 ether;
    uint public rentDueDate;

    event RentPaid(address tenant, uint amount);
    event SecurityDepositPaid(address tenant, uint amount);
    event SecurityDepositReturned(address tenant, uint amount);

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    constructor(address _tenant, uint _leaseStart, uint _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        rentDueDate = _leaseStart;
    }

    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        require(!securityDepositPaid, "Security deposit already paid.");
        securityDepositPaid = true;
        emit SecurityDepositPaid(msg.sender, msg.value);
    }

    function payRent() external payable onlyTenant {
        require(block.timestamp >= rentDueDate, "Rent is not due yet.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        if (block.timestamp > rentDueDate + 5 days) {
            require(msg.value == rentAmount + lateFee, "Late fee not included.");
        }
        landlord.transfer(msg.value);
        rentDueDate += 30 days; // Assuming rent is paid monthly
        emit RentPaid(msg.sender, msg.value);
    }

    function returnSecurityDeposit() external onlyLandlord {
        require(block.timestamp > leaseEnd, "Lease term has not ended.");
        require(securityDepositPaid && !securityDepositReturned, "Conditions for returning security deposit not met.");
        payable(tenant).transfer(securityDeposit);
        securityDepositReturned = true;
        emit SecurityDepositReturned(tenant, securityDeposit);
    }

    // Additional functions to handle other aspects of the lease could be added here
    // For example, handling damages, modifications to the lease terms, etc.
}