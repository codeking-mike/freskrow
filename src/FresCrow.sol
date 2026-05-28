// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FresCrow is ReentrancyGuard {
    enum Status {
        Funded,
        Accepted,
        Delivered,
        Released,
        Refunded,
        Disputed
    }

    struct Escrow {
        address client;
        address freelancer;
        uint256 amount;
        uint256 releasedAmount;
        Status status;
        string description;
    }

    event EscrowCreated(uint256 indexed escrowId, address indexed client, address indexed freelancer, uint256 amount);
    event EscrowAccepted(uint256 indexed escrowId, address indexed freelancer);
    event EscrowDelivered(uint256 indexed escrowId, address indexed freelancer);
    event FundsReleased(uint256 indexed escrowId, address indexed freelancer, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed client, uint256 amount);
    event EscrowDisputed(uint256 indexed escrowId, address indexed reporter);
    event EscrowDisputeResolved(uint256 indexed escrowId, address indexed winner, uint256 amount);

    error NotClient();
    error NotFreelancer();
    error EscrowNotFound();
    error EscrowAlreadyResolved();
    error EscrowNotPending();
    error InvalidWinner();

    address public platformOwner;
    uint256 public escrowCount;
    mapping(uint256 => Escrow) public escrows;

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function");
        _;
    }

    modifier escrowExists(uint256 escrowId) {
        if (escrows[escrowId].client == address(0)) revert EscrowNotFound();
        _;
    }

    modifier onlyClient(uint256 escrowId) {
        if (msg.sender != escrows[escrowId].client) revert NotClient();
        _;
    }

    modifier onlyFreelancer(uint256 escrowId) {
        if (msg.sender != escrows[escrowId].freelancer) revert NotFreelancer();
        _;
    }

    constructor(address _platformOwner) {
        require(_platformOwner != address(0), "Platform owner cannot be zero");
        platformOwner = _platformOwner;
    }

    function createEscrow(address freelancer, string memory description) external payable nonReentrant {
        require(msg.value > 0, "Payment must be greater than zero");
        require(freelancer != address(0), "Freelancer address cannot be zero");

        escrowCount++;
        escrows[escrowCount] = Escrow({
            client: msg.sender,
            freelancer: freelancer,
            amount: msg.value,
            releasedAmount: 0,
            status: Status.Funded,
            description: description
        });

        emit EscrowCreated(escrowCount, msg.sender, freelancer, msg.value);
    }

    function acceptJob(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == Status.Funded, "Escrow must be in Funded status");

        escrow.status = Status.Accepted;

        emit EscrowAccepted(escrowId, msg.sender);
    }

    function markDelivered(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == Status.Accepted || escrow.status == Status.Funded, "Escrow must be in Funded or Accepted status");

        escrow.status = Status.Delivered;

        emit EscrowDelivered(escrowId, msg.sender);
    }

    function markCompleted(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == Status.Funded || escrow.status == Status.Accepted, "Escrow must be in Funded or Accepted status");

        escrow.status = Status.Delivered;

        emit EscrowDelivered(escrowId, msg.sender);
    }

    function releaseFunds(uint256 escrowId) external escrowExists(escrowId) onlyClient(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Delivered) revert EscrowNotPending();
        if (escrow.releasedAmount != 0) revert EscrowAlreadyResolved();

        escrow.releasedAmount = escrow.amount;
        escrow.status = Status.Released;

        emit FundsReleased(escrowId, escrow.freelancer, escrow.amount);

        (bool freelancerSuccess,) = payable(escrow.freelancer).call{value: escrow.amount}("");
        require(freelancerSuccess, "Transfer to freelancer failed");
    }

    function refund(uint256 escrowId) external escrowExists(escrowId) onlyClient(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Funded && escrow.status != Status.Accepted) revert EscrowAlreadyResolved();

        uint256 refundAmount = escrow.amount;

        escrow.status = Status.Refunded;

        emit EscrowRefunded(escrowId, msg.sender, refundAmount);

        (bool success,) = payable(escrow.client).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
    }

    function raiseDispute(uint256 escrowId) external escrowExists(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (msg.sender != escrow.client && msg.sender != escrow.freelancer) revert NotFreelancer();
        if (escrow.status == Status.Released || escrow.status == Status.Refunded || escrow.status == Status.Disputed) revert EscrowAlreadyResolved();

        escrow.status = Status.Disputed;

        emit EscrowDisputed(escrowId, msg.sender);
    }

    function resolveDispute(uint256 escrowId, address winner) external escrowExists(escrowId) onlyPlatformOwner nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status == Status.Released || escrow.status == Status.Refunded) revert EscrowAlreadyResolved();
        if (winner != escrow.client && winner != escrow.freelancer) revert InvalidWinner();

        if (winner == escrow.freelancer) {
            escrow.releasedAmount = escrow.amount;
            escrow.status = Status.Released;

            emit EscrowDisputeResolved(escrowId, winner, escrow.amount);
            emit FundsReleased(escrowId, escrow.freelancer, escrow.amount);

            (bool freelancerSuccess,) = payable(escrow.freelancer).call{value: escrow.amount}("");
            require(freelancerSuccess, "Transfer to freelancer failed");
            return;
        }

        escrow.status = Status.Refunded;

        emit EscrowDisputeResolved(escrowId, winner, escrow.amount);
        emit EscrowRefunded(escrowId, escrow.client, escrow.amount);

        (bool refundSuccess,) = payable(escrow.client).call{value: escrow.amount}("");
        require(refundSuccess, "Refund transfer failed");
    }

    function getEscrow(uint256 escrowId)
        external
        view
        escrowExists(escrowId)
        returns (address client, address freelancer, uint256 amount, uint256 releasedAmount, Status status, string memory description)
    {
        Escrow storage escrow = escrows[escrowId];

        return (escrow.client, escrow.freelancer, escrow.amount, escrow.releasedAmount, escrow.status, escrow.description);
    }
}

