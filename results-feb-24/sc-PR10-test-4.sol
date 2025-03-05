pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the currency, for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 amount, uint256 month);
    event LeaseTerminated(address tenant);
    event SecurityDepositRefunded(address tenant, uint256 amount);

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
     * @dev Pay rent for a specific month
     * @param month The month for which rent is being paid
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(msg.value == rentAmount, "Incorrect rent amount");
        require(!rentPaid[month], "Rent already paid for this month");
        require(block.timestamp <= leaseEnd, "Lease has ended");

        rentPaid[month] = true;
        emit RentPaid(msg.sender, msg.value, month);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease has naturally ended");

        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Simplified logic for refund calculation
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Landlord collects rent for a specific month
     * @param month The month for which rent is being collected
     */
    function collectRent(uint256 month) external onlyLandlord {
        require(rentPaid[month], "Rent not paid for this month");
        // Assuming the rent is already in the contract, transfer it to the landlord
        payable(landlord).transfer(rentAmount);
    }

    /**
     * @dev Refund the security deposit at the end of the lease, if applicable
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(block.timestamp > leaseEnd, "Lease has not ended yet");
        require(leaseActive, "Lease is not active");

        leaseActive = false;
        uint256 refundAmount = securityDeposit; // Simplified logic for refund calculation
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Fallback function to handle receiving ether directly
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw funds
     */
    function withdraw() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(landlord).transfer(balance);
    }
}