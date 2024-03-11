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

    event RentPaid(address indexed _tenant, uint256 _month, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can call this function.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can call this function.");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month.
     * @param _month Month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease term is not valid.");
        require(!rentPaid[_month], "Rent for this month is already paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[_month] = true;
        emit RentPaid(msg.sender, _month, msg.value);
    }

    /**
     * @dev Pay security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        // Assuming the security deposit is handled separately in terms of business logic
    }

    /**
     * @dev Terminate the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Withdraw rent payments.
     */
    function withdrawRent() external onlyLandlord {
        uint256 amount = address(this).balance;
        (bool success, ) = landlord.call{value: amount}("");
        require(success, "Failed to withdraw rent.");
    }

    /**
     * @dev Returns the contract's balance.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}