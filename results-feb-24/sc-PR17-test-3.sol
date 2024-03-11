pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit of currency, for simplicity.
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 month, uint256 amount);
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
        emit RentPaid(msg.sender, month, msg.value);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions.
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease has already ended");
        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Simplified calculation, real-world scenario may require adjustments.
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Landlord refunds the security deposit at the end of the lease.
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(block.timestamp > leaseEnd, "Lease has not ended yet");
        require(leaseActive, "Lease is already terminated");
        leaseActive = false;
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Allows the landlord to collect late fees.
     */
    function collectLateFee() external payable onlyLandlord {
        require(msg.value == lateFee, "Incorrect late fee amount");
        // Logic to ensure late fee is due could be added here.
    }

    /**
     * @dev Fallback function to handle receiving ether directly.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw payments made to the contract.
     */
    function withdraw() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(landlord).transfer(balance);
    }
}