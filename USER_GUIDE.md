# 📚 SSI Identity Manager - User Guide

## 🌟 Tổng quan hệ thống

**SSI Identity Manager** là một hệ thống quản lý danh tính phi tập trung (Self-Sovereign Identity) được xây dựng trên blockchain Ethereum, cho phép:

- **Quản lý DID**: Đăng ký và quản lý Decentralized Identity
- **Phát hành VC**: Tạo và quản lý Verifiable Credentials
- **Xác minh**: Verify tính hợp lệ của credentials
- **QR Code**: Chia sẻ và quét thông tin qua QR code

---

## 🚀 Cài đặt và Cấu hình

### 1. Yêu cầu hệ thống
- **Node.js** >= 16.0.0
- **MetaMask** extension
- **Git**
- Sepolia ETH (để test)

### 2. Cài đặt Smart Contract
```bash
cd ssi-smart-contract
npm install
cp .env.example .env
```

**Cấu hình `.env`:**
```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY=your_private_key_without_0x
OWNER_PRIVATE_KEY=your_owner_private_key
ISSUER_PRIVATE_KEY=your_issuer_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
CONTRACT_ADDRESS=deployed_contract_address
```

**Deploy contract:**
```bash
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat verify --network sepolia DEPLOYED_ADDRESS
```

### 3. Cài đặt Frontend
```bash
cd ssi-frontend
npm install
cp .env.example .env
```

**Cấu hình `.env`:**
```env
VITE_CONTRACT_ADDRESS=your_deployed_contract_address
VITE_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
VITE_NETWORK=sepolia
VITE_PINATA_PROJECT_ID=your_pinata_project_id
VITE_PINATA_PROJECT_SECRET=your_pinata_secret
```

**Khởi chạy:**
```bash
npm run dev
```

---

## 🎯 Hướng dẫn sử dụng

### 📱 1. Dashboard - Trang chủ

**Mục đích**: Tổng quan tình trạng hệ thống và thực hiện các thao tác nhanh.

**Các chức năng**:
- **Connect Wallet**: Kết nối MetaMask
- **Stats Overview**: Xem thống kê DID/VC
- **Quick Actions**: Truy cập nhanh các chức năng
- **Current Status**: Trạng thái hiện tại của organization

**Cách sử dụng**:
1. Mở trang web
2. Click **"Connect Wallet"** 
3. Chấp nhận kết nối MetaMask
4. Xem thông tin tổng quan

### 🆔 2. DID Management - Quản lý DID

**Mục đích**: Đăng ký và quản lý Decentralized Identity cho organization.

**Flow cơ bản**:

#### Bước 1: Kiểm tra DID tồn tại
```
Organization ID → Check DID → Kết quả
```

#### Bước 2: Đăng ký DID mới (nếu chưa có)
```
Organization ID + DID Data → Register DID → Success
```

**Hướng dẫn chi tiết**:

1. **Nhập Organization ID**:
   - Format: `org_company_name` hoặc `domain.com`
   - Unique trên toàn hệ thống

2. **Check DID**:
   - Click **"Check DID"**
   - Hệ thống sẽ hiển thị trạng thái

3. **Register DID** (nếu chưa có):
   - Click **"Register DID"**
   - Nhập **DID Data** (JSON format):
   ```json
   {
     "name": "Company Name",
     "description": "Company description",
     "website": "https://company.com",
     "contact": "admin@company.com"
   }
   ```
   - Confirm transaction trong MetaMask

4. **Xem thông tin DID**:
   - Organization ID
   - Owner Address
   - Status (Active/Inactive)
   - Data Hash
   - IPFS URI

5. **Generate QR Code**:
   - Click **"Show QR"**
   - Chia sẻ QR code với partners

### 🎫 3. VC Operations - Quản lý Verifiable Credentials

**Mục đích**: Phát hành, xác minh và quản lý các chứng chỉ số.

