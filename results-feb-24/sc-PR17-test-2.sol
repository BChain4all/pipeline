pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit of currency, for simplicity.
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive = false;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _month, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier onlyDuringLease() {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "This action can only be performed during the lease term.");
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
     * @dev Pay rent for a specific month.
     * @param _month Month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant onlyDuringLease {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent for this month has already been paid.");
        require(block.timestamp <= leaseEnd, "Lease has ended.");
        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions.
     */
    function terminateLease() external onlyTenant {
        require(block.timestamp < leaseEnd, "Lease has already ended.");
        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Simplified refund logic for demonstration.
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Landlord can claim the security deposit under specific conditions.
     */
    function claimSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active.");
        // Additional logic to validate conditions for claiming the security deposit.
        // Simplified for demonstration.
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Returns whether rent for a specific month has been paid.
     * @param _month Month to check.
     * @return bool Rent payment status for the month.
     */
    function isRentPaid(uint256 _month) external view returns (bool) {
        return rentPaid[_month];
    }
}