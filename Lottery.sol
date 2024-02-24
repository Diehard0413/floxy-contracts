// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Lottery is Ownable {
    struct Project {
        uint256 totalParticipants;
        uint256 totalWinners;
        address[] participants;
        address[] winners;
        bool isActivated;
    }

    uint256 private nonce = 0;
    mapping(uint256 => Project) private projects;
    mapping(uint256 => mapping(address => bool)) private participated;
    mapping(uint256 => mapping(uint256 => bool)) private selected;

    event ProjectCreated(uint256 projectId, uint256 totalParticipants, uint256 totalWinners);
    event ParticipantAdded(uint256 projectId, address[] participants);
    event WinnersSelected(uint256 projectId, address[] winners);

    constructor() Ownable(msg.sender) {}

    // Function to create a new project
    function createProject(uint256 projectId, uint256 totalParticipants, uint256 totalWinners) external onlyOwner {
        require(!projects[projectId].isActivated, "Project already exists");

        projects[projectId].totalParticipants = totalParticipants;
        projects[projectId].totalWinners = totalWinners;
        projects[projectId].isActivated = true;
        emit ProjectCreated(projectId, totalParticipants, totalWinners);
    }

    // Function to add a participant to a project
    function joinProject(uint256 projectId) external {
        require(projects[projectId].isActivated, "Project does not exist");
        require(projects[projectId].participants.length < projects[projectId].totalParticipants, "Project is filled");
        require(!participated[projectId][msg.sender], "Already participated");

        projects[projectId].participants.push(msg.sender);
        participated[projectId][msg.sender] = true;
        emit ParticipantAdded(projectId, projects[projectId].participants);
    }

    // Function to choose winners for a project
    function chooseWinners(uint256 projectId) external onlyOwner {
        require(projects[projectId].isActivated, "Project does not exist");
        require(projects[projectId].participants.length >= projects[projectId].totalWinners, "Not enough participants");

        uint256 winnersCount = 0;

        while (winnersCount < projects[projectId].totalWinners) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % projects[projectId].participants.length;
            nonce++;

            if (!selected[projectId][randomIndex]) {
                selected[projectId][randomIndex] = true;
                projects[projectId].winners.push(projects[projectId].participants[randomIndex]);
                winnersCount++;
            }
        }

        projects[projectId].isActivated = false;
        emit WinnersSelected(projectId, projects[projectId].winners);
    }

    function getProject(uint256 projectId) external view returns (
        uint256 totalParticipants,
        uint256 totalWinners,
        address[] memory participants,
        address[] memory winners,
        bool isActivated
    ) {
        Project memory project = projects[projectId];
        return (
            project.totalParticipants,
            project.totalWinners,
            project.participants,
            project.winners,
            project.isActivated
        );
    }
}
