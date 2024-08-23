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

    event RentPaid(address tenant, uint256 amount, uint256 month);
    event LeaseTerminated(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active.");
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
     * @dev Pay rent for a specific month. Rent must be paid in full.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[month], "Rent for this month already paid.");
        require(msg.value == rentAmount, "Rent amount is incorrect.");

        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Pay the security deposit. Must be done before the lease starts.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(block.timestamp < leaseStart, "Lease has already started.");
        require(msg.value == securityDeposit, "Security deposit amount is incorrect.");
    }

    /**
     * @dev Terminate the lease agreement. Can be called by either the landlord or the tenant.
     */
    function terminateLease() external {
        require(msg.sender == landlord || msg.sender == tenant, "Only landlord or tenant can terminate the lease.");
        leaseActive = false;
        emit LeaseTerminated(msg.sender);
    }

    /**
     * @dev Refund the security deposit to the tenant, minus any deductions for damages.
     * @param deduction Amount to deduct from the security deposit for damages.
     */
    function refundSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(deduction <= securityDeposit, "Deduction exceeds security deposit.");
        uint256 refundAmount = securityDeposit - deduction;
        payable(tenant).transfer(refundAmount);
    }

    /**
     * @dev Get the status of rent payment for a specific month.
     * @param month The month to check.
     * @return bool Status of rent payment for the month.
     */
    function isRentPaid(uint256 month) external view returns (bool) {
        return rentPaid[month];
    }
}