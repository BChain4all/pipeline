pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a basic smart contract for a lease agreement between a landlord and a tenant.
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
    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _amount);
    event SecurityDepositPaid(address indexed _tenant, uint256 _amount);
    event SecurityDepositRefunded(address indexed _tenant, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

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
        address _landlord,
        address _tenant,
        uint256 _leaseStart,
        uint256 _leaseEnd,
        uint256 _monthlyRent,
        uint256 _securityDeposit
    ) {
        landlord = _landlord;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        monthlyRent = _monthlyRent;
        securityDeposit = _securityDeposit;
        leaseActive = true;

        emit LeaseSigned(_landlord, _tenant, _leaseStart, _leaseEnd);
    }

    /**
     * @dev Allows the tenant to pay their monthly rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(msg.value == monthlyRent, "Incorrect rent amount.");
        payable(landlord).transfer(msg.value);

        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        payable(landlord).transfer(msg.value);

        emit SecurityDepositPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the landlord to refund the security deposit to the tenant.
     */
    function refundSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= securityDeposit, "Amount exceeds security deposit.");
        payable(tenant).transfer(_amount);

        emit SecurityDepositRefunded(tenant, _amount);
    }

    /**
     * @dev Terminates the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;

        emit LeaseTerminated(landlord, tenant);
    }
}