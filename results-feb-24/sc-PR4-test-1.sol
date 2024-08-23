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
    uint public leaseStart = 1646092800; // March 1, 2022
    uint public leaseEnd = 1677628800; // March 1, 2023
    uint public monthlyRent = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint public securityDeposit = 1700 ether;
    uint public lateFee = 200 ether;
    bool public isLeaseActive = false;

    // Events
    event LeaseSigned(address tenant, uint leaseStart, uint leaseEnd);
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
        require(isLeaseActive, "The lease is not active.");
        _;
    }

    /**
     * @dev Constructor to set the initial landlord and tenant.
     */
    constructor(address payable _tenant) {
        landlord = payable(msg.sender);
        tenant = _tenant;
    }

    /**
     * @dev Function for the tenant to sign the lease.
     */
    function signLease() external onlyTenant {
        require(!isLeaseActive, "Lease is already active.");
        isLeaseActive = true;
        emit LeaseSigned(tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Function for the tenant to pay rent.
     */
    function payRent() external payable onlyTenant leaseIsActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease term is not valid.");
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Function for the landlord to terminate the lease.
     */
    function terminateLease() external onlyLandlord leaseIsActive {
        isLeaseActive = false;
        uint balance = address(this).balance;
        if (balance > 0) {
            tenant.transfer(balance);
        }
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Function to check the contract's balance.
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}