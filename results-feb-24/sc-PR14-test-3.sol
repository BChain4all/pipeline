pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev Implements a standard lease agreement between a landlord and a tenant
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _month, uint256 _amount);
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
        require(leaseActive, "The lease is not active.");
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
        require(!rentPaid[_month], "Rent for this month has already been paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        // In a real scenario, these funds would be managed more securely, potentially with a multi-sig wallet or escrow.
    }

    /**
     * @dev Returns the security deposit to the tenant, less any damages.
     * @param _amount The amount to return to the tenant.
     */
    function returnSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= securityDeposit, "Cannot return more than the original security deposit.");
        payable(tenant).transfer(_amount);
    }

    /**
     * @dev Allows the landlord to collect a late fee from the tenant.
     */
    function collectLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseEnd, "Lease term has not ended.");
        payable(landlord).transfer(lateFee);
    }

    /**
     * @dev Fallback function to accept Ether sent directly to the contract.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function to allow the landlord to withdraw rent payments.
     */
    function withdrawRent() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw.");
        payable(landlord).transfer(balance);
    }
}