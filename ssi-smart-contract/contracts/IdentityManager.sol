// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IdentityManager {
    constructor() {
        admin = msg.sender;  // Người deploy contract là admin đầu tiên
    }

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
        uint256 expirationDate;  // Unix timestamp, 0 means no expiration
        uint256 issuedAt;        // Unix timestamp
        bool verified;            // Đã được xác thực bởi cơ quan cấp cao
        address verifier;         // Địa chỉ của cơ quan đã xác thực
        uint256 verifiedAt;       // Thời điểm xác thực (Unix timestamp)
    }

    struct VerificationRequest {
        string orgID;
        uint256 vcIndex;
        address requester;        // Người yêu cầu xác thực (chủ sở hữu VC)
        address targetVerifier;   // Cơ quan xác thực được yêu cầu (address(0) = bất kỳ verifier nào)
        string metadataUri;       // URI đến metadata/file/link trên IPFS chứa thông tin cần xác thực
        uint256 requestedAt;      // Thời điểm yêu cầu
        bool processed;           // Đã được xử lý (verified hoặc rejected)
    }

    mapping(string => DID) public dids;
    mapping(string => VC[]) public credentials;
    mapping(string => mapping(address => bool)) public authorizedIssuers;
    mapping(address => bool) public trustedVerifiers;  // Các cơ quan được phép xác thực VC
    mapping(uint256 => VerificationRequest) public verificationRequests;  // Mapping request ID -> request
    mapping(string => mapping(uint256 => uint256)) public vcRequestId;  // Mapping orgID + vcIndex -> request ID
    uint256 public nextRequestId;  // Counter cho request ID
    address public admin;  // Admin có quyền quản lý trusted verifiers

    event DIDRegistered(string orgID, address owner);
    event VCCreated(string orgID, bytes32 hashCredential, address issuer);
    event VCRevoked(string orgID, uint index);
    event IssuerAuthorized(string orgID, address issuer);
    event VCVerified(string orgID, uint index, address verifier);
    event TrustedVerifierSet(address verifier, bool allowed);
    event VerificationRequested(uint256 requestId, string orgID, uint256 vcIndex, address requester, address targetVerifier, string metadataUri);
    event VerificationRequestCancelled(uint256 requestId);

    modifier onlyOwner(string memory orgID) {
        require(dids[orgID].owner == msg.sender, "Only owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyTrustedVerifier() {
        require(trustedVerifiers[msg.sender], "Only trusted verifier can perform this action");
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
        issueVCWithExpiration(orgID, hashCredential, uri, 0);
    }

    // Phát hành VC với expiration date
    function issueVCWithExpiration(
        string memory orgID,
        bytes32 hashCredential,
        string memory uri,
        uint256 expirationDate
    ) public {
        require(dids[orgID].active, "DID not active");
        require(
            authorizedIssuers[orgID][msg.sender] || msg.sender == dids[orgID].owner,
            "Only authorized issuers or owner can issue VC"
        );
        credentials[orgID].push(VC(
            hashCredential,
            uri,
            msg.sender,
            true,
            expirationDate,
            block.timestamp,
            false,  // verified = false khi mới tạo
            address(0),  // verifier = address(0) khi chưa được xác thực
            0  // verifiedAt = 0 khi chưa được xác thực
        ));
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
        
        // Check if VC is valid
        if (!vc.valid) {
            return false;
        }
        
        // Check if VC is expired (expirationDate > 0 means it has expiration)
        if (vc.expirationDate > 0 && block.timestamp > vc.expirationDate) {
            return false;
        }
        
        // Check if hash matches
        return vc.hashCredential == providedHash;
    }

    function getVCLength(string memory orgID) external view returns (uint) {
        return credentials[orgID].length;
    }

    // Thiết lập trusted verifier (chỉ admin)
    function setTrustedVerifier(address verifier, bool allowed) external onlyAdmin {
        trustedVerifiers[verifier] = allowed;
        emit TrustedVerifierSet(verifier, allowed);
    }

    // Thay đổi admin (chỉ admin hiện tại)
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }

    // Yêu cầu xác thực VC on-chain (chủ sở hữu VC)
    function requestVerification(
        string memory orgID,
        uint256 vcIndex,
        address targetVerifier,
        string memory metadataUri
    ) external {
        require(vcIndex < credentials[orgID].length, "Invalid VC index");
        VC memory vc = credentials[orgID][vcIndex];
        
        require(vc.valid, "VC is not valid");
        require(!vc.verified, "VC already verified");
        
        // Chỉ chủ sở hữu DID hoặc issuer của VC mới có thể yêu cầu xác thực
        require(
            msg.sender == dids[orgID].owner || msg.sender == vc.issuer,
            "Only DID owner or VC issuer can request verification"
        );
        
        // Kiểm tra xem đã có request chưa được xử lý chưa
        uint256 existingRequestId = vcRequestId[orgID][vcIndex];
        if (existingRequestId > 0) {
            VerificationRequest memory existingRequest = verificationRequests[existingRequestId];
            require(existingRequest.processed, "Verification request already exists");
        }
        
        // Nếu chỉ định targetVerifier, phải là trusted verifier
        if (targetVerifier != address(0)) {
            require(trustedVerifiers[targetVerifier], "Target verifier is not trusted");
        }
        
        // Tạo request mới
        uint256 requestId = ++nextRequestId;
        verificationRequests[requestId] = VerificationRequest(
            orgID,
            vcIndex,
            msg.sender,
            targetVerifier,
            metadataUri,
            block.timestamp,
            false
        );
        
        vcRequestId[orgID][vcIndex] = requestId;
        
        emit VerificationRequested(requestId, orgID, vcIndex, msg.sender, targetVerifier, metadataUri);
    }

    // Hủy yêu cầu xác thực (chỉ người yêu cầu)
    function cancelVerificationRequest(uint256 requestId) external {
        VerificationRequest storage request = verificationRequests[requestId];
        require(request.requester == msg.sender, "Only requester can cancel");
        require(!request.processed, "Request already processed");
        
        request.processed = true;
        vcRequestId[request.orgID][request.vcIndex] = 0;
        
        emit VerificationRequestCancelled(requestId);
    }

    // Xác thực VC bởi cơ quan cấp cao (trusted verifier)
    // Có thể xác thực trực tiếp hoặc từ verification request
    function verifyCredential(string memory orgID, uint index) external onlyTrustedVerifier {
        require(index < credentials[orgID].length, "Invalid index");
        VC storage vc = credentials[orgID][index];
        
        require(vc.valid, "VC is not valid");
        require(!vc.verified, "VC already verified");
        
        // Nếu có verification request, kiểm tra xem verifier có phù hợp không
        uint256 requestId = vcRequestId[orgID][index];
        if (requestId > 0) {
            VerificationRequest memory request = verificationRequests[requestId];
            require(!request.processed, "Verification request already processed");
            
            // Nếu request chỉ định targetVerifier, chỉ verifier đó mới có thể xác thực
            if (request.targetVerifier != address(0)) {
                require(msg.sender == request.targetVerifier, "Only target verifier can verify this request");
            }
            
            // Đánh dấu request đã được xử lý
            verificationRequests[requestId].processed = true;
        }
        
        vc.verified = true;
        vc.verifier = msg.sender;
        vc.verifiedAt = block.timestamp;
        
        emit VCVerified(orgID, index, msg.sender);
    }

    // Getter VC với đầy đủ thông tin bao gồm verification status
    function getVC(string memory orgID, uint index) external view returns (
        bytes32 hashCredential,
        string memory uri,
        address issuer,
        bool valid,
        uint256 expirationDate,
        uint256 issuedAt,
        bool verified,
        address verifier,
        uint256 verifiedAt
    ) {
        require(index < credentials[orgID].length, "Invalid index");
        VC memory vc = credentials[orgID][index];
        return (
            vc.hashCredential,
            vc.uri,
            vc.issuer,
            vc.valid,
            vc.expirationDate,
            vc.issuedAt,
            vc.verified,
            vc.verifier,
            vc.verifiedAt
        );
    }

    // Lấy thông tin verification request theo request ID
    function getVerificationRequest(uint256 requestId) external view returns (
        string memory orgID,
        uint256 vcIndex,
        address requester,
        address targetVerifier,
        string memory metadataUri,
        uint256 requestedAt,
        bool processed
    ) {
        VerificationRequest memory request = verificationRequests[requestId];
        require(request.requester != address(0), "Request not found");
        return (
            request.orgID,
            request.vcIndex,
            request.requester,
            request.targetVerifier,
            request.metadataUri,
            request.requestedAt,
            request.processed
        );
    }

    // Lấy request ID của VC (nếu có)
    function getVCRequestId(string memory orgID, uint256 vcIndex) external view returns (uint256) {
        return vcRequestId[orgID][vcIndex];
    }

    // Kiểm tra xem VC có đang có verification request chưa được xử lý không
    function hasPendingVerificationRequest(string memory orgID, uint256 vcIndex) external view returns (bool) {
        uint256 requestId = vcRequestId[orgID][vcIndex];
        if (requestId == 0) return false;
        VerificationRequest memory request = verificationRequests[requestId];
        return !request.processed;
    }
}
