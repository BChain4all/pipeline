pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as the currency
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(address => uint256) public balances;

    event RentPaid(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);

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
     * @dev Tenant pays rent to the landlord
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart, "Lease has not started");
        require(block.timestamp <= leaseEnd, "Lease has ended");
        require(msg.value == rentAmount, "Incorrect rent amount");

        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Landlord terminates the lease agreement
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refund the security deposit to the tenant
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        require(balances[tenant] >= securityDeposit, "Insufficient funds to refund");

        payable(tenant).transfer(securityDeposit);
        balances[tenant] -= securityDeposit;
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }

    /**
     * @dev Tenant pays the security deposit
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount");
        balances[tenant] += msg.value;
    }

    /**
     * @dev Check if rent is late and apply late fee
     */
    function checkAndApplyLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseEnd, "Lease has not yet ended");
        require(balances[tenant] < rentAmount, "Rent has been paid");

        balances[tenant] -= lateFee;
    }

    /**
     * @dev Get the current balance of the tenant
     */
    function getTenantBalance() external view returns (uint256) {
        return balances[tenant];
    }
}