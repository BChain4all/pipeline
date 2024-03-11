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
    uint public rentDueDay = 5; // The 5th of every month

    // State variables
    bool public leaseActive;
    uint public totalPaid;
    mapping(uint => bool) public rentPaid;

    // Events
    event RentPaid(address tenant, uint amount, uint date);
    event LeaseTerminated(address tenant, uint date);

    /**
     * @dev Sets the contract deployer as the landlord and initializes the lease.
     * @param _tenant address of the tenant
     */
    constructor(address payable _tenant) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month.
     * @param _month month for which rent is being paid
     */
    function payRent(uint _month) external payable {
        require(leaseActive, "Lease is not active.");
        require(msg.sender == tenant, "Only the tenant can pay rent.");
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent for this month already paid.");
        require(block.timestamp <= leaseEndTimestamp, "Lease has ended.");

        uint currentMonth = (block.timestamp - leaseStartTimestamp) / 30 days;
        require(_month <= currentMonth, "Cannot pay in advance.");

        if (_month > rentDueDay && block.timestamp % 30 days > rentDueDay) {
            require(msg.value == monthlyRent + lateFee, "Late fee not included.");
        }

        landlord.transfer(msg.value);
        rentPaid[_month] = true;
        totalPaid += msg.value;

        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    /**
     * @dev Terminate the lease agreement.
     */
    function terminateLease() external {
        require(msg.sender == tenant, "Only the tenant can terminate the lease.");
        require(leaseActive, "Lease is already terminated.");

        leaseActive = false;
        uint refundAmount = securityDeposit;

        // Check for any unpaid rent
        for (uint i = 0; i <= (leaseEndTimestamp - leaseStartTimestamp) / 30 days; i++) {
            if (!rentPaid[i] && block.timestamp > leaseStartTimestamp + i * 30 days) {
                refundAmount -= monthlyRent;
            }
        }

        if (refundAmount > 0) {
            tenant.transfer(refundAmount);
        }

        emit LeaseTerminated(tenant, block.timestamp);
    }

    /**
     * @dev Get the lease status.
     * @return bool indicating if the lease is active
     */
    function getLeaseStatus() external view returns (bool) {
        return leaseActive;
    }

    /**
     * @dev Get the total amount paid by the tenant.
     * @return uint total amount paid
     */
    function getTotalPaid() external view returns (uint) {
        return totalPaid;
    }
}