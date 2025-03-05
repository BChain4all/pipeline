pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement between a landlord and a tenant.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit for simplicity, in a real scenario, a stablecoin or specific token might be used.
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public securityDepositReturned = false;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address indexed tenant, uint256 month, uint256 amount);
    event SecurityDepositReturned(address indexed tenant, uint256 amount);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
    }

    /**
     * @dev Pay rent for a specific month. The month is represented as an integer (e.g., 1 for January).
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease term is not active");
        require(!rentPaid[month], "Rent for this month already paid");
        require(msg.value == rentAmount, "Incorrect rent amount");

        rentPaid[month] = true;
        landlord.transfer(msg.value);

        emit RentPaid(tenant, month, msg.value);
    }

    /**
     * @dev Return the security deposit to the tenant, deducting any damages or unpaid rent.
     * @param deductions Amount to be deducted from the security deposit for damages or unpaid rent.
     */
    function returnSecurityDeposit(uint256 deductions) external onlyLandlord {
        require(block.timestamp > leaseEnd, "Lease term is still active");
        require(!securityDepositReturned, "Security deposit already returned");
        require(deductions <= securityDeposit, "Deductions exceed security deposit");

        uint256 refundAmount = securityDeposit - deductions;
        securityDepositReturned = true;
        payable(tenant).transfer(refundAmount);

        emit SecurityDepositReturned(tenant, refundAmount);
    }

    /**
     * @dev Allows the landlord to collect a late fee from the tenant.
     */
    function collectLateFee() external payable onlyTenant {
        require(msg.value == lateFee, "Incorrect late fee amount");
        landlord.transfer(msg.value);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions (e.g., tenant is a victim of domestic violence).
     * This is a simplified representation. In practice, verification of the condition would be required.
     */
    function earlyTermination() external onlyTenant {
        // Simplified check for demonstration. In a real scenario, additional verification would be needed.
        require(block.timestamp < leaseEnd, "Lease term has already ended");

        leaseEnd = block.timestamp; // Adjust lease end to current time to terminate the lease.
    }
}