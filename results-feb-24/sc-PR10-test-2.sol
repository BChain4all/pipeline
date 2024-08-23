pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a unit of currency
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 amount, uint256 month);
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
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = block.timestamp; // Assuming lease starts upon contract deployment
        leaseEnd = leaseStart + 365 days; // Assuming a 1-year lease
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(month >= leaseStart && month <= leaseEnd, "Invalid month.");
        require(!rentPaid[month], "Rent for this month has already been paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        if (block.timestamp > (leaseStart + (month * 30 days) + 5 days)) {
            require(msg.value == rentAmount + lateFee, "Late fee not included.");
        }

        rentPaid[month] = true;
        emit RentPaid(tenant, msg.value, month);
    }

    /**
     * @dev Allows the landlord to terminate the lease under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Allows the tenant to terminate the lease under specific conditions, such as military service.
     */
    function terminateLeaseForCause() external onlyTenant isLeaseActive {
        // This function would include conditions under which the tenant can terminate the lease.
        // For simplicity, we're directly allowing termination here.
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Returns the security deposit to the tenant if there are no deductions.
     */
    function returnSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to return the security deposit.");
        // Assuming no deductions for simplicity. In a real scenario, deductions would be checked here.
        payable(tenant).transfer(securityDeposit);
    }

    /**
     * @dev Fallback function to handle receiving ether directly to the contract.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function to allow the landlord to withdraw rent payments.
     */
    function withdraw() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw.");
        payable(landlord).transfer(balance);
    }
}