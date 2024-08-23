pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev Implements a lease agreement between a landlord and a tenant on the Ethereum blockchain.
 */
contract LeaseAgreement {
    // State variables
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit of currency
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(address => uint256) public rentBalance;
    
    // Events
    event RentPaid(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);
    event LateFeeAssessed(address indexed tenant, uint256 fee);

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
     * @dev Constructor to create a lease agreement.
     * @param _tenant Address of the tenant.
     * @param _leaseStart Start date of the lease as a timestamp.
     * @param _leaseEnd End date of the lease as a timestamp.
     */
    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Function for the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart, "Lease has not started.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        landlord.transfer(msg.value);
        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Function for the landlord to assess a late fee.
     */
    function assessLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseStart + 10 days, "Late fee cannot be assessed yet.");
        rentBalance[tenant] += lateFee;
        emit LateFeeAssessed(tenant, lateFee);
    }

    /**
     * @dev Function for the tenant to terminate the lease agreement.
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp > leaseEnd, "Lease term has not ended.");
        leaseActive = false;
        emit LeaseTerminated(msg.sender);
    }

    /**
     * @dev Function for the landlord to refund the security deposit.
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active.");
        uint256 refundAmount = securityDeposit - rentBalance[tenant];
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Fallback function to handle receiving ether.
     */
    receive() external payable {
        revert("Direct payments not allowed.");
    }
}