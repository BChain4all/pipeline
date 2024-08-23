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
    uint256 public lateFee;
    bool public isLeaseActive;

    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);

    /**
     * @dev Sets the contract deployer as the landlord, and initializes the lease agreement details.
     * @param _tenant address of the tenant.
     * @param _premises string representation of the premises address.
     * @param _rent monthly rent amount in wei.
     * @param _securityDeposit security deposit amount in wei.
     * @param _leaseStart timestamp of lease start date.
     * @param _leaseEnd timestamp of lease end date.
     * @param _lateFee late fee amount in wei.
     */
    constructor(
        address _tenant,
        string memory _premises,
        uint256 _rent,
        uint256 _securityDeposit,
        uint256 _leaseStart,
        uint256 _leaseEnd,
        uint256 _lateFee
    ) {
        landlord = msg.sender;
        tenant = _tenant;
        premises = _premises;
        rent = _rent;
        securityDeposit = _securityDeposit;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        lateFee = _lateFee;
        isLeaseActive = true;

        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Allows the tenant to pay rent. Emits a RentPaid event.
     */
    function payRent() external payable {
        require(msg.sender == tenant, "Only the tenant can pay rent.");
        require(isLeaseActive, "Lease is not active.");
        require(msg.value == rent, "Incorrect rent amount.");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");

        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement. Emits a LeaseTerminated event.
     */
    function terminateLease() external {
        require(msg.sender == landlord, "Only the landlord can terminate the lease.");
        require(isLeaseActive, "Lease is already terminated.");

        isLeaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }

    /**
     * @dev Returns the lease details.
     */
    function getLeaseDetails() external view returns (
        address _landlord,
        address _tenant,
        string memory _premises,
        uint256 _rent,
        uint256 _securityDeposit,
        uint256 _leaseStart,
        uint256 _leaseEnd,
        uint256 _lateFee,
        bool _isLeaseActive
    ) {
        return (landlord, tenant, premises, rent, securityDeposit, leaseStart, leaseEnd, lateFee, isLeaseActive);
    }
}