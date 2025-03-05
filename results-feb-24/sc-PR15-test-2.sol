pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev Implements a lease agreement between a landlord and a tenant with specific terms and conditions.
 */
contract LeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the unit of currency, for simplicity.
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
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
    }

    /**
     * @dev Allows the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rentAmount, "Incorrect rent amount");
        landlord.transfer(msg.value);
        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refunds the security deposit to the tenant under specific conditions.
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        require(balances[tenant] >= securityDeposit, "Insufficient funds for refund");
        payable(tenant).transfer(securityDeposit);
        balances[tenant] -= securityDeposit;
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect deposit amount");
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev Allows the landlord to charge a late fee if rent is not paid on time.
     */
    function chargeLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseStart + 10 days, "Rent is not yet late");
        balances[tenant] += lateFee;
    }

    /**
     * @dev Fallback function to handle receiving ether directly.
     */
    receive() external payable {
        revert("Direct payments not allowed");
    }
}