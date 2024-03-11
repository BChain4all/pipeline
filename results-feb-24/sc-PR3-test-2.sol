pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for US Dollars for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 month, uint256 amount);
    event LeaseTerminated(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isActiveLease() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isActiveLease {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[month], "Rent for this month already paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[month] = true;
        emit RentPaid(tenant, month, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement under specific conditions.
     */
    function terminateLease() external onlyLandlord isActiveLease {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
    }

    /**
     * @dev Returns the security deposit to the tenant, minus any deductions for damages.
     * @param amount The amount to be returned to the tenant.
     */
    function returnSecurityDeposit(uint256 amount) external onlyLandlord {
        require(amount <= securityDeposit, "Amount exceeds security deposit.");
        payable(tenant).transfer(amount);
    }

    /**
     * @dev Allows the landlord to charge a late fee if rent is not paid on time.
     */
    function chargeLateFee() external onlyLandlord isActiveLease {
        require(block.timestamp > leaseStart, "Lease has not started.");
        payable(landlord).transfer(lateFee);
    }
}