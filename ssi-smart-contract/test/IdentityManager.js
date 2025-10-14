const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('IdentityManager', function() {
	let contract, owner, issuer, other;

	beforeEach(async function() {
		[owner, issuer, other] = await ethers.getSigners();
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
			const [h, u, iss, valid] = await contract.getVC(orgID, 0);
			expect(h).to.equal(hashCredential);
			expect(u).to.equal(uri);
			expect(iss).to.equal(issuer.address);
			expect(valid).to.be.true;
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
