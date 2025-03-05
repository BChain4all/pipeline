pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a basic lease agreement between a landlord and tenant
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    uint256 public monthlyRent;
    uint256 public securityDeposit;
    bool public leaseActive;

    // Events
    event LeaseSigned(address indexed tenant, uint256 leaseStart, uint256 leaseEnd);
    event RentPaid(address indexed tenant, uint256 amount);
    event SecurityDepositPaid(address indexed tenant, uint256 amount);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed tenant);

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

    constructor(
        address _tenant,
        uint256 _leaseStart,
        uint256 _leaseEnd,
        uint256 _monthlyRent,
        uint256 _securityDeposit
    ) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        monthlyRent = _monthlyRent;
        securityDeposit = _securityDeposit;
        leaseActive = true;
    }

    /**
     * @dev Tenant signs the lease agreement
     */
    function signLease() external onlyTenant {
        require(block.timestamp >= leaseStart, "Lease cannot be signed before the start date.");
        emit LeaseSigned(tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Tenant pays the monthly rent
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Tenant pays the security deposit
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        emit SecurityDepositPaid(tenant, msg.value);
    }

    /**
     * @dev Landlord refunds the security deposit to the tenant
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(address(this).balance >= securityDeposit, "Insufficient balance to refund security deposit.");
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Terminate the lease agreement
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Get the current balance of the contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}