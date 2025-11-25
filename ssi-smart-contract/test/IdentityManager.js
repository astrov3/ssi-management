const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('IdentityManager', function() {
	let contract, owner, issuer, other, verifier;

	beforeEach(async function() {
		[owner, issuer, other, verifier] = await ethers.getSigners();
		const IdentityManager = await ethers.getContractFactory('IdentityManager');
		contract = await IdentityManager.deploy();
	});

	describe('DID Management', function() {
		it('Should register a new DID', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			const did = await contract.dids(orgID);
			expect(did.owner).to.equal(owner.address);
			expect(did.hashData).to.equal(hash);
			expect(did.uri).to.equal(uri);
			expect(did.active).to.be.true;
		});

		it('Should prevent duplicate DID', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await expect(
				contract.connect(owner).registerDID(orgID, hash, uri),
			).to.be.revertedWith('DID already exists');
		});

		it('Should update DID', async function() {
			const orgID = 'org1';
			const hash1 = ethers.keccak256(ethers.toUtf8Bytes('data1'));
			const hash2 = ethers.keccak256(ethers.toUtf8Bytes('data2'));
			const uri1 = 'ipfs://uri1';
			const uri2 = 'ipfs://uri2';
			await contract.connect(owner).registerDID(orgID, hash1, uri1);
			await contract.connect(owner).updateDID(orgID, hash2, uri2);
			const did = await contract.dids(orgID);
			expect(did.hashData).to.equal(hash2);
			expect(did.uri).to.equal(uri2);
		});

		it('Should prevent update from non-owner', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await expect(
				contract.connect(issuer).updateDID(orgID, hash, uri),
			).to.be.revertedWith('Only owner can perform this action');
		});

		it('Should deactivate DID', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await contract.connect(owner).deactivateDID(orgID);
			const did = await contract.dids(orgID);
			expect(did.active).to.be.false;
		});

		it('Should prevent deactivation from non-owner', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await expect(
				contract.connect(issuer).deactivateDID(orgID),
			).to.be.revertedWith('Only owner can perform this action');
		});
	});

	describe('VC Operations', function() {
		let orgID, hashCredential, uri;

		beforeEach(async () => {
			orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			uri = 'ipfs://uri';
			hashCredential = ethers.keccak256(ethers.toUtf8Bytes('cred'));
			await contract.connect(owner).registerDID(orgID, hash, uri);
		});

		it('Should issue VC', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
			const [h, u, iss, valid, expirationDate, issuedAt, verified, verifierAddr, verifiedAt] = await contract.getVC(orgID, 0);
			expect(h).to.equal(hashCredential);
			expect(u).to.equal(uri);
			expect(iss).to.equal(issuer.address);
			expect(valid).to.be.true;
			expect(expirationDate).to.equal(0); // No expiration by default
			expect(issuedAt).to.be.gt(0); // Should have issuedAt timestamp
			expect(verified).to.be.false; // Not verified by default
			expect(verifierAddr).to.equal(ethers.ZeroAddress); // No verifier by default
			expect(verifiedAt).to.equal(0); // No verification timestamp by default
		});

		it('Should reject VC issuance if DID is inactive', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(owner).deactivateDID(orgID);
			await expect(
				contract.connect(issuer).issueVC(orgID, hashCredential, uri),
			).to.be.revertedWith('DID not active');
		});

		it('Should revoke VC', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
			await contract.connect(owner).revokeVC(orgID, 0);
			const [, , , valid] = await contract.getVC(orgID, 0);
			expect(valid).to.be.false;
		});

		it('Should issue VC with expiration date', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			const futureTimestamp = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
			await contract.connect(issuer).issueVCWithExpiration(orgID, hashCredential, uri, futureTimestamp);
			const [h, u, iss, valid, expirationDate, issuedAt, verified, verifierAddr, verifiedAt] = await contract.getVC(orgID, 0);
			expect(h).to.equal(hashCredential);
			expect(u).to.equal(uri);
			expect(iss).to.equal(issuer.address);
			expect(valid).to.be.true;
			expect(expirationDate).to.equal(futureTimestamp);
			expect(issuedAt).to.be.gt(0);
			expect(verified).to.be.false; // Not verified by default
			expect(verifierAddr).to.equal(ethers.ZeroAddress);
			expect(verifiedAt).to.equal(0);
		});

		it('Should verify VC with expiration date', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			const futureTimestamp = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
			await contract.connect(issuer).issueVCWithExpiration(orgID, hashCredential, uri, futureTimestamp);
			const result = await contract.verifyVC(orgID, 0, hashCredential);
			expect(result).to.be.true;
		});

		it('Should reject expired VC', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			const pastTimestamp = Math.floor(Date.now() / 1000) - 86400; // 24 hours ago
			await contract.connect(issuer).issueVCWithExpiration(orgID, hashCredential, uri, pastTimestamp);
			const result = await contract.verifyVC(orgID, 0, hashCredential);
			expect(result).to.be.false; // Should be false because VC is expired
		});

		it('Should allow VC with no expiration (expirationDate = 0)', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVCWithExpiration(orgID, hashCredential, uri, 0);
			const [, , , valid, expirationDate] = await contract.getVC(orgID, 0);
			expect(valid).to.be.true;
			expect(expirationDate).to.equal(0);
			const result = await contract.verifyVC(orgID, 0, hashCredential);
			expect(result).to.be.true; // Should be valid (no expiration)
		});

		it('Should not allow revoke from non-owner', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
			await expect(
				contract.connect(issuer).revokeVC(orgID, 0),
			).to.be.revertedWith('Only owner can perform this action');
		});

		it('Should verify valid VC', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
			const result = await contract.verifyVC(orgID, 0, hashCredential);
			expect(result).to.be.true;
		});

		it('Should reject invalid or revoked VC', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);

			const wrongHash = ethers.keccak256(ethers.toUtf8Bytes('wrong'));
			expect(await contract.verifyVC(orgID, 0, wrongHash)).to.be.false;

			await contract.connect(owner).revokeVC(orgID, 0);
			expect(await contract.verifyVC(orgID, 0, hashCredential)).to.be.false;
		});

		it('Should reject verification with invalid index', async function() {
			await expect(
				contract.verifyVC(orgID, 0, hashCredential),
			).to.be.revertedWith('Invalid index');
		});

		it('Should return correct VC count using getVCLength', async function() {
			// Ủy quyền issuer
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);

			// Issue 2 VC
			const cred1 = ethers.keccak256(ethers.toUtf8Bytes('cred1'));
			const cred2 = ethers.keccak256(ethers.toUtf8Bytes('cred2'));

			await contract.connect(issuer).issueVC(orgID, cred1, uri);
			await contract.connect(issuer).issueVC(orgID, cred2, uri);

			// Gọi getVCLength và kiểm tra
			const length = await contract.getVCLength(orgID);
			expect(length).to.equal(2);
		});

		it('Should handle mixed VCs with and without expiration', async function() {
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			
			const cred1 = ethers.keccak256(ethers.toUtf8Bytes('cred1'));
			const cred2 = ethers.keccak256(ethers.toUtf8Bytes('cred2'));
			const futureTimestamp = Math.floor(Date.now() / 1000) + 86400;

			// Issue VC without expiration
			await contract.connect(issuer).issueVC(orgID, cred1, uri);
			// Issue VC with expiration
			await contract.connect(issuer).issueVCWithExpiration(orgID, cred2, uri, futureTimestamp);

			const vc1 = await contract.getVC(orgID, 0);
			const vc2 = await contract.getVC(orgID, 1);

			expect(vc1[4]).to.equal(0); // expirationDate = 0 (no expiration)
			expect(vc2[4]).to.equal(futureTimestamp); // expirationDate = futureTimestamp

			// Both should be valid
			expect(await contract.verifyVC(orgID, 0, cred1)).to.be.true;
			expect(await contract.verifyVC(orgID, 1, cred2)).to.be.true;
		});
	});

	describe('Verification System', function() {
		let orgID, hashCredential, uri;

		beforeEach(async () => {
			orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			uri = 'ipfs://uri';
			hashCredential = ethers.keccak256(ethers.toUtf8Bytes('cred'));
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
		});

		it('Should set trusted verifier by admin', async function() {
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			const isTrusted = await contract.trustedVerifiers(verifier.address);
			expect(isTrusted).to.be.true;
		});

		it('Should prevent non-admin from setting trusted verifier', async function() {
			await expect(
				contract.connect(issuer).setTrustedVerifier(verifier.address, true),
			).to.be.revertedWith('Only admin can perform this action');
		});

		it('Should verify credential by trusted verifier', async function() {
			// Set verifier as trusted
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			
			// Verify credential
			await contract.connect(verifier).verifyCredential(orgID, 0);
			
			// Check verification status
			const [, , , , , , verified, verifierAddr, verifiedAt] = await contract.getVC(orgID, 0);
			expect(verified).to.be.true;
			expect(verifierAddr).to.equal(verifier.address);
			expect(verifiedAt).to.be.gt(0);
		});

		it('Should prevent non-trusted verifier from verifying', async function() {
			await expect(
				contract.connect(verifier).verifyCredential(orgID, 0),
			).to.be.revertedWith('Only trusted verifier can perform this action');
		});

		it('Should prevent verifying invalid VC', async function() {
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			await contract.connect(owner).revokeVC(orgID, 0);
			
			await expect(
				contract.connect(verifier).verifyCredential(orgID, 0),
			).to.be.revertedWith('VC is not valid');
		});

		it('Should prevent double verification', async function() {
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			await contract.connect(verifier).verifyCredential(orgID, 0);
			
			await expect(
				contract.connect(verifier).verifyCredential(orgID, 0),
			).to.be.revertedWith('VC already verified');
		});

		it('Should emit VCVerified event', async function() {
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			
			await expect(
				contract.connect(verifier).verifyCredential(orgID, 0)
			).to.emit(contract, 'VCVerified')
				.withArgs(orgID, 0, verifier.address);
		});

		it('Should allow admin to remove trusted verifier', async function() {
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
			await contract.connect(owner).setTrustedVerifier(verifier.address, false);
			
			const isTrusted = await contract.trustedVerifiers(verifier.address);
			expect(isTrusted).to.be.false;
		});

		it('Should allow admin to change admin', async function() {
			await contract.connect(owner).setAdmin(issuer.address);
			const newAdmin = await contract.admin();
			expect(newAdmin).to.equal(issuer.address);
		});

		it('Should prevent setting zero address as admin', async function() {
			await expect(
				contract.connect(owner).setAdmin(ethers.ZeroAddress),
			).to.be.revertedWith('Invalid admin address');
		});
	});

	describe('Verification Request System', function() {
		let orgID, hashCredential, uri;

		beforeEach(async () => {
			orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			uri = 'ipfs://uri';
			hashCredential = ethers.keccak256(ethers.toUtf8Bytes('cred'));
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);
			await contract.connect(issuer).issueVC(orgID, hashCredential, uri);
			await contract.connect(owner).setTrustedVerifier(verifier.address, true);
		});

		it('Should create verification request', async function() {
			const metadataUri = 'ipfs://metadata123';
			const tx = await contract.connect(owner).requestVerification(orgID, 0, verifier.address, metadataUri);
			const receipt = await tx.wait();
			
			// Check event
			const event = receipt.logs.find(log => {
				try {
					const parsed = contract.interface.parseLog(log);
					return parsed.name === 'VerificationRequested';
				} catch {
					return false;
				}
			});
			expect(event).to.not.be.undefined;
			
			// Check request data
			const requestId = await contract.vcRequestId(orgID, 0);
			expect(requestId).to.be.gt(0);
			
			const request = await contract.getVerificationRequest(requestId);
			expect(request[0]).to.equal(orgID); // orgID
			expect(request[1]).to.equal(0); // vcIndex
			expect(request[2]).to.equal(owner.address); // requester
			expect(request[3]).to.equal(verifier.address); // targetVerifier
			expect(request[4]).to.equal(metadataUri); // metadataUri
			expect(request[6]).to.be.false; // processed
		});

		it('Should allow issuer to request verification', async function() {
			const metadataUri = 'ipfs://metadata456';
			await contract.connect(issuer).requestVerification(orgID, 0, verifier.address, metadataUri);
			
			const requestId = await contract.vcRequestId(orgID, 0);
			const request = await contract.getVerificationRequest(requestId);
			expect(request[2]).to.equal(issuer.address); // requester
		});

		it('Should allow request without specific verifier (address(0))', async function() {
			const metadataUri = 'ipfs://metadata789';
			await contract.connect(owner).requestVerification(orgID, 0, ethers.ZeroAddress, metadataUri);
			
			const requestId = await contract.vcRequestId(orgID, 0);
			const request = await contract.getVerificationRequest(requestId);
			expect(request[3]).to.equal(ethers.ZeroAddress); // targetVerifier = any
		});

		it('Should prevent non-owner/non-issuer from requesting verification', async function() {
			await expect(
				contract.connect(other).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata'),
			).to.be.revertedWith('Only DID owner or VC issuer can request verification');
		});

		it('Should prevent requesting verification for invalid VC index', async function() {
			await expect(
				contract.connect(owner).requestVerification(orgID, 999, verifier.address, 'ipfs://metadata'),
			).to.be.revertedWith('Invalid VC index');
		});

		it('Should prevent requesting verification for already verified VC', async function() {
			await contract.connect(verifier).verifyCredential(orgID, 0);
			
			await expect(
				contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata'),
			).to.be.revertedWith('VC already verified');
		});

		it('Should prevent requesting verification for revoked VC', async function() {
			await contract.connect(owner).revokeVC(orgID, 0);
			
			await expect(
				contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata'),
			).to.be.revertedWith('VC is not valid');
		});

		it('Should prevent duplicate unprocessed verification request', async function() {
			await contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata1');
			
			await expect(
				contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata2'),
			).to.be.revertedWith('Verification request already exists');
		});

		it('Should prevent requesting verification with non-trusted verifier', async function() {
			await expect(
				contract.connect(owner).requestVerification(orgID, 0, other.address, 'ipfs://metadata'),
			).to.be.revertedWith('Target verifier is not trusted');
		});

		it('Should cancel verification request', async function() {
			await contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata');
			const requestId = await contract.vcRequestId(orgID, 0);
			
			await contract.connect(owner).cancelVerificationRequest(requestId);
			
			const request = await contract.getVerificationRequest(requestId);
			expect(request[6]).to.be.true; // processed
			
			const hasPending = await contract.hasPendingVerificationRequest(orgID, 0);
			expect(hasPending).to.be.false;
		});

		it('Should prevent non-requester from cancelling request', async function() {
			await contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata');
			const requestId = await contract.vcRequestId(orgID, 0);
			
			await expect(
				contract.connect(other).cancelVerificationRequest(requestId),
			).to.be.revertedWith('Only requester can cancel');
		});

		it('Should verify VC from verification request', async function() {
			const metadataUri = 'ipfs://metadata123';
			await contract.connect(owner).requestVerification(orgID, 0, verifier.address, metadataUri);
			
			// Verifier verifies the credential
			await contract.connect(verifier).verifyCredential(orgID, 0);
			
			// Check VC is verified
			const [, , , , , , verified] = await contract.getVC(orgID, 0);
			expect(verified).to.be.true;
			
			// Check request is processed
			const requestId = await contract.vcRequestId(orgID, 0);
			const request = await contract.getVerificationRequest(requestId);
			expect(request[6]).to.be.true; // processed
		});

		it('Should enforce target verifier restriction', async function() {
			const [anotherVerifier] = await ethers.getSigners();
			await contract.connect(owner).setTrustedVerifier(anotherVerifier.address, true);
			
			await contract.connect(owner).requestVerification(orgID, 0, verifier.address, 'ipfs://metadata');
			
			// Only the target verifier can verify
			await expect(
				contract.connect(anotherVerifier).verifyCredential(orgID, 0),
			).to.be.revertedWith('Only target verifier can verify this request');
			
			// Target verifier can verify
			await contract.connect(verifier).verifyCredential(orgID, 0);
			const [, , , , , , verified] = await contract.getVC(orgID, 0);
			expect(verified).to.be.true;
		});

		it('Should allow any trusted verifier when targetVerifier is address(0)', async function() {
			const [anotherVerifier] = await ethers.getSigners();
			await contract.connect(owner).setTrustedVerifier(anotherVerifier.address, true);
			
			await contract.connect(owner).requestVerification(orgID, 0, ethers.ZeroAddress, 'ipfs://metadata');
			
			// Any trusted verifier can verify
			await contract.connect(anotherVerifier).verifyCredential(orgID, 0);
			const [, , , , , , verified] = await contract.getVC(orgID, 0);
			expect(verified).to.be.true;
		});
	});

	describe('Edge Cases', function() {
		it('Handles multiple VCs', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await contract.connect(owner).authorizeIssuer(orgID, issuer.address);

			const cred1 = ethers.keccak256(ethers.toUtf8Bytes('cred1'));
			const cred2 = ethers.keccak256(ethers.toUtf8Bytes('cred2'));

			await contract.connect(issuer).issueVC(orgID, cred1, uri);
			await contract.connect(issuer).issueVC(orgID, cred2, uri);

			const vc1 = await contract.getVC(orgID, 0);
			const vc2 = await contract.getVC(orgID, 1);

			expect(vc1[0]).to.equal(cred1);
			expect(vc2[0]).to.equal(cred2);
			// Check that both have issuedAt timestamps
			expect(vc1[5]).to.be.gt(0);
			expect(vc2[5]).to.be.gt(0);
			// Check that both are not verified by default
			expect(vc1[6]).to.be.false;
			expect(vc2[6]).to.be.false;
		});

		it('Should reject revoking non-existent VC', async function() {
			const orgID = 'org1';
			const hash = ethers.keccak256(ethers.toUtf8Bytes('data'));
			const uri = 'ipfs://uri';
			await contract.connect(owner).registerDID(orgID, hash, uri);
			await expect(
				contract.connect(owner).revokeVC(orgID, 0),
			).to.be.revertedWith('Invalid index');
		});
	});
});