**Điều kiện tiên quyết**:
- ✅ Đã connect wallet
- ✅ Đã có DID active
- ✅ Đã authorize issuer (nếu cần)

#### 3.1 Authorize Issuer
**Khi nào cần**: Khi muốn ủy quyền cho địa chỉ khác phát hành VC

1. Click **"Authorize Issuer"**
2. Nhập **Issuer Address** (0x...)
3. Confirm transaction
4. Issuer được phép issue VC cho organization

#### 3.2 Issue VC (Phát hành chứng chỉ)
**Quy trình**:

1. Click **"Issue VC"**
2. Nhập **VC Data**:
   ```json
   {
     "type": "EducationCredential",
     "recipient": "John Doe",
     "degree": "Bachelor of Computer Science",
     "university": "Tech University",
     "graduationYear": 2024,
     "gpa": 3.8
   }
   ```
3. Confirm transaction
4. VC được tạo với index tự động

#### 3.3 Verify VC (Xác minh chứng chỉ)
**Cách 1: Manual Verify**
1. Nhập **VC Index** (0, 1, 2...)
2. Nhập **Provided Hash** (hash từ VC gốc)
3. Click **"Verify VC"**
4. Kết quả: Valid/Invalid

**Cách 2: QR Code Verify**
1. Click **"Scan QR"**
2. Quét QR code của VC
3. Hệ thống tự động verify

#### 3.4 Revoke VC (Thu hồi chứng chỉ)
1. Tìm VC trong danh sách
2. Click **trash icon** 
3. Confirm revoke
4. VC status → Invalid

#### 3.5 Share VC via QR
1. Tìm VC trong danh sách
2. Click **QR icon**
3. Share QR code với verifier

### 📱 4. QR Scanner - Quét mã QR

**Mục đích**: Quét và xử lý QR codes chứa thông tin DID/VC.

**Supported QR Types**:
- **DID QR**: Thông tin organization
- **VC QR**: Verifiable credential data
- **Verification Request**: Yêu cầu verify VC

**Cách sử dụng**:

1. Click **"Scan QR Code"**
2. Cho phép truy cập camera
3. Đưa QR code vào khung scan
4. Hệ thống tự động:
   - Parse QR data
   - Hiển thị thông tin
   - Thực hiện verification (nếu là VC)

**QR Code Actions**:
- **Copy**: Copy raw data
- **Download**: Tải file JSON
- **Verify**: Xác minh VC (tự động)

### ⚙️ 5. Settings - Cài đặt

**Mục đích**: Cấu hình hệ thống và manage connections.

#### 5.1 Wallet Connection
- **Connect/Disconnect**: Quản lý kết nối MetaMask
- **Address Info**: Hiển thị địa chỉ hiện tại

#### 5.2 Organization Settings
- **Current Org ID**: Set/change organization
- **Clear Org ID**: Reset organization

#### 5.3 Network Configuration
- **Network**: Sepolia/Mainnet/Localhost
- **RPC URL**: Custom RPC endpoint
- **Contract Address**: Smart contract địa chỉ

#### 5.4 IPFS Configuration
- **Pinata Project ID**: Cho IPFS storage
- **Pinata Secret**: Authentication key

#### 5.5 Application Settings
- **Auto-connect**: Tự động connect wallet
- **App Info**: Version, environment

---

## 🔄 Workflow cơ bản

### Scenario 1: Organization đăng ký DID
```
1. Connect MetaMask
2. Go to DID Management
3. Enter Organization ID
4. Check if DID exists
5. If not exists → Register DID
6. Fill DID data → Confirm transaction
7. ✅ DID registered successfully
```

### Scenario 2: Issue credential cho student
```
1. Ensure DID is active
2. Go to VC Operations
3. Click "Issue VC"
4. Enter student credential data
5. Confirm transaction
6. ✅ VC issued with index 0
7. Share QR code with student
```

### Scenario 3: Verify credential từ QR
```
1. Go to QR Scanner
2. Click "Scan QR Code"
3. Scan student's VC QR
4. System auto-verifies
5. ✅ Show verification result
```

