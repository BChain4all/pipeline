pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
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
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = block.timestamp; // Lease starts upon contract deployment
        leaseEnd = leaseStart + 365 days; // Lease duration is 1 year
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month.
     * @param month The month for which rent is being paid.
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(month >= leaseStart && month <= leaseEnd, "Invalid month");
        require(!rentPaid[month], "Rent already paid for this month");
        require(msg.value == rentAmount, "Incorrect rent amount");

        rentPaid[month] = true;
        landlord.transfer(msg.value);
        emit RentPaid(tenant, month, msg.value);
    }

    /**
     * @dev Pay late fee.
     */
    function payLateFee() external payable onlyTenant isLeaseActive {
        require(msg.value == lateFee, "Incorrect late fee amount");
        landlord.transfer(msg.value);
    }

    /**
     * @dev Terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refund the security deposit to the tenant.
     */
    function refundSecurityDeposit() external onlyLandlord isLeaseActive {
        require(!leaseActive, "Lease is still active");
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Fallback function to handle receiving ether directly.
     */
    receive() external payable {}

    /**
     * @dev Withdraw function for the landlord to withdraw funds.
     */
    function withdraw(uint256 _amount) external onlyLandlord {
        require(_amount <= address(this).balance, "Insufficient balance");
        landlord.transfer(_amount);
    }
}