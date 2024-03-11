pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the currency used
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 amount, uint256 month);
    event LeaseTerminated(address tenant);

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
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(!rentPaid[month], "Rent already paid for this month");
        require(msg.value == rentAmount, "Incorrect rent amount");

        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount");
        // In a real scenario, this would move funds to a secure wallet or escrow.
    }

    /**
     * @dev Terminate the lease agreement early.
     */
    function terminateLease() external onlyTenant isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(msg.sender);
        // Additional logic for handling security deposit and any other termination logic would be added here.
    }

    /**
     * @dev Landlord collects rent for a specific month. Typically would transfer the funds to the landlord's address.
     * @param month The month for which rent is being collected.
     */
    function collectRent(uint256 month) external onlyLandlord {
        require(rentPaid[month], "Rent not paid for this month");
        // Transfer the rent amount to the landlord's address.
        // In a real scenario, this would involve transferring the funds from the contract to the landlord.
    }

    /**
     * @dev Return the security deposit to the tenant, minus any deductions for damages.
     * @param deduction Amount to deduct from the security deposit for damages.
     */
    function returnSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(deduction <= securityDeposit, "Deduction exceeds security deposit");
        uint256 refundAmount = securityDeposit - deduction;
        // Transfer the refund amount to the tenant's address.
        // In a real scenario, this would involve transferring the funds from the contract to the tenant.
    }
}