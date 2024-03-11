pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a basic lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
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
    function payRent(uint256 month) external payable onlyTenant {
        require(leaseActive, "Lease is not active.");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[month], "Rent already paid for this month.");
        
        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Terminate the lease agreement early.
     */
    function terminateLease() external onlyTenant {
        require(leaseActive, "Lease is already terminated.");
        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Simplified logic for refund calculation
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Landlord collects the security deposit.
     */
    function collectSecurityDeposit() external payable onlyLandlord {
        require(msg.value == securityDeposit, "Incorrect deposit amount.");
    }

    /**
     * @dev Landlord returns the security deposit minus any deductions.
     * @param deduction Amount to be deducted from the security deposit.
     */
    function returnSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(deduction <= securityDeposit, "Deduction exceeds deposit.");
        uint256 refundAmount = securityDeposit - deduction;
        payable(tenant).transfer(refundAmount);
    }

    /**
     * @dev Pay late fee.
     */
    function payLateFee() external payable onlyTenant {
        require(msg.value == lateFee, "Incorrect late fee amount.");
        // Logic to accept late fee payment
    }
}