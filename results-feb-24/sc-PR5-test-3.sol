pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement between a landlord and a tenant.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a unit for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 amount, uint256 month);
    event LeaseTerminated(address tenant);
    event SecurityDepositRefunded(address tenant, uint256 amount);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month. Only the tenant can call this function.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(!rentPaid[month], "Rent already paid for this month");
        require(msg.value == rentAmount, "Incorrect rent amount");

        rentPaid[month] = true;
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value, month);
    }

    /**
     * @dev Terminate the lease agreement. Can be called by either the landlord or the tenant.
     */
    function terminateLease() external isLeaseActive {
        require(msg.sender == landlord || msg.sender == tenant, "Only landlord or tenant can terminate the lease");
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refund the security deposit to the tenant. Only the landlord can call this function.
     * @param deduction Amount to be deducted from the security deposit for any damages or unpaid rent.
     */
    function refundSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to refund the security deposit");
        require(deduction <= securityDeposit, "Deduction exceeds security deposit");

        uint256 refundAmount = securityDeposit - deduction;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Fallback function to prevent direct deposits.
     */
    fallback() external {
        revert("Direct deposits are not allowed");
    }
}