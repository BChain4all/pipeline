pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for US Dollars for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
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
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent for this month already paid.");
        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Allows the tenant to terminate the lease under specific conditions (e.g., military service).
     */
    function terminateLeaseForCause() external onlyTenant isLeaseActive {
        // This function would include conditions under which the tenant can terminate the lease, such as military service.
        // For simplicity, we're directly allowing termination here.
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Returns the security deposit to the tenant, minus any deductions for damages.
     * @param _amount The amount to be returned to the tenant.
     */
    function returnSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= securityDeposit, "Amount exceeds security deposit.");
        payable(tenant).transfer(_amount);
    }

    /**
     * @dev Allows the landlord to collect a late fee from the tenant.
     */
    function collectLateFee() external payable onlyTenant {
        require(msg.value == lateFee, "Incorrect late fee amount.");
        // Additional logic to ensure the late fee is collected appropriately could be added here.
    }
}