### Scenario 4: Partner organization verify VC
```
1. Receive VC QR from student
2. Go to QR Scanner
3. Scan QR code
4. Get VC data (orgID, hash, etc.)
5. Go to VC Operations
6. Manual verify with VC index + hash
7. ✅ Verification complete
```

---

## 🛠️ Testing với Script

### Test deployed contract
```bash
cd ssi-smart-contract
node scripts/test-deployed.js
```

**Script thực hiện**:
1. ✅ Check DID existence
2. ✅ Register DID (if not exists)  
3. ✅ Authorize Issuer
4. ✅ Issue VC
5. ✅ Verify VC
6. ✅ Get VC Length
7. ✅ Revoke VC
8. ✅ Verify VC after revoke

---

## ⚠️ Troubleshooting

### 1. MetaMask Issues
**Problem**: Cannot connect wallet
**Solution**:
- Đảm bảo MetaMask đã install
- Switch to Sepolia network
- Có đủ Sepolia ETH
- Refresh page and retry

### 2. Transaction Failed
**Problem**: Transaction reverted
**Common causes**:
- **"Only owner can perform this action"**: Không phải owner của DID
- **"DID not active"**: DID đã bị deactivate
- **"DID already exists"**: Org ID đã được đăng ký
- **"Invalid index"**: VC index không tồn tại
- **Gas limit**: Tăng gas limit

### 3. Contract Address Issues
**Problem**: Contract not found
**Solution**:
- Check `.env` CONTRACT_ADDRESS
- Verify contract deployed
- Check network (Sepolia vs Mainnet)

### 4. IPFS Upload Failed
**Problem**: Cannot upload to IPFS
**Solution**:
- Check Pinata credentials
- Verify internet connection
- Check file size limits

### 5. QR Scanner Not Working
**Problem**: Camera not accessible
**Solution**:
- Allow camera permission
- Use HTTPS (required for camera)
- Try different browser
- Check device camera

---

## 📋 Best Practices

### 🔒 Security
1. **Private Keys**: Never share private keys
2. **Organization ID**: Use meaningful, unique IDs
3. **Backup**: Backup wallet và private keys
4. **Verify**: Always verify contract addresses
5. **Testing**: Test trên Sepolia trước khi lên Mainnet

### 💡 Usage Tips
1. **DID Data**: Sử dụng JSON format chuẩn
2. **VC Data**: Include đầy đủ thông tin cần thiết
3. **QR Codes**: Test QR trước khi share
4. **Gas Optimization**: Batch operations khi có thể
5. **Documentation**: Lưu lại organizational procedures

### 🎯 Organization Management
1. **Naming**: Consistent org ID naming convention
2. **Authorization**: Manage issuer permissions carefully
3. **Monitoring**: Regular check VC status
4. **Archival**: Keep records of issued VCs
5. **Compliance**: Follow relevant regulations

---

## 🔗 Useful Links

- **Sepolia Faucet**: https://sepoliafaucet.com/
- **MetaMask**: https://metamask.io/
- **Etherscan Sepolia**: https://sepolia.etherscan.io/
- **Pinata IPFS**: https://pinata.cloud/
- **Hardhat Docs**: https://hardhat.org/docs

---

## 📞 Support

Nếu gặp vấn đề, hãy:
1. Check troubleshooting section
2. Verify cấu hình `.env`
3. Test với script provided
4. Check smart contract trên Etherscan
5. Create issue với detailed logs

---

## 🎉 Kết luận

Hệ thống SSI Identity Manager cung cấp giải pháp hoàn chỉnh cho việc quản lý danh tính và chứng chỉ phi tập trung. Với giao diện thân thiện và workflow rõ ràng, users có thể dễ dàng:

- Đăng ký và quản lý DID
- Phát hành và verify VC
- Chia sẻ credentials qua QR code
- Tích hợp với các hệ thống khác

**Happy Identity Managing! 🚀**
