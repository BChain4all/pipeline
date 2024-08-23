pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
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

    modifier isLeaseActive() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = block.timestamp; // Assuming lease starts upon contract deployment
        leaseEnd = leaseStart + 365 days; // Assuming a 1-year lease term
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month
     * @param month The month for which rent is being paid
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(month >= leaseStart && month <= leaseEnd, "Invalid month.");
        require(!rentPaid[month], "Rent for this month has already been paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease term has already ended.");
        leaseActive = false;
        uint256 refundAmount = securityDepositAmount; // Simplified logic for refund calculation
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Refund the security deposit at the end of the lease, minus any deductions
     */
    function refundSecurityDeposit(uint256 deductions) external onlyLandlord {
        require(!leaseActive, "Lease is still active.");
        require(deductions <= securityDepositAmount, "Deductions exceed the deposit amount.");
        uint256 refundAmount = securityDepositAmount - deductions;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Receive payments (for receiving security deposit)
     */
    receive() external payable {
        require(msg.value == securityDepositAmount, "Incorrect security deposit amount.");
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        revert("Invalid transaction.");
    }
}