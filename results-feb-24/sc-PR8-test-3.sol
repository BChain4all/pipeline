pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    // Landlord's details
    address payable public landlord;
    string public landlordName = "David Miller";
    string public landlordAddress = "324 W Gore St, Orlando, Florida, 32806";

    // Tenant's details
    address payable public tenant;
    string public tenantName = "Richard Garcia";
    string public tenantAddress = "7000 NW 27th Ave, Miami, Florida, 33147";

    // Lease details
    string public premisesAddress = "7000 NW 27th Ave, Miami, Florida, 33147";
    uint public leaseStartTimestamp = 1646092800; // March 1, 2022
    uint public leaseEndTimestamp = 1677628800; // March 1, 2023
    uint public monthlyRent = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint public securityDeposit = 1700 ether;
    uint public lateFee = 200 ether;
    uint public rentDueDay = 5; // The day of the month by which rent is due

    // State variables
    bool public leaseActive;
    uint public totalRentPaid;
    mapping(uint => bool) public rentPaidMonths;

    // Events
    event LeaseSigned(address landlord, address tenant);
    event RentPaid(address tenant, uint amount);
    event LeaseTerminated(address tenant);

    // Modifiers
    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier leaseIsActive() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    /**
     * @dev Constructor to set initial values including landlord and tenant addresses.
     * @param _tenant address of the tenant.
     */
    constructor(address payable _tenant) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant);
    }

    /**
     * @dev Function for tenant to pay rent.
     */
    function payRent() external payable onlyTenant leaseIsActive {
        require(block.timestamp >= leaseStartTimestamp, "Lease has not started.");
        require(block.timestamp <= leaseEndTimestamp, "Lease has ended.");
        require(msg.value == monthlyRent, "Incorrect rent amount.");

        uint currentMonth = (block.timestamp - leaseStartTimestamp) / 30 days;
        require(!rentPaidMonths[currentMonth], "Rent for this month already paid.");

        landlord.transfer(msg.value);
        rentPaidMonths[currentMonth] = true;
        totalRentPaid += msg.value;

        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Function for landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord leaseIsActive {
        leaseActive = false;
        uint refundAmount = securityDeposit;

        // Check if there are any unpaid months and adjust the refund amount
        for (uint i = 0; i <= (leaseEndTimestamp - leaseStartTimestamp) / 30 days; i++) {
            if (!rentPaidMonths[i]) {
                refundAmount -= monthlyRent;
            }
        }

        if (refundAmount > 0) {
            tenant.transfer(refundAmount);
        }

        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Function to check if rent is paid for a specific month.
     * @param monthIndex index of the month starting from 0 for the lease start month.
     * @return bool indicating if rent was paid for the given month.
     */
    function isRentPaidForMonth(uint monthIndex) external view returns (bool) {
        return rentPaidMonths[monthIndex];
    }
}