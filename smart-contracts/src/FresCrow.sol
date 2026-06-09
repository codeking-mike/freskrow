// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FresCrow is ReentrancyGuard {
    enum Status {
        Created,
        Funded,
        InProgress,
        Delivered,
        Completed,
        Refunded,
        Disputed,
        Released,
        Cancelled
    }

    struct Escrow {
        uint256 id;
        address client;
        address freelancer;
        uint256 amount;
        uint256 releasedAmount;
        Status status;
        string title;
        uint256 createdAt;
        uint256 completedAt;
    }

    event EscrowCreated(uint256 indexed escrowId, address indexed client, address indexed freelancer, uint256 amount, string title);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event EscrowAccepted(uint256 indexed escrowId, address indexed freelancer);
    event EscrowDelivered(uint256 indexed escrowId, address indexed freelancer);
    event EscrowCompleted(uint256 indexed escrowId, address indexed freelancer);
    event FundsReleased(uint256 indexed escrowId, address indexed freelancer, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed client, uint256 amount);
    event EscrowDisputed(uint256 indexed escrowId, address indexed reporter);
    event EscrowDisputeResolved(uint256 indexed escrowId, address indexed winner, uint256 amount);

    error NotClient();
    error NotFreelancer();
    error NotClientOrFreelancer();
    error EscrowNotFound();
    error EscrowAlreadyResolved();
    error EscrowNotPending();
    error InvalidWinner();
    error InvalidAmount();
    error TransferFailed();
    error Unauthorized();
    error InvalidFreelancer();
    error InvalidStatus();

    address public immutable PLATFORM_OWNER;
    uint256 public constant FEE_PERCENTAGE = 1; // Platform fee percentage
    uint256 public escrowCount;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public clientEscrows;
    mapping(address => uint256[]) public freelancerEscrows;

    function _onlyPlatformOwner() internal view {
        if (msg.sender != PLATFORM_OWNER) revert Unauthorized();
    }

    modifier onlyPlatformOwner() {
        _onlyPlatformOwner();
        _;
    }

    function _escrowExists(uint256 escrowId) internal view {
        if (escrows[escrowId].client == address(0)) revert EscrowNotFound();
    }

    modifier escrowExists(uint256 escrowId) {
        _escrowExists(escrowId);
        _;
    }

    function _onlyClient(uint256 escrowId) internal view {
        if (msg.sender != escrows[escrowId].client) revert NotClient();
    }

    modifier onlyClient(uint256 escrowId) {
        _onlyClient(escrowId);
        _;
    }

    function _onlyFreelancer(uint256 escrowId) internal view {
        if (msg.sender != escrows[escrowId].freelancer) revert NotFreelancer();
    }

    modifier onlyFreelancer(uint256 escrowId) {
        _onlyFreelancer(escrowId);
        _;
    }

    constructor(address _platformOwner) {
        if (_platformOwner == address(0)) revert Unauthorized();
        PLATFORM_OWNER = _platformOwner;
    }

    function createEscrow(address _freelancer, string calldata _title) external {
        if (_freelancer == address(0)) revert InvalidFreelancer();

        unchecked {
            escrowCount++;
        }

        Escrow storage escrow = escrows[escrowCount];
        escrow.id = escrowCount;
        escrow.client = msg.sender;
        escrow.freelancer = _freelancer;
        escrow.title = _title;
        escrow.amount = 0;
        escrow.status = Status.Created;
        escrow.createdAt = block.timestamp;

        clientEscrows[msg.sender].push(escrowCount);
        freelancerEscrows[_freelancer].push(escrowCount);

        emit EscrowCreated(escrowCount, msg.sender, _freelancer, 0, _title);
    }

    function fundEscrow(uint256 _escrowId) external payable escrowExists(_escrowId) onlyClient(_escrowId) nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        if (msg.value == 0) revert InvalidAmount();
        if (escrow.status != Status.Created) revert InvalidStatus();

        escrow.amount = msg.value;
        escrow.status = Status.Funded;

        emit EscrowFunded(_escrowId, msg.value);
    }

    function acceptJob(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Funded) revert InvalidStatus();

        escrow.status = Status.InProgress;

        emit EscrowAccepted(escrowId, msg.sender);
    }

    function markDelivered(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.InProgress) revert InvalidStatus();

        escrow.status = Status.Delivered;

        emit EscrowDelivered(escrowId, msg.sender);
    }

    function markCompleted(uint256 escrowId) external escrowExists(escrowId) onlyFreelancer(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Delivered) revert InvalidStatus();

        escrow.status = Status.Completed;
        escrow.completedAt = block.timestamp;

        emit EscrowCompleted(escrowId, msg.sender);
    }

    function releaseFunds(uint256 _escrowId) external nonReentrant escrowExists(_escrowId) onlyClient(_escrowId) {
        Escrow storage escrow = escrows[_escrowId];
        if (escrow.status != Status.Completed) revert InvalidStatus();

        uint256 amount = escrow.amount;
        escrow.amount = 0;
        escrow.releasedAmount = amount;
        escrow.status = Status.Released;
        escrow.completedAt = block.timestamp;

        (bool success, ) = payable(escrow.freelancer).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsReleased(_escrowId, escrow.freelancer, amount);
    }

    function refund(uint256 escrowId) external escrowExists(escrowId) onlyClient(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Created && escrow.status != Status.Funded && escrow.status != Status.InProgress) revert EscrowNotPending();

        uint256 refundAmount = escrow.amount;
        escrow.amount = 0;
        escrow.status = escrow.status == Status.Created ? Status.Cancelled : Status.Refunded;

        emit EscrowRefunded(escrowId, msg.sender, refundAmount);

        if (refundAmount > 0) {
            (bool success, ) = payable(escrow.client).call{value: refundAmount}("");
            if (!success) revert TransferFailed();
        }
    }

    function raiseDispute(uint256 escrowId) external escrowExists(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (msg.sender != escrow.client && msg.sender != escrow.freelancer) revert NotClientOrFreelancer();
        if (escrow.status == Status.Released || escrow.status == Status.Refunded || escrow.status == Status.Disputed) revert EscrowAlreadyResolved();

        escrow.status = Status.Disputed;

        emit EscrowDisputed(escrowId, msg.sender);
    }

    function resolveDispute(uint256 escrowId, address winner) external escrowExists(escrowId) onlyPlatformOwner nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.status != Status.Disputed) revert InvalidStatus();
        if (winner != escrow.client && winner != escrow.freelancer) revert InvalidWinner();

        if (winner == escrow.freelancer) {
            uint256 amount = escrow.amount;
            escrow.amount = 0;
            escrow.releasedAmount = amount;
            escrow.status = Status.Released;

            emit EscrowDisputeResolved(escrowId, winner, amount);
            emit FundsReleased(escrowId, escrow.freelancer, amount);

            (bool freelancerSuccess, ) = payable(escrow.freelancer).call{value: amount}("");
            if (!freelancerSuccess) revert TransferFailed();
            return;
        }

        uint256 refundAmount = escrow.amount;
        escrow.amount = 0;
        escrow.status = Status.Refunded;

        emit EscrowDisputeResolved(escrowId, winner, refundAmount);
        emit EscrowRefunded(escrowId, escrow.client, refundAmount);

        (bool refundSuccess, ) = payable(escrow.client).call{value: refundAmount}("");
        if (!refundSuccess) revert TransferFailed();
    }

    function getEscrow(uint256 escrowId)
        external
        view
        escrowExists(escrowId)
        returns (address client, address freelancer, uint256 amount, uint256 releasedAmount, Status status, string memory title)
    {
        Escrow storage escrow = escrows[escrowId];
        return (escrow.client, escrow.freelancer, escrow.amount, escrow.releasedAmount, escrow.status, escrow.title);
    }

    function getClientEscrows(address _client) external view returns (uint256[] memory) {
        return clientEscrows[_client];
    }

    function getFreelancerEscrows(address _freelancer) external view returns (uint256[] memory) {
        return freelancerEscrows[_freelancer];
    }
}

