pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _amount, uint256 _month);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Allows the tenant to pay rent for a specific month.
     * @param _month The month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[_month], "Rent for this month already paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        if (block.timestamp > (leaseStart + (_month * 30 days)) + 5 days) {
            require(msg.value == rentAmount + lateFee, "Late fee not included.");
        }

        rentPaid[_month] = true;
        emit RentPaid(tenant, msg.value, _month);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Allows the tenant to terminate the lease under specific conditions.
     */
    function tenantTerminateLease() external onlyTenant isLeaseActive {
        // This could be expanded to include specific conditions under which the tenant can terminate the lease.
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Returns the lease status.
     */
    function getLeaseStatus() external view returns (bool) {
        return leaseActive;
    }

    /**
     * @dev Returns whether rent for a specific month has been paid.
     * @param _month The month in question.
     */
    function isRentPaid(uint256 _month) external view returns (bool) {
        return rentPaid[_month];
    }
}