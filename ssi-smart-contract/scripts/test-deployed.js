const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
	const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);

	// Signers
	const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);
	const issuer = new ethers.Wallet(process.env.ISSUER_PRIVATE_KEY, provider);

	// Load ABI
	const abi = require('../artifacts/contracts/IdentityManager.sol/IdentityManager.json')
		.abi;

	// Contract instance connected with owner (for owner actions)
	const contractOwner = new ethers.Contract(
		process.env.CONTRACT_ADDRESS,
		abi,
		owner,
	);
	// Contract instance connected with issuer (for issuer actions)
	const contractIssuer = new ethers.Contract(
		process.env.CONTRACT_ADDRESS,
		abi,
		issuer,
	);

	// Test data
	const orgID = 'orgID_' + Date.now();
	const hashData = ethers.keccak256(ethers.toUtf8Bytes('offchainData'));
	const uri = 'ipfs://testUri';
	const hashVC = ethers.keccak256(
		ethers.toUtf8Bytes('verifiableCredentialData'),
	);

	console.log('--- STEP 1: Check DID existence ---');
	const did = await contractOwner.dids(orgID);
	console.log('DID active:', did.active);

	if (!did.active) {
		console.log('--- STEP 2: Register DID ---');
		const tx = await contractOwner.registerDID(orgID, hashData, uri);
		await tx.wait();
		console.log('✅ DID registered');
	} else {
		console.log('✅ DID already exists');
	}

	console.log('--- STEP 3: Authorize Issuer ---');
	const isAuthorized = await contractOwner.authorizedIssuers(
		orgID,
		issuer.address,
	);
	if (!isAuthorized) {
		const txAuth = await contractOwner.authorizeIssuer(orgID, issuer.address);
		await txAuth.wait();
		console.log(`✅ Issuer ${issuer.address} authorized`);
	} else {
		console.log('✅ Issuer already authorized');
	}

	console.log('--- STEP 4: Issue VC ---');
	const txIssue = await contractIssuer.issueVC(orgID, hashVC, uri);
	await txIssue.wait();
	console.log('✅ VC issued by issuer');

	console.log('--- STEP 5: Verify VC ---');
	const valid = await contractOwner.verifyVC(orgID, 0, hashVC);
	console.log('✅ VC valid:', valid);

	console.log('--- STEP 6: Get VC Length ---');
	const vcLength = await contractOwner.getVCLength(orgID);
	console.log('✅ VC length:', vcLength.toString());

	console.log('--- STEP 7: Revoke VC ---');
	const txRevoke = await contractOwner.revokeVC(orgID, 0);
	await txRevoke.wait();
	console.log('✅ VC revoked');

	console.log('--- STEP 8: Verify VC after revoke ---');
	const validAfterRevoke = await contractOwner.verifyVC(orgID, 0, hashVC);
	console.log('✅ VC valid after revoke:', validAfterRevoke);
}

main().catch(err => {
	console.error('❌ Error:', err.reason || err.message || err);
});
