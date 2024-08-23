pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
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

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _start, uint256 _end);
    event RentPaid(address indexed _tenant, uint256 _month, uint256 _amount);
    event SecurityDepositReturned(address indexed _tenant, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isActiveLease() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _start, uint256 _end) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _start;
        leaseEnd = _end;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Tenant pays rent for a specific month.
     * @param _month Month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isActiveLease {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent already paid for this month.");
        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Landlord returns the security deposit to the tenant.
     */
    function returnSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to return the security deposit.");
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositReturned(tenant, securityDeposit);
    }

    /**
     * @dev Terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isActiveLease {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Fallback function to handle receiving ether directly to the contract.
     */
    receive() external payable {
        revert("Direct payments to this contract are not allowed.");
    }
}