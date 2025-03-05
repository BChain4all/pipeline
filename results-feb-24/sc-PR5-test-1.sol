pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement between a landlord and a tenant
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a unit for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(address => uint256) public balances;

    event RentPaid(address tenant, uint256 amount);
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

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
        balances[tenant] = securityDeposit;
    }

    /**
     * @dev Pay rent for a specific month
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rentAmount, "Incorrect rent amount");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Terminate the lease agreement early under specific conditions
     */
    function terminateLease() external onlyTenant isLeaseActive {
        require(block.timestamp < leaseEnd, "Lease has already ended");
        leaseActive = false;
        uint256 refundAmount = balances[tenant];
        balances[tenant] = 0;
        payable(tenant).transfer(refundAmount);
        emit LeaseTerminated(tenant);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Landlord refunds the security deposit at the end of the lease
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        require(balances[tenant] > 0, "No deposit to refund");
        uint256 refundAmount = balances[tenant];
        balances[tenant] = 0;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Allows the landlord to collect late fees
     */
    function collectLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseStart + 10 days, "Rent is not yet late");
        balances[tenant] -= lateFee;
        landlord.transfer(lateFee);
    }

    /**
     * @dev Fallback function to handle receiving ether directly
     */
    receive() external payable {
        revert("Direct payments not allowed");
    }
}