pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the currency unit
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
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
        leaseStart = block.timestamp;
        leaseEnd = leaseStart + 365 days; // Assuming a 1-year lease
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
        emit RentPaid(tenant, msg.value, month);
    }

    /**
     * @dev Terminate the lease agreement
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refund the security deposit to the tenant
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to refund the security deposit.");
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Pay late fee
     */
    function payLateFee() external payable onlyTenant isLeaseActive {
        require(msg.value == lateFee, "Incorrect late fee amount.");
        // Late fee logic here
    }

    /**
     * @dev Fallback function to handle receiving ether directly
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw rent payments
     */
    function withdraw() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal.");
        payable(landlord).transfer(balance);
    }
}