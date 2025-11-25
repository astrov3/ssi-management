const { ethers } = require('ethers');
require('dotenv').config();

// Helper function for assertions
function assert(condition, message) {
	if (!condition) {
		throw new Error(`Assertion failed: ${message}`);
	}
}

async function main() {
	const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);

	// Signers
	const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);
	const issuer = new ethers.Wallet(process.env.ISSUER_PRIVATE_KEY, provider);
	// Verifier: use VERIFIER_PRIVATE_KEY if available, otherwise use issuer as verifier
	// Note: If using issuer as verifier, make sure issuer is set as trusted verifier
	const verifier = process.env.VERIFIER_PRIVATE_KEY 
		? new ethers.Wallet(process.env.VERIFIER_PRIVATE_KEY, provider)
		: issuer; // Fallback to issuer if no verifier key provided

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
	// Contract instance connected with verifier (for verifier actions)
	const contractVerifier = new ethers.Contract(
		process.env.CONTRACT_ADDRESS,
		abi,
		verifier,
	);
	// Contract instance for admin (deployer is admin)
	const deployer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
	const contractAdmin = new ethers.Contract(
		process.env.CONTRACT_ADDRESS,
		abi,
		deployer,
	);

	// Test data
	const orgID = 'orgID_' + Date.now();
	const hashData = ethers.keccak256(ethers.toUtf8Bytes('offchainData'));
	const uri = 'ipfs://testUri';
	const hashVC = ethers.keccak256(
		ethers.toUtf8Bytes('verifiableCredentialData'),
	);

	// Track contract version
	let hasVerificationFields = false;

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

	console.log('--- STEP 4: Issue VC (no expiration) ---');
	const txIssue = await contractIssuer.issueVC(orgID, hashVC, uri);
	await txIssue.wait();
	console.log('✅ VC issued by issuer');

	console.log('--- STEP 5: Get VC and check fields ---');
	let vc;
	try {
		vc = await contractOwner.getVC(orgID, 0);
		// Check if contract has new fields (9 values) or old fields (6 values)
		hasVerificationFields = vc.length >= 9;
	} catch (error) {
		if (error.message.includes('BAD_DATA') || error.code === 'BAD_DATA') {
			console.log('⚠️  Contract version mismatch detected!');
			console.log('⚠️  Old contract returns 6 values, new contract returns 9 values');
			console.log('⚠️  Attempting to decode with old signature...');
			
			// Try to decode manually with old signature (6 values)
			try {
				const oldAbi = [
					{
						"inputs": [
							{"internalType": "string", "name": "orgID", "type": "string"},
							{"internalType": "uint256", "name": "index", "type": "uint256"}
						],
						"name": "getVC",
						"outputs": [
							{"internalType": "bytes32", "name": "hashCredential", "type": "bytes32"},
							{"internalType": "string", "name": "uri", "type": "string"},
							{"internalType": "address", "name": "issuer", "type": "address"},
							{"internalType": "bool", "name": "valid", "type": "bool"},
							{"internalType": "uint256", "name": "expirationDate", "type": "uint256"},
							{"internalType": "uint256", "name": "issuedAt", "type": "uint256"}
						],
						"stateMutability": "view",
						"type": "function"
					}
				];
				const oldContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, oldAbi, provider);
				vc = await oldContract.getVC(orgID, 0);
				hasVerificationFields = false;
				console.log('✅ Successfully decoded with old signature');
			} catch (decodeError) {
				console.error('❌ Failed to decode with old signature:', decodeError.message);
				console.log('⚠️  Please redeploy contract with updated getVC signature to test all features');
				throw new Error('Contract version mismatch. Please redeploy contract with new getVC signature.');
			}
		} else {
			throw error;
		}
	}
	
	console.log('VC Hash:', vc[0]);
	console.log('VC URI:', vc[1]);
	console.log('VC Issuer:', vc[2]);
	console.log('VC Valid:', vc[3]);
	console.log('VC Expiration Date:', vc[4].toString(), '(0 = no expiration)');
	console.log('VC Issued At:', vc[5].toString(), `(${new Date(Number(vc[5]) * 1000).toISOString()})`);
	
	if (hasVerificationFields) {
		console.log('VC Verified:', vc[6]);
		console.log('VC Verifier:', vc[7]);
		console.log('VC Verified At:', vc[8].toString(), vc[8] === 0n ? '(not verified yet)' : `(${new Date(Number(vc[8]) * 1000).toISOString()})`);
		console.log('✅ Contract has verification fields (new version)');
	} else {
		console.log('⚠️  Contract does not have verification fields (old version)');
		console.log('⚠️  Some verification tests will be skipped');
	}
	
	assert(vc[4] === 0n, 'expirationDate should be 0');
	assert(vc[5] > 0n, 'issuedAt should be greater than 0');
	console.log('✅ VC fields verified');

	console.log('--- STEP 6: Verify VC ---');
	const valid = await contractOwner.verifyVC(orgID, 0, hashVC);
	console.log('✅ VC valid:', valid);
	assert(valid === true, 'VC should be valid');

	console.log('--- STEP 7: Issue VC with expiration date ---');
	const futureTimestamp = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
	const hashVC2 = ethers.keccak256(ethers.toUtf8Bytes('verifiableCredentialData2'));
	const txIssue2 = await contractIssuer.issueVCWithExpiration(orgID, hashVC2, uri, futureTimestamp);
	await txIssue2.wait();
	console.log(`✅ VC with expiration date issued (expires: ${new Date(futureTimestamp * 1000).toISOString()})`);

	console.log('--- STEP 8: Get VC with expiration and check fields ---');
	let vc2;
	try {
		vc2 = await contractOwner.getVC(orgID, 1);
	} catch (error) {
		if (error.message.includes('BAD_DATA') || error.code === 'BAD_DATA') {
			// Use old ABI to decode
			const oldAbi = [
				{
					"inputs": [
						{"internalType": "string", "name": "orgID", "type": "string"},
						{"internalType": "uint256", "name": "index", "type": "uint256"}
					],
					"name": "getVC",
					"outputs": [
						{"internalType": "bytes32", "name": "hashCredential", "type": "bytes32"},
						{"internalType": "string", "name": "uri", "type": "string"},
						{"internalType": "address", "name": "issuer", "type": "address"},
						{"internalType": "bool", "name": "valid", "type": "bool"},
						{"internalType": "uint256", "name": "expirationDate", "type": "uint256"},
						{"internalType": "uint256", "name": "issuedAt", "type": "uint256"}
					],
					"stateMutability": "view",
					"type": "function"
				}
			];
			const oldContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, oldAbi, provider);
			vc2 = await oldContract.getVC(orgID, 1);
		} else {
			throw error;
		}
	}
	console.log('VC Expiration Date:', vc2[4].toString(), `(${new Date(Number(vc2[4]) * 1000).toISOString()})`);
	console.log('VC Issued At:', vc2[5].toString(), `(${new Date(Number(vc2[5]) * 1000).toISOString()})`);
	if (vc2.length >= 9) {
		console.log('VC Verified:', vc2[6]);
		console.log('VC Verifier:', vc2[7]);
		console.log('VC Verified At:', vc2[8].toString());
	}
	assert(Number(vc2[4]) === futureTimestamp, 'expirationDate should match futureTimestamp');
	assert(vc2[5] > 0n, 'issuedAt should be greater than 0');
	console.log('✅ VC with expiration fields verified');

	console.log('--- STEP 9: Verify VC with expiration ---');
	const valid2 = await contractOwner.verifyVC(orgID, 1, hashVC2);
	console.log('✅ VC with expiration valid:', valid2);
	assert(valid2 === true, 'VC with expiration should be valid');

	console.log('--- STEP 10: Get VC Length ---');
	const vcLength = await contractOwner.getVCLength(orgID);
	console.log('✅ VC length:', vcLength.toString());
	assert(Number(vcLength) === 2, 'VC length should be 2');

	console.log('--- STEP 11: Test expired VC (if time allows) ---');
	// Note: This would require waiting for expiration, so we'll just test the logic
	// In a real scenario, you'd need to wait or use time manipulation
	console.log('ℹ️  Expired VC test skipped (would require time manipulation)');

	console.log('--- STEP 12: Revoke VC ---');
	const txRevoke = await contractOwner.revokeVC(orgID, 0);
	await txRevoke.wait();
	console.log('✅ VC revoked');

	console.log('--- STEP 13: Verify VC after revoke ---');
	const validAfterRevoke = await contractOwner.verifyVC(orgID, 0, hashVC);
	console.log('✅ VC valid after revoke:', validAfterRevoke);
	assert(validAfterRevoke === false, 'VC should be invalid after revoke');

	console.log('\n=== VERIFICATION SYSTEM TESTS ===\n');

	// Check if contract has verification features
	let hasVerificationFeatures = hasVerificationFields;
	if (!hasVerificationFeatures) {
		try {
			const admin = await contractOwner.admin();
			hasVerificationFeatures = true;
			console.log('✅ Contract has admin field');
		} catch (error) {
			console.log('⚠️  Contract does not have verification features (old version)');
			hasVerificationFeatures = false;
		}
	}

	if (!hasVerificationFeatures) {
		console.log('⚠️  Skipping verification system tests');
		console.log('⚠️  Please redeploy contract to enable verification features');
		console.log('\n=== SUMMARY ===');
		console.log('✅ All basic VC operations tested');
		console.log('⚠️  Verification system tests skipped (contract is old version)');
		console.log('⚠️  Please redeploy contract to test verification features');
		return;
	}

	console.log('--- STEP 14: Check Admin ---');
	const admin = await contractOwner.admin();
	console.log('Admin address:', admin);
	console.log('Deployer address:', deployer.address);
	assert(admin.toLowerCase() === deployer.address.toLowerCase(), 'Deployer should be admin');
	console.log('✅ Admin verified');

	console.log('--- STEP 15: Set Trusted Verifier ---');
	const isTrustedBefore = await contractOwner.trustedVerifiers(verifier.address);
	console.log('Verifier trusted before:', isTrustedBefore);
	if (!isTrustedBefore) {
		const txSetVerifier = await contractAdmin.setTrustedVerifier(verifier.address, true);
		await txSetVerifier.wait();
		console.log(`✅ Verifier ${verifier.address} set as trusted`);
	} else {
		console.log('✅ Verifier already trusted');
	}
	const isTrustedAfter = await contractOwner.trustedVerifiers(verifier.address);
	assert(isTrustedAfter === true, 'Verifier should be trusted');
	console.log('✅ Trusted verifier verified');

	console.log('--- STEP 16: Issue new VC for verification testing ---');
	const hashVC3 = ethers.keccak256(ethers.toUtf8Bytes('verifiableCredentialData3'));
	const txIssue3 = await contractIssuer.issueVC(orgID, hashVC3, uri);
	await txIssue3.wait();
	console.log('✅ VC issued for verification testing');

	console.log('--- STEP 17: Get VC and check verification fields ---');
	const vc3 = await contractOwner.getVC(orgID, 2);
	console.log('VC Verified:', vc3[6]);
	console.log('VC Verifier:', vc3[7]);
	console.log('VC Verified At:', vc3[8].toString(), vc3[8] === 0n ? '(not verified yet)' : `(${new Date(Number(vc3[8]) * 1000).toISOString()})`);
	assert(vc3[6] === false, 'VC should not be verified initially');
	assert(vc3[7] === ethers.ZeroAddress, 'VC verifier should be zero address initially');
	assert(vc3[8] === 0n, 'VC verifiedAt should be 0 initially');
	console.log('✅ VC verification fields verified (initial state)');

	console.log('--- STEP 18: Request Verification ---');
	const metadataUri = 'ipfs://QmTestMetadata123';
	const hasPendingBefore = await contractOwner.hasPendingVerificationRequest(orgID, 2);
	console.log('Has pending request before:', hasPendingBefore);
	
	const txRequest = await contractOwner.requestVerification(orgID, 2, verifier.address, metadataUri);
	const receiptRequest = await txRequest.wait();
	console.log('✅ Verification request created');
	
	// Check event
	const requestEvent = receiptRequest.logs.find(log => {
		try {
			const parsed = contractOwner.interface.parseLog(log);
			return parsed && parsed.name === 'VerificationRequested';
		} catch {
			return false;
		}
	});
	if (requestEvent) {
		const parsed = contractOwner.interface.parseLog(requestEvent);
		console.log('Request ID:', parsed.args.requestId.toString());
		console.log('Requester:', parsed.args.requester);
		console.log('Target Verifier:', parsed.args.targetVerifier);
		console.log('Metadata URI:', parsed.args.metadataUri);
	}

	const requestId = await contractOwner.vcRequestId(orgID, 2);
	console.log('Request ID from mapping:', requestId.toString());
	assert(Number(requestId) > 0, 'Request ID should be greater than 0');

	const hasPendingAfter = await contractOwner.hasPendingVerificationRequest(orgID, 2);
	assert(hasPendingAfter === true, 'Should have pending verification request');
	console.log('✅ Pending verification request verified');

	console.log('--- STEP 19: Get Verification Request Details ---');
	const request = await contractOwner.getVerificationRequest(requestId);
	console.log('Request orgID:', request[0]);
	console.log('Request VC Index:', request[1].toString());
	console.log('Request Requester:', request[2]);
	console.log('Request Target Verifier:', request[3]);
	console.log('Request Metadata URI:', request[4]);
	console.log('Request Requested At:', request[5].toString(), `(${new Date(Number(request[5]) * 1000).toISOString()})`);
	console.log('Request Processed:', request[6]);
	assert(request[0] === orgID, 'Request orgID should match');
	assert(Number(request[1]) === 2, 'Request VC index should be 2');
	assert(request[2].toLowerCase() === owner.address.toLowerCase(), 'Requester should be owner');
	assert(request[3].toLowerCase() === verifier.address.toLowerCase(), 'Target verifier should match');
	assert(request[4] === metadataUri, 'Metadata URI should match');
	assert(request[6] === false, 'Request should not be processed yet');
	console.log('✅ Verification request details verified');

	console.log('--- STEP 20: Verify Credential (from request) ---');
	const txVerify = await contractVerifier.verifyCredential(orgID, 2);
	await txVerify.wait();
	console.log('✅ Credential verified by trusted verifier');

	const vc3AfterVerify = await contractOwner.getVC(orgID, 2);
	console.log('VC Verified:', vc3AfterVerify[6]);
	console.log('VC Verifier:', vc3AfterVerify[7]);
	console.log('VC Verified At:', vc3AfterVerify[8].toString(), `(${new Date(Number(vc3AfterVerify[8]) * 1000).toISOString()})`);
	assert(vc3AfterVerify[6] === true, 'VC should be verified');
	assert(vc3AfterVerify[7].toLowerCase() === verifier.address.toLowerCase(), 'VC verifier should match');
	assert(vc3AfterVerify[8] > 0n, 'VC verifiedAt should be greater than 0');
	console.log('✅ VC verification status verified');

	const requestAfterVerify = await contractOwner.getVerificationRequest(requestId);
	assert(requestAfterVerify[6] === true, 'Request should be processed after verification');
	console.log('✅ Request marked as processed');

	console.log('--- STEP 21: Test Verification Request with Any Verifier ---');
	const hashVC4 = ethers.keccak256(ethers.toUtf8Bytes('verifiableCredentialData4'));
	const txIssue4 = await contractIssuer.issueVC(orgID, hashVC4, uri);
	await txIssue4.wait();
	console.log('✅ VC issued for any verifier test');

	const metadataUri2 = 'ipfs://QmTestMetadata456';
	const txRequest2 = await contractOwner.requestVerification(orgID, 3, ethers.ZeroAddress, metadataUri2);
	await txRequest2.wait();
	console.log('✅ Verification request created (any verifier allowed)');

	const requestId2 = await contractOwner.vcRequestId(orgID, 3);
	const request2 = await contractOwner.getVerificationRequest(requestId2);
	assert(request2[3] === ethers.ZeroAddress, 'Target verifier should be zero address (any verifier)');
	console.log('✅ Any verifier request verified');

	// Any trusted verifier can verify
	const txVerify2 = await contractVerifier.verifyCredential(orgID, 3);
	await txVerify2.wait();
	console.log('✅ Credential verified by any trusted verifier');

	const vc4AfterVerify = await contractOwner.getVC(orgID, 3);
	assert(vc4AfterVerify[6] === true, 'VC should be verified');
	console.log('✅ VC verified successfully');

	console.log('--- STEP 22: Test Direct Verification (without request) ---');
	const hashVC5 = ethers.keccak256(ethers.toUtf8Bytes('verifiableCredentialData5'));
	const txIssue5 = await contractIssuer.issueVC(orgID, hashVC5, uri);
	await txIssue5.wait();
	console.log('✅ VC issued for direct verification test');

	// Verify directly without request
	const txVerifyDirect = await contractVerifier.verifyCredential(orgID, 4);
	await txVerifyDirect.wait();
	console.log('✅ Credential verified directly (without request)');

	const vc5AfterVerify = await contractOwner.getVC(orgID, 4);
	assert(vc5AfterVerify[6] === true, 'VC should be verified');
	console.log('✅ Direct verification works');

	console.log('\n=== SUMMARY ===');
	console.log('✅ All basic VC operations tested');
	console.log('✅ Verification system tested');
	console.log('✅ Verification request system tested');
	console.log('✅ Trusted verifier system tested');
	console.log('✅ All tests passed!');
}

main().catch(err => {
	console.error('❌ Error:', err.reason || err.message || err);
});
