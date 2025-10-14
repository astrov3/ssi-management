import { useState } from 'react';
import { ethers } from 'ethers';
import { create } from 'ipfs-http-client';

import IdentityManagerAbi from './IdentityManager.json'; // ABI json file, đặt trong src/

// Địa chỉ contract đã deploy
const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS; // thay bằng địa chỉ contract của bạn
const SEPOLIA_RPC_URL = import.meta.env.VITE_SEPOLIA_RPC_URL; // hoặc RPC của bạn

const PINATA_PROJECT_ID = import.meta.env.VITE_PINATA_PROJECT_ID; // hoặc đặt trực tiếp string
const PINATA_PROJECT_SECRET = import.meta.env.VITE_PINATA_PROJECT_SECRET;

const auth = 'Basic ' + btoa(PINATA_PROJECT_ID + ':' + PINATA_PROJECT_SECRET).toString('base64');

const ipfs = create({
  host: 'api.pinata.cloud',
  port: 443,
  protocol: 'https',
  headers: {
    authorization: auth,
  },
});

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);

  const [contract, setContract] = useState(null);

  const [orgID, setOrgID] = useState('');
  const [didActive, setDidActive] = useState(null);
  const [vcLength, setVcLength] = useState(null);
  const [message, setMessage] = useState('');

  // Kết nối MetaMask
  async function connectWallet() {
    if (window.ethereum) {
      const prov = new ethers.BrowserProvider(window.ethereum);
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const signer = await prov.getSigner();
      const account = await signer.getAddress();

      setProvider(prov);
      setSigner(signer);
      setAccount(account);

      // Khởi tạo contract instance
      const contract = new ethers.Contract(CONTRACT_ADDRESS, IdentityManagerAbi, signer);
      setContract(contract);

      setMessage(`Connected: ${account}`);
    } else {
      setMessage('Please install MetaMask!');
    }
  }

  // Kiểm tra DID
  async function checkDID() {
    if (!contract || !orgID) return;
    try {
      const did = await contract.dids(orgID);
      setDidActive(did.active);
      setMessage(`DID active: ${did.active}`);
    } catch (err) {
      setMessage('Error checking DID: ' + err.message);
    }
  }

  // Đăng ký DID (upload offchain data lên IPFS)
  async function registerDID() {
    if (!contract || !orgID) return;
    try {
      const offchainData = JSON.stringify({ orgID, createdAt: Date.now() });
      // Upload IPFS
      const added = await ipfs.add(offchainData);
      const uri = 'ipfs://' + added.path;

      // Hash dữ liệu offchain
      const hashData = ethers.keccak256(ethers.toUtf8Bytes(offchainData));

      const tx = await contract.registerDID(orgID, hashData, uri);
      await tx.wait();
      setMessage('✅ DID registered');
      setDidActive(true);
    } catch (err) {
      setMessage('Error registering DID: ' + err.message);
    }
  }

  // Ủy quyền issuer (giả sử current user là owner)
  async function authorizeIssuer(issuerAddress) {
    if (!contract || !orgID || !issuerAddress) return;
    try {
      const tx = await contract.authorizeIssuer(orgID, issuerAddress);
      await tx.wait();
      setMessage('✅ Issuer authorized: ' + issuerAddress);
    } catch (err) {
      setMessage('Error authorizing issuer: ' + err.message);
    }
  }

  // Phát hành VC (issuer sẽ gọi, giả sử signer hiện tại là issuer)
  async function issueVC() {
    if (!contract || !orgID) return;
    try {
      const vcData = JSON.stringify({ orgID, claim: "Example VC claim", issuedAt: Date.now() });
      const added = await ipfs.add(vcData);
      const uri = 'ipfs://' + added.path;
      const hashVC = ethers.keccak256(ethers.toUtf8Bytes(vcData));

      const tx = await contract.issueVC(orgID, hashVC, uri);
      await tx.wait();
      setMessage('✅ VC issued');
    } catch (err) {
      setMessage('Error issuing VC: ' + err.message);
    }
  }

  // Lấy số lượng VC
  async function getVCCount() {
    if (!contract || !orgID) return;
    try {
      const count = await contract.getVCLength(orgID);
      setVcLength(count.toString());
      setMessage(`VC count: ${count.toString()}`);
    } catch (err) {
      setMessage('Error getting VC count: ' + err.message);
    }
  }

  return (
    <div className="min-h-screen p-6 bg-base-200">
      <h1 className="text-3xl font-bold mb-6">SSI Identity Manager Demo</h1>

      {!account ? (
        <button onClick={connectWallet} className="btn btn-primary mb-4">
          Connect MetaMask
        </button>
      ) : (
        <p className="mb-4">Connected account: <code>{account}</code></p>
      )}

      <input
        type="text"
        placeholder="Enter orgID"
        value={orgID}
        onChange={e => setOrgID(e.target.value)}
        className="input input-bordered w-full max-w-xs mb-4"
      />

      <button onClick={checkDID} className="btn btn-secondary mr-2">
        Check DID
      </button>

      <button onClick={registerDID} className="btn btn-success mr-2">
        Register DID
      </button>

      <button
        onClick={() => {
          const issuerAddress = prompt('Enter issuer address to authorize:');
          if (issuerAddress) authorizeIssuer(issuerAddress);
        }}
        className="btn btn-info mr-2"
      >
        Authorize Issuer
      </button>

      <button onClick={issueVC} className="btn btn-warning mr-2">
        Issue VC
      </button>

      <button onClick={getVCCount} className="btn btn-primary">
        Get VC Count
      </button>

      <p className="mt-6 text-lg">{message}</p>

      {didActive !== null && (
        <p className="mt-2">
          DID Active: <strong>{didActive ? 'Yes' : 'No'}</strong>
        </p>
      )}

      {vcLength !== null && (
        <p className="mt-2">
          VC Count: <strong>{vcLength}</strong>
        </p>
      )}
    </div>
  );
}

export default App;
