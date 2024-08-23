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
    bool public agreementSigned = false;

    // Events
    event AgreementSigned(address landlord, address tenant);
    event RentPaid(address tenant, uint256 amount);
    event SecurityDepositReturned(address tenant, uint256 amount);
    event AgreementTerminated();

    /**
     * @dev Sets the contract creator as the landlord, and initializes the lease agreement details.
     * @param _tenant address of the tenant.
     * @param _premises string representation of the premises address.
     * @param _rent monthly rent amount in wei.
     * @param _securityDeposit security deposit amount in wei.
     * @param _leaseStart start date of the lease as a timestamp.
     * @param _leaseEnd end date of the lease as a timestamp.
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
    }

    /**
     * @dev Allows the tenant and landlord to sign the agreement.
     */
    function signAgreement() external {
        require(msg.sender == tenant || msg.sender == landlord, "Only the tenant or landlord can sign the agreement.");
        require(!agreementSigned, "The agreement has already been signed.");
        agreementSigned = true;
        emit AgreementSigned(landlord, tenant);
    }

    /**
     * @dev Allows the tenant to pay rent. Rent can only be paid by the tenant and if the agreement is signed.
     */
    function payRent() external payable {
        require(msg.sender == tenant, "Only the tenant can pay rent.");
        require(agreementSigned, "The agreement must be signed before paying rent.");
        require(msg.value == rent, "Incorrect rent amount.");
        emit RentPaid(tenant, msg.value);
        // Transfer the rent to the landlord
        payable(landlord).transfer(msg.value);
    }

    /**
     * @dev Allows the landlord to return the security deposit to the tenant.
     */
    function returnSecurityDeposit() external {
        require(msg.sender == landlord, "Only the landlord can return the security deposit.");
        require(agreementSigned, "The agreement must be signed.");
        emit SecurityDepositReturned(tenant, securityDeposit);
        // Transfer the security deposit back to the tenant
        payable(tenant).transfer(securityDeposit);
    }

    /**
     * @dev Terminates the agreement. Can be called by either the landlord or the tenant.
     */
    function terminateAgreement() external {
        require(msg.sender == tenant || msg.sender == landlord, "Only the tenant or landlord can terminate the agreement.");
        require(agreementSigned, "The agreement must be signed.");
        agreementSigned = false;
        emit AgreementTerminated();
        // Additional logic for termination can be added here
    }

    /**
     * @dev Fallback function to prevent direct sending of ether to the contract.
     */
    fallback() external {
        revert("Direct sending of ether is not allowed.");
    }

    /**
     * @dev Receive function to prevent direct sending of ether to the contract.
     */
    receive() external payable {
        revert("Direct sending of ether is not allowed.");
    }
}