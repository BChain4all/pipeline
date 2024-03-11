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
    uint public rentDueDay = 5; // 5th of every month
    uint public lateFee = 200 ether;
    uint public lateFeeAfterDay = 10; // 10th of every month

    // State variables
    bool public leaseActive;
    uint public totalPaid;
    mapping(uint => bool) public rentPaid;

    // Events
    event RentPaid(address tenant, uint amount, uint month);
    event LeaseTerminated(address tenant);

    /**
     * @dev Sets the contract deployer as the landlord and initializes the lease.
     * @param _tenant address of the tenant.
     */
    constructor(address payable _tenant) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent.
     * @param _month represents the month number (1 = January, 12 = December) for which rent is paid.
     */
    function payRent(uint _month) external payable {
        require(leaseActive, "Lease is not active.");
        require(msg.sender == tenant, "Only the tenant can pay rent.");
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent for this month is already paid.");
        require(block.timestamp <= leaseEndTimestamp, "Lease has ended.");

        uint currentDay = getCurrentDay();
        if (currentDay > rentDueDay && currentDay <= lateFeeAfterDay) {
            require(msg.value == monthlyRent + lateFee, "Late fee not included.");
        }

        landlord.transfer(msg.value);
        rentPaid[_month] = true;
        totalPaid += msg.value;

        emit RentPaid(tenant, msg.value, _month);
    }

    /**
     * @dev Terminates the lease agreement.
     */
    function terminateLease() external {
        require(msg.sender == tenant || msg.sender == landlord, "Only the tenant or landlord can terminate the lease.");
        require(leaseActive, "Lease is already terminated.");

        leaseActive = false;
        uint refundAmount = securityDeposit;
        if (totalPaid > 0) {
            refundAmount += totalPaid - (monthlyRent * getLeaseMonths());
        }
        tenant.transfer(refundAmount);

        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Returns the current day of the month.
     */
    function getCurrentDay() public view returns (uint) {
        return (block.timestamp / 60 / 60 / 24) % 30 + 1; // Simplified calculation
    }

    /**
     * @dev Calculates the total number of months in the lease term.
     */
    function getLeaseMonths() public view returns (uint) {
        return (leaseEndTimestamp - leaseStartTimestamp) / 30 days;
    }
}