pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit of currency
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 month, uint256 amount);
    event LeaseTerminated(address tenant);

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

    constructor(address _tenant) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = block.timestamp; // Assuming lease starts upon contract deployment
        leaseEnd = leaseStart + 365 days; // Assuming a 1-year lease
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(!rentPaid[month], "Rent already paid for this month");
        require(msg.value == rentAmount, "Incorrect rent amount");

        if (block.timestamp > leaseStart + month * 30 days + 5 days) {
            require(msg.value == rentAmount + lateFee, "Late fee not included");
        }

        rentPaid[month] = true;
        emit RentPaid(tenant, month, msg.value);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions.
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease term has already ended");

        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Assuming no damages for simplicity

        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Landlord can claim the security deposit under specific conditions.
     */
    function claimSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active");

        uint256 claimAmount = securityDeposit; // Assuming full claim for simplicity
        payable(landlord).transfer(claimAmount);
    }

    /**
     * @dev Returns the contract's balance.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to accept Ether.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for unexpected Ether in the contract.
     */
    function withdraw() external onlyLandlord {
        payable(landlord).transfer(address(this).balance);
    }
}