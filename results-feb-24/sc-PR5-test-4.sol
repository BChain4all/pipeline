pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement between a landlord and a tenant.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a currency unit for simplicity
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
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier leaseIsActive() {
        require(leaseActive, "The lease is not active.");
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
     * @dev Allows the tenant to pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant leaseIsActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease term is not valid.");
        require(!rentPaid[month], "Rent for this month has already been paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[month] = true;
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value, month);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement under specific conditions.
     */
    function terminateLease() external onlyLandlord leaseIsActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refunds the security deposit to the tenant minus any deductions.
     * @param deductions The amount to be deducted from the security deposit.
     */
    function refundSecurityDeposit(uint256 deductions) external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to refund the security deposit.");
        require(deductions <= securityDeposit, "Deductions exceed the security deposit.");

        uint256 refundAmount = securityDeposit - deductions;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        landlord.transfer(msg.value);
    }

    /**
     * @dev Fallback function to prevent direct sending of ether to the contract.
     */
    fallback() external {
        revert("Direct sending of ether is not allowed.");
    }

    /**
     * @dev Receive function to prevent direct sending of ether to the contract.
     */
    receive() external payable {
        revert("Direct sending of ether is not allowed.");
    }
}