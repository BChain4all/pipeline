pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a placeholder for US Dollars for simplicity.
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
    }

    /**
     * @dev Allows the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rentAmount, "Incorrect rent amount");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount");
        balances[tenant] += msg.value;
    }

    /**
     * @dev Refunds the security deposit to the tenant at the end of the lease, minus any deductions.
     * @param deduction The amount to deduct from the security deposit for repairs/damages.
     */
    function refundSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        require(balances[tenant] >= deduction, "Deduction exceeds deposit");
        uint256 refundAmount = balances[tenant] - deduction;
        balances[tenant] = 0;
        payable(tenant).transfer(refundAmount);
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Allows the landlord to collect a late fee if the rent is not paid on time.
     */
    function collectLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseStart + 10 days, "Rent is not yet late");
        balances[tenant] -= lateFee;
        landlord.transfer(lateFee);
    }

    /**
     * @dev Fallback function to handle receiving ether directly to the contract.
     */
    receive() external payable {
        revert("Direct payments to this contract are not allowed");
    }
}