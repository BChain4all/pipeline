pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a unit for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive = false;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(uint256 leaseStart, uint256 leaseEnd, address tenant);
    event RentPaid(uint256 month, address tenant, uint256 amount);
    event LeaseTerminated(address tenant);

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
    }

    /**
     * @dev Sign the lease agreement. Can only be called by the tenant.
     */
    function signLease() external onlyTenant {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease signing period is invalid.");
        leaseActive = true;
        emit LeaseSigned(leaseStart, leaseEnd, tenant);
    }

    /**
     * @dev Pay rent for a specific month. Can only be called by the tenant.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant leaseIsActive {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease period is invalid.");
        require(!rentPaid[month], "Rent for this month has already been paid.");
        rentPaid[month] = true;
        landlord.transfer(msg.value);
        emit RentPaid(month, msg.sender, msg.value);
    }

    /**
     * @dev Terminate the lease agreement. Can be called by either the landlord or the tenant.
     */
    function terminateLease() external {
        require(msg.sender == landlord || msg.sender == tenant, "Only the landlord or tenant can terminate the lease.");
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Return the security deposit to the tenant. Can only be called by the landlord.
     */
    function returnSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to return the security deposit.");
        payable(tenant).transfer(securityDeposit);
    }

    /**
     * @dev Charge a late fee. Can only be called by the landlord.
     */
    function chargeLateFee() external onlyLandlord {
        require(leaseActive, "Lease is not active.");
        payable(landlord).transfer(lateFee);
    }
}