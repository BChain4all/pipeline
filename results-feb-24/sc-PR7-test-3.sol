pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a basic lease agreement as a smart contract
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

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _month, uint256 _amount);
    event SecurityDepositPaid(address indexed _tenant, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Pay the security deposit. Must be called by the tenant.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        emit SecurityDepositPaid(tenant, msg.value);
    }

    /**
     * @dev Pay rent for a specific month. Must be called by the tenant.
     * @param _month Month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent for this month already paid.");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        
        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Terminate the lease agreement. Can be called by either the landlord or the tenant.
     */
    function terminateLease() external {
        require(msg.sender == landlord || msg.sender == tenant, "Only landlord or tenant can terminate the lease.");
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Get the status of rent payment for a specific month.
     * @param _month Month for which to check the rent payment status.
     * @return bool Status of rent payment for the month.
     */
    function isRentPaid(uint256 _month) external view returns (bool) {
        return rentPaid[_month];
    }
}