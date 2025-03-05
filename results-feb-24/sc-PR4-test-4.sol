pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the currency used
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 amount, uint256 month);
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
        leaseStart = 1646092800; // March 1, 2022 00:00:00 GMT
        leaseEnd = 1677628800; // March 1, 2023 00:00:00 GMT
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

        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount");
        // Assuming the security deposit is handled off-chain or in another function for simplicity
    }

    /**
     * @dev Terminate the lease agreement early.
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease has already ended");
        leaseActive = false;
        emit LeaseTerminated(msg.sender);
        // Assuming the security deposit return logic is handled off-chain or in another function for simplicity
    }

    /**
     * @dev Landlord collects late fee.
     */
    function collectLateFee() external onlyLandlord {
        // Assuming the late fee collection logic is handled off-chain or in another function for simplicity
    }

    /**
     * @dev Returns whether rent is paid for a specific month.
     * @param month The month to check.
     * @return bool Whether rent is paid for the month.
     */
    function isRentPaid(uint256 month) external view returns (bool) {
        return rentPaid[month];
    }
}