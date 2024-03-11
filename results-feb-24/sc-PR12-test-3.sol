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

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
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
     * @dev Allows the tenant to pay rent for a specific month.
     * @param _month The month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(!rentPaid[_month], "Rent already paid for this month.");
        
        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Allows the landlord to return the security deposit to the tenant.
     */
    function returnSecurityDeposit() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseEnd, "Lease term has not ended.");
        leaseActive = false;
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositReturned(tenant, securityDeposit);
    }

    /**
     * @dev Terminates the lease agreement before the end date.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Fallback function to handle receiving rent payments.
     */
    receive() external payable {
        payRent(getCurrentMonth());
    }

    /**
     * @dev Utility function to get the current month as a number.
     */
    function getCurrentMonth() public view returns (uint256) {
        return (block.timestamp - leaseStart) / 30 days + 1;
    }
}