pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev This contract represents a standard lease agreement between a landlord and a tenant.
 *      It encapsulates terms and conditions of the lease agreement as described in the provided legal agreement.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as the currency unit for simplicity
    uint256 public constant securityDepositAmount = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address indexed tenant, uint256 amount, uint256 month);
    event LeaseTerminated(address indexed tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);

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
    }

    /**
     * @dev Allows the tenant to pay rent for a specific month.
     * @param _month The month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[_month], "Rent for this month already paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[_month] = true;
        emit RentPaid(msg.sender, msg.value, _month);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refunds the security deposit to the tenant minus any deductions.
     * @param _deductions The amount to be deducted from the security deposit.
     */
    function refundSecurityDeposit(uint256 _deductions) external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to refund the security deposit.");
        require(_deductions <= securityDepositAmount, "Deductions exceed security deposit.");

        uint256 refundAmount = securityDepositAmount - _deductions;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDepositAmount, "Incorrect security deposit amount.");
        // Assuming the security deposit is handled off-chain or in another contract function for simplicity.
    }

    /**
     * @dev Fallback function to prevent ether from being sent to the contract inadvertently.
     */
    fallback() external {
        revert("Cannot send ETH directly to this contract.");
    }
}