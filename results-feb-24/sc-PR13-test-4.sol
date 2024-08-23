pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
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
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active");
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
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(!rentPaid[_month], "Rent already paid for this month");
        require(msg.value == rentAmount, "Incorrect rent amount");

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
        require(msg.value == securityDeposit, "Incorrect security deposit amount");
        // In a real scenario, these funds would be managed more carefully, potentially with escrow.
    }

    /**
     * @dev Returns the security deposit to the tenant, less any damages.
     * @param _amount The amount to return to the tenant.
     */
    function returnSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= securityDeposit, "Amount exceeds security deposit");
        payable(tenant).transfer(_amount);
    }

    /**
     * @dev Fallback function to handle receiving ether.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw rent payments.
     */
    function withdraw() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(landlord).transfer(balance);
    }
}