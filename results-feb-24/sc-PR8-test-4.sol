pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for US Dollars for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;

    // Events
    event RentPaid(address tenant, uint256 amount);
    event LeaseTerminated(address tenant);
    event SecurityDepositRefunded(address tenant, uint256 amount);

    // Modifiers
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

    /**
     * @dev Constructor to create a new lease agreement.
     * @param _landlord address of the landlord.
     * @param _tenant address of the tenant.
     * @param _leaseStart start date of the lease as a timestamp.
     * @param _leaseEnd end date of the lease as a timestamp.
     */
    constructor(address _landlord, address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = _landlord;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refunds the security deposit to the tenant minus any deductions.
     * @param _amount amount to be refunded to the tenant.
     */
    function refundSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= securityDeposit, "Refund amount exceeds security deposit.");
        leaseActive = false;
        payable(tenant).transfer(_amount);
        emit SecurityDepositRefunded(tenant, _amount);
    }

    /**
     * @dev Fallback function to handle receiving ether.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw rent payments.
     */
    function withdraw() external onlyLandlord {
        payable(landlord).transfer(address(this).balance);
    }
}