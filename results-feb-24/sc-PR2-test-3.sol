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

    event LeaseSigned(uint256 leaseStart, uint256 leaseEnd, address tenant);
    event RentPaid(uint256 month, address tenant);
    event LeaseTerminated(address tenant);

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
        emit LeaseSigned(_leaseStart, _leaseEnd, _tenant);
    }

    /**
     * @dev Tenant pays rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[month], "Rent for this month already paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[month] = true;
        emit RentPaid(month, msg.sender);
    }

    /**
     * @dev Landlord terminates the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Tenant pays the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
    }

    /**
     * @dev Landlord returns the security deposit to the tenant.
     */
    function returnSecurityDeposit() external onlyLandlord {
        require(address(this).balance >= securityDeposit, "Insufficient balance to return security deposit.");
        payable(tenant).transfer(securityDeposit);
    }

    /**
     * @dev Get contract balance.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}