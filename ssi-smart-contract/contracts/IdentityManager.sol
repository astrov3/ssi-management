// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IdentityManager {
    struct DID {
        address owner;
        bytes32 hashData;
        string uri;
        bool active;
    }

    struct VC {
        bytes32 hashCredential;
        string uri;
        address issuer;
        bool valid;
    }

    mapping(string => DID) public dids;
    mapping(string => VC[]) public credentials;
    mapping(string => mapping(address => bool)) public authorizedIssuers;

    event DIDRegistered(string orgID, address owner);
    event VCCreated(string orgID, bytes32 hashCredential, address issuer);
    event VCRevoked(string orgID, uint index);
    event IssuerAuthorized(string orgID, address issuer);

    modifier onlyOwner(string memory orgID) {
        require(dids[orgID].owner == msg.sender, "Only owner can perform this action");
        _;
    }

    // Đăng ký DID
    function registerDID(string memory orgID, bytes32 hashData, string memory uri) external {
        require(dids[orgID].owner == address(0), "DID already exists");
        dids[orgID] = DID(msg.sender, hashData, uri, true);
        emit DIDRegistered(orgID, msg.sender);
    }

    // Cập nhật DID
    function updateDID(string memory orgID, bytes32 newHash, string memory newUri) external onlyOwner(orgID) {
        dids[orgID].hashData = newHash;
        dids[orgID].uri = newUri;
    }

    // Hủy kích hoạt DID
    function deactivateDID(string memory orgID) external onlyOwner(orgID) {
        dids[orgID].active = false;
    }

    // Ủy quyền cho issuer
    function authorizeIssuer(string memory orgID, address issuer) external onlyOwner(orgID) {
        authorizedIssuers[orgID][issuer] = true;
        emit IssuerAuthorized(orgID, issuer);
    }

    // Phát hành VC
    function issueVC(string memory orgID, bytes32 hashCredential, string memory uri) external {
        require(dids[orgID].active, "DID not active");
        require(
            authorizedIssuers[orgID][msg.sender] || msg.sender == dids[orgID].owner,
            "Only authorized issuers or owner can issue VC"
        );
        credentials[orgID].push(VC(hashCredential, uri, msg.sender, true));
        emit VCCreated(orgID, hashCredential, msg.sender);
    }

    // Thu hồi VC
    function revokeVC(string memory orgID, uint index) external onlyOwner(orgID) {
        require(index < credentials[orgID].length, "Invalid index");
        credentials[orgID][index].valid = false;
        emit VCRevoked(orgID, index);
    }

    // Xác minh VC
    function verifyVC(string memory orgID, uint index, bytes32 providedHash) external view returns (bool) {
        require(index < credentials[orgID].length, "Invalid index");
        VC memory vc = credentials[orgID][index];
        return vc.valid && vc.hashCredential == providedHash;
    }

    // Getter VC
    function getVC(string memory orgID, uint index) external view returns (
        bytes32 hashCredential,
        string memory uri,
        address issuer,
        bool valid
    ) {
        require(index < credentials[orgID].length, "Invalid index");
        VC memory vc = credentials[orgID][index];
        return (vc.hashCredential, vc.uri, vc.issuer, vc.valid);
    }

    function getVCLength(string memory orgID) external view returns (uint) {
        return credentials[orgID].length;
    }
}
