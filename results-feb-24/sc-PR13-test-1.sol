pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    string public premises;
    uint256 public rent;
    uint256 public securityDeposit;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public isLeaseActive;

    // Events
    event LeaseCreated(address indexed landlord, address indexed tenant, uint256 leaseStart, uint256 leaseEnd);
    event RentPaid(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed landlord, address indexed tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);

    // Modifiers
    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    modifier leaseIsActive() {
        require(isLeaseActive, "Lease is not active");
        _;
    }

    /**
     * @dev Constructor to create a lease agreement.
     * @param _landlord address of the landlord.
     * @param _tenant address of the tenant.
     * @param _premises address of the premises.
     * @param _rent monthly rent amount.
     * @param _securityDeposit security deposit amount.
     * @param _leaseStart start date of the lease.
     * @param _leaseEnd end date of the lease.
     */
    constructor(
        address _landlord,
        address _tenant,
        string memory _premises,
        uint256 _rent,
        uint256 _securityDeposit,
        uint256 _leaseStart,
        uint256 _leaseEnd
    ) {
        landlord = _landlord;
        tenant = _tenant;
        premises = _premises;
        rent = _rent;
        securityDeposit = _securityDeposit;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        isLeaseActive = true;

        emit LeaseCreated(_landlord, _tenant, _leaseStart, _leaseEnd);
    }

    /**
     * @dev Function for the tenant to pay rent.
     */
    function payRent() external payable onlyTenant leaseIsActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rent, "Incorrect rent amount");

        payable(landlord).transfer(msg.value);
        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Function for the landlord to terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord leaseIsActive {
        isLeaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Function for the landlord to refund the security deposit.
     */
    function refundSecurityDeposit(uint256 amount) external onlyLandlord {
        require(amount <= securityDeposit, "Amount exceeds security deposit");
        payable(tenant).transfer(amount);
        emit SecurityDepositRefunded(tenant, amount);
    }

    /**
     * @dev Function to check the balance of the contract.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}