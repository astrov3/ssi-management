# 🧪 End-to-End Testing Guide - SSI Identity Manager

## 📋 Testing Overview

Hướng dẫn test toàn diện cho hệ thống SSI Identity Manager, bao gồm:
- **Smart Contract Testing** 
- **Frontend Integration Testing**
- **End-to-End Workflow Testing**
- **Security & Performance Testing**
- **Manual Testing Checklist**

---

## 🔧 Setup Testing Environment

### 1. Prerequisites
```bash
# Install dependencies
cd ssi-smart-contract && npm install
cd ssi-frontend && npm install

# Setup test environment variables
cp .env.example .env.test
```

### 2. Test Configuration
**`.env.test`:**
```env
# Test Network
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY=your_test_private_key
OWNER_PRIVATE_KEY=your_test_owner_key
ISSUER_PRIVATE_KEY=your_test_issuer_key

# Test Contract (will be deployed fresh)
CONTRACT_ADDRESS=

# Test IPFS
VITE_PINATA_PROJECT_ID=test_project_id
VITE_PINATA_PROJECT_SECRET=test_secret
```

---

## 🔬 1. Smart Contract Testing

### Unit Tests
```bash
cd ssi-smart-contract
npx hardhat test
```

**Expected Output:**
```
✅ DID Management
  ✅ Should register a new DID
  ✅ Should prevent duplicate DID
  ✅ Should update DID  
  ✅ Should prevent update from non-owner
  ✅ Should deactivate DID
  ✅ Should prevent deactivation from non-owner

✅ VC Operations
  ✅ Should issue VC
  ✅ Should reject VC issuance if DID is inactive
  ✅ Should revoke VC
  ✅ Should not allow revoke from non-owner
  ✅ Should verify valid VC
  ✅ Should reject invalid or revoked VC
  ✅ Should return correct VC count

✅ Edge Cases
  ✅ Handles multiple VCs
  ✅ Should reject revoking non-existent VC
```

### Integration Tests
```bash
cd ssi-smart-contract
node scripts/test-deployed.js
```

**Test Flow:**
```
STEP 1: Check DID existence ✅
STEP 2: Register DID ✅
STEP 3: Authorize Issuer ✅
STEP 4: Issue VC ✅
STEP 5: Verify VC ✅
STEP 6: Get VC Length ✅
STEP 7: Revoke VC ✅
STEP 8: Verify VC after revoke ✅
```

### Gas Optimization Tests
```bash
npx hardhat test --gas-reporter
```

**Expected Gas Usage:**
- `registerDID`: ~85,000 gas
- `issueVC`: ~75,000 gas
- `revokeVC`: ~35,000 gas
- `verifyVC`: ~25,000 gas (view function)

---

## 🌐 2. Frontend Testing

### Setup Frontend Tests
```bash
cd ssi-frontend
npm install --save-dev @testing-library/react @testing-library/jest-dom vitest jsdom
```

### Component Unit Tests
**Create: `src/__tests__/Dashboard.test.jsx`**
```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Dashboard from '../pages/Dashboard';
import { useStore } from '../store/useStore';

// Mock store
jest.mock('../store/useStore');

describe('Dashboard Component', () => {
  beforeEach(() => {
    useStore.mockReturnValue({
      isConnected: false,
      account: null,
      loading: false,
      connectWallet: jest.fn(),
      currentOrgID: '',
      didActive: null,
      vcLength: 0
    });
  });

  test('renders dashboard title', () => {
    render(
      <BrowserRouter>
        <Dashboard />
      </BrowserRouter>
    );
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });

  test('shows connect wallet button when not connected', () => {
    render(
      <BrowserRouter>
        <Dashboard />
      </BrowserRouter>
    );
    expect(screen.getByText('Connect Wallet')).toBeInTheDocument();
  });

  test('calls connectWallet when button clicked', () => {
    const mockConnect = jest.fn();
    useStore.mockReturnValue({
      isConnected: false,
      connectWallet: mockConnect,
      loading: false
    });

    render(
      <BrowserRouter>
        <Dashboard />
      </BrowserRouter>
    );
    
    fireEvent.click(screen.getByText('Connect Wallet'));
    expect(mockConnect).toHaveBeenCalled();
  });
});
```

### Integration Tests with MSW
**Setup Mock Service Worker:**
```bash
npm install --save-dev msw
```

**Create: `src/__tests__/mocks/handlers.js`**
```javascript
import { rest } from 'msw';

export const handlers = [
  // Mock Pinata IPFS
  rest.post('https://api.pinata.cloud/pinning/pinJSONToIPFS', (req, res, ctx) => {
    return res(
      ctx.json({
        IpfsHash: 'QmTestHash123',
        PinSize: 1024,
        Timestamp: '2024-01-01T00:00:00.000Z'
      })
    );
  }),

  // Mock RPC calls
  rest.post('https://sepolia.infura.io/v3/*', (req, res, ctx) => {
    return res(
      ctx.json({
        jsonrpc: '2.0',
        id: 1,
        result: '0x1'
      })
    );
  })
];
```

---

## 🔄 3. End-to-End Workflow Testing

### Scenario 1: University Issues Diploma
**Test Case ID**: E2E-001  
**Priority**: High  
**Description**: Complete flow from DID registration to VC issuance and verification

**Pre-conditions:**
- MetaMask installed and configured
- Sepolia testnet selected
- Test account has sufficient ETH
- Fresh browser session

**Test Steps:**
```
1. SETUP PHASE
   ✅ Navigate to app URL
   ✅ Connect MetaMask wallet
   ✅ Verify connection status

2. DID REGISTRATION PHASE
   ✅ Go to DID Management
   ✅ Enter orgID: "university_tech_2024"
   ✅ Check DID (should not exist)
   ✅ Click "Register DID"
   ✅ Enter DID data:
   {
     "name": "Tech University",
     "type": "Educational Institution",
     "accreditation": "Ministry of Education",
     "established": 1995,
     "website": "https://techuni.edu"
   }
   ✅ Confirm transaction
   ✅ Verify DID status = Active

3. VC ISSUANCE PHASE
   ✅ Go to VC Operations
   ✅ Click "Issue VC"
   ✅ Enter student credential:
   {
     "type": "DiplomaCredential",
     "student": {
       "name": "John Doe",
       "id": "ST2024001",
       "email": "john.doe@student.techuni.edu"
     },
     "degree": {
       "name": "Bachelor of Computer Science",
       "level": "Bachelor",
       "major": "Computer Science",
       "gpa": 3.75,
       "graduationDate": "2024-06-15"
     },
     "issuer": "Tech University",
     "issuedDate": "2024-06-16"
   }
   ✅ Confirm transaction
   ✅ Verify VC appears in list
   ✅ Generate QR code for VC

4. VERIFICATION PHASE
   ✅ Go to QR Scanner
   ✅ Scan generated VC QR code
   ✅ Verify auto-verification works
   ✅ Check verification result = Valid
   ✅ Test manual verification with hash

5. SHARING & REVOCATION PHASE
   ✅ Share VC QR with test verifier
   ✅ Test cross-device scanning
   ✅ Revoke VC from VC Operations
   ✅ Re-scan QR code
   ✅ Verify status = Invalid
```

**Expected Results:**
- All transactions succeed
- QR codes scan correctly
- Verification results accurate
- UI reflects all state changes
- No console errors

**Post-conditions:**
- DID registered and active
- VC issued and revoked
- All data consistent on blockchain

### Scenario 2: Multi-Organization Workflow
**Test Case ID**: E2E-002  
**Priority**: Medium  
**Description**: Cross-organization credential verification

**Test Steps:**
```
1. SETUP TWO ORGANIZATIONS
   Org A: "employer_company_2024"
   Org B: "certification_body_2024"

2. ORG B ISSUES CERTIFICATION
   - Register DID for certification body
   - Issue professional certification VC
   - Generate QR code

3. ORG A VERIFIES CERTIFICATION
   - Scan VC QR from different browser/device
   - Verify credential authenticity
   - Check issuer legitimacy

4. EMPLOYEE SHARES WITH EMPLOYER
   - Multi-step verification process
   - Cross-reference multiple credentials
```

### Scenario 3: Error Handling & Edge Cases
**Test Case ID**: E2E-003  
**Priority**: High  
**Description**: System behavior under error conditions

**Test Cases:**
```
🔴 NETWORK ERRORS
- Disconnect internet during transaction
- Switch networks mid-process
- RPC timeout scenarios

🔴 WALLET ERRORS  
- Reject MetaMask transactions
- Insufficient gas scenarios
- Wrong network selected

🔴 DATA ERRORS
- Invalid JSON in forms
- Malformed QR codes
- Corrupted IPFS data

🔴 PERMISSION ERRORS
- Unauthorized VC issuance attempts
- Non-owner revocation attempts
- Camera permission denied

🔴 UI EDGE CASES
- Extremely long organization names
- Special characters in data
- Large file uploads
- Mobile device testing
```

---

## 🔒 4. Security Testing

### Authentication & Authorization Tests
```javascript
// Test unauthorized access attempts
describe('Security Tests', () => {
  test('prevents unauthorized DID updates', async () => {
    // Attempt to update DID from wrong account
    // Should fail with "Only owner can perform this action"
  });
  
  test('prevents unauthorized VC issuance', async () => {
    // Attempt to issue VC without authorization
    // Should fail with "Only authorized issuers"
  });
  
  test('validates input sanitization', async () => {
    // Test XSS attempts in form inputs
    // Test SQL injection patterns
    // Test script injection in JSON data
  });
});
```

### Smart Contract Security Audit
**Manual Security Checklist:**
```
✅ Reentrancy Protection
✅ Integer Overflow/Underflow
✅ Access Control Implementation
✅ Input Validation
✅ Gas Limit Considerations
✅ Event Emission
✅ State Variable Visibility
✅ Function Visibility
✅ Modifier Usage
✅ Error Handling
```

### Frontend Security Tests
```
✅ HTTPS Enforcement
✅ Content Security Policy
✅ XSS Prevention
✅ CSRF Protection
✅ Sensitive Data Handling
✅ Wallet Connection Security
✅ IPFS Data Encryption
✅ Privacy Protection
```

---

## ⚡ 5. Performance Testing

### Load Testing Script
**Create: `performance-tests/load-test.js`**
```javascript
import { check, sleep } from 'k6';
import http from 'k6/http';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 20 }, // Ramp up to 20
    { duration: '5m', target: 20 }, // Stay at 20
    { duration: '2m', target: 0 },  // Ramp down
  ],
};

export default function() {
  // Test frontend loading
  let response = http.get('http://localhost:5173');
  check(response, {
    'homepage loads': (r) => r.status === 200,
    'load time < 2s': (r) => r.timings.duration < 2000,
  });
  
  sleep(1);
}
```

### Blockchain Performance Metrics
```bash
# Monitor gas usage
npx hardhat test --gas-reporter

# Check transaction times
time node scripts/test-deployed.js

# Memory usage monitoring
node --max-old-space-size=4096 scripts/performance-test.js
```

**Performance Benchmarks:**
- Page load time: < 2 seconds
- Transaction confirmation: < 30 seconds
- QR code generation: < 1 second
- IPFS upload: < 5 seconds
- Contract deployment: < 60 seconds

---

## 📋 6. Manual Testing Checklist

### Pre-Testing Setup
```
□ Fresh browser installation
□ MetaMask extension installed
□ Sepolia testnet configured
□ Test accounts funded
□ Test data prepared
□ Screen recording started
```

### Dashboard Testing
```
□ Page loads without errors
□ Wallet connection works
□ Stats display correctly
□ Quick actions functional
□ Responsive on mobile
□ Dark/light mode toggle
□ Navigation menu works
```

### DID Management Testing
```
□ Organization ID validation
□ DID registration flow
□ Error handling for duplicates
□ DID status updates
□ QR code generation
□ QR code scanning
□ Form validation
□ Transaction confirmations
```

### VC Operations Testing
```
□ Issuer authorization flow
□ VC issuance process
□ VC data validation
□ Verification functionality
□ Revocation process
□ QR code generation/scanning
□ Batch operations
□ Error message clarity
```

### QR Scanner Testing
```
□ Camera permission request
□ QR code detection
□ Different QR types support
□ Data parsing accuracy
□ Error handling for invalid QRs
□ Cross-device compatibility
□ Offline mode behavior
```

### Settings Testing
```
□ Wallet connection management
□ Network switching
□ Configuration persistence
□ User guide functionality
□ Export/import settings
□ Reset functionality
□ Help documentation
```

---

## 🤖 7. Automated Testing Scripts

### Create Comprehensive Test Suite
**Create: `scripts/run-all-tests.sh`**
```bash
#!/bin/bash

echo "🚀 Starting Comprehensive E2E Testing Suite"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test Results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}▶ Running: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. Smart Contract Tests
echo -e "\n🔧 SMART CONTRACT TESTS"
echo "========================"
cd ssi-smart-contract

run_test "Smart Contract Compilation" "npx hardhat compile"
run_test "Unit Tests" "npx hardhat test"
run_test "Gas Reporter" "npx hardhat test --gas-reporter"
run_test "Contract Coverage" "npx hardhat coverage"

# 2. Frontend Tests
echo -e "\n🌐 FRONTEND TESTS"
echo "=================="
cd ../ssi-frontend

run_test "Frontend Build" "npm run build"
run_test "Component Tests" "npm test"
run_test "E2E Tests" "npm run test:e2e"
run_test "Lint Check" "npm run lint"

# 3. Integration Tests
echo -e "\n🔄 INTEGRATION TESTS"
echo "===================="
cd ../ssi-smart-contract

run_test "Deployed Contract Test" "node scripts/test-deployed.js"
run_test "Multi-Account Test" "node scripts/test-multi-account.js"
run_test "Network Integration" "node scripts/test-network.js"

# 4. Performance Tests
echo -e "\n⚡ PERFORMANCE TESTS"
echo "===================="
run_test "Load Testing" "k6 run performance-tests/load-test.js"
run_test "Memory Usage" "node --trace_gc scripts/memory-test.js"
run_test "Transaction Speed" "node scripts/speed-test.js"

# 5. Security Tests
echo -e "\n🔒 SECURITY TESTS"
echo "=================="
run_test "Static Analysis" "slither contracts/"
run_test "Vulnerability Scan" "mythril analyze contracts/IdentityManager.sol"
run_test "Access Control Test" "node scripts/security-test.js"

# Final Report
echo -e "\n📊 TEST SUMMARY"
echo "================"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}❌ SOME TESTS FAILED ❌${NC}"
    exit 1
fi
```

### Test Data Generator
**Create: `scripts/generate-test-data.js`**
```javascript
const fs = require('fs');
const { faker } = require('@faker-js/faker');

// Generate test organizations
const generateOrganizations = (count = 10) => {
    const orgs = [];
    for (let i = 0; i < count; i++) {
        orgs.push({
            orgID: `org_${faker.company.name().toLowerCase().replace(/\s+/g, '_')}_${i}`,
            data: {
                name: faker.company.name(),
                type: faker.helpers.arrayElement(['University', 'Company', 'Government', 'NGO']),
                established: faker.date.past(50).getFullYear(),
                website: faker.internet.url(),
                email: faker.internet.email(),
                address: {
                    street: faker.address.streetAddress(),
                    city: faker.address.city(),
                    country: faker.address.country()
                }
            }
        });
    }
    return orgs;
};

// Generate test credentials
const generateCredentials = (count = 50) => {
    const credentials = [];
    const credentialTypes = [
        'DiplomaCredential',
        'CertificationCredential', 
        'LicenseCredential',
        'AwardCredential',
        'MembershipCredential'
    ];
    
    for (let i = 0; i < count; i++) {
        credentials.push({
            type: faker.helpers.arrayElement(credentialTypes),
            recipient: {
                name: faker.name.fullName(),
                id: faker.datatype.uuid(),
                email: faker.internet.email()
            },
            credential: {
                title: faker.lorem.words(3),
                description: faker.lorem.sentence(),
                issuedDate: faker.date.recent().toISOString(),
                expiryDate: faker.date.future().toISOString(),
                grade: faker.datatype.float({ min: 2.0, max: 4.0, precision: 0.1 })
            }
        });
    }
    return credentials;
};

// Generate test data
console.log('🔄 Generating test data...');

const testData = {
    organizations: generateOrganizations(10),
    credentials: generateCredentials(50),
    testAccounts: [
        {
            role: 'owner',
            address: '0x742d35Cc6634C0532925a3b8D1DE9c61F8E7c982',
            privateKey: 'OWNER_PRIVATE_KEY'
        },
        {
            role: 'issuer',
            address: '0x8ba1f109551bD432803012645Hac136c',
            privateKey: 'ISSUER_PRIVATE_KEY'
        },
        {
            role: 'verifier',
            address: '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
            privateKey: 'VERIFIER_PRIVATE_KEY'
        }
    ],
    generatedAt: new Date().toISOString()
};

// Save to file
fs.writeFileSync('test-data.json', JSON.stringify(testData, null, 2));
console.log('✅ Test data generated: test-data.json');
console.log(`📊 Generated ${testData.organizations.length} organizations and ${testData.credentials.length} credentials`);
```

---

## 📊 8. Test Reporting & Documentation

### Test Report Template
**Create: `TEST_REPORT.md`**
```markdown
# 📋 E2E Test Execution Report

**Date**: {TEST_DATE}  
**Version**: {APP_VERSION}  
**Environment**: {TEST_ENVIRONMENT}  
**Tester**: {TESTER_NAME}

## 📊 Summary
- **Total Test Cases**: {TOTAL}
- **Passed**: {PASSED} ✅
- **Failed**: {FAILED} ❌  
- **Skipped**: {SKIPPED} ⏭️
- **Success Rate**: {SUCCESS_RATE}%

## 🎯 Test Scope
- [ ] Smart Contract Functionality
- [ ] Frontend User Interface  
- [ ] End-to-End Workflows
- [ ] Security Vulnerabilities
- [ ] Performance Benchmarks
- [ ] Cross-browser Compatibility
- [ ] Mobile Responsiveness

## 🐛 Defects Found
| Severity | Description | Status | Assigned |
|----------|-------------|--------|----------|
| High     | Login fails on mobile | Open | Dev Team |
| Medium   | QR scan timeout | Fixed | QA Team |
| Low      | UI alignment issue | Open | UI Team |

## 📈 Performance Metrics
- **Page Load Time**: 1.2s (Target: <2s) ✅
- **Transaction Time**: 25s (Target: <30s) ✅  
- **QR Generation**: 0.8s (Target: <1s) ✅
- **Memory Usage**: 45MB (Target: <100MB) ✅

## 🔒 Security Assessment
- **Authentication**: ✅ Passed
- **Authorization**: ✅ Passed
- **Input Validation**: ✅ Passed
- **Data Encryption**: ✅ Passed
- **XSS Protection**: ✅ Passed

## 📱 Browser Compatibility
| Browser | Version | Status |
|---------|---------|--------|
| Chrome | 118+ | ✅ Passed |
| Firefox | 119+ | ✅ Passed |
| Safari | 17+ | ✅ Passed |
| Edge | 118+ | ✅ Passed |

## 📝 Recommendations
1. Improve error messaging for failed transactions
2. Add loading indicators for IPFS uploads
3. Implement retry mechanism for network failures
4. Add more comprehensive input validation
5. Enhance mobile user experience
```

---

## 🚀 9. Continuous Integration Setup

### GitHub Actions Workflow
**Create: `.github/workflows/e2e-tests.yml`**
```yaml
name: E2E Testing Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  smart-contract-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd ssi-smart-contract
          npm ci
      
      - name: Run tests
        run: |
          cd ssi-smart-contract
          npx hardhat test
          npx hardhat coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd ssi-frontend
          npm ci
      
      - name: Run tests
        run: |
          cd ssi-frontend
          npm test
          npm run build

  e2e-tests:
    runs-on: ubuntu-latest
    needs: [smart-contract-tests, frontend-tests]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install Playwright
        run: npx playwright install
      
      - name: Run E2E tests
        run: |
          npm run test:e2e
        env:
          SEPOLIA_RPC_URL: ${{ secrets.SEPOLIA_RPC_URL }}
          TEST_PRIVATE_KEY: ${{ secrets.TEST_PRIVATE_KEY }}

  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security audit
        run: |
          npm audit
          npx audit-ci --config audit-ci.json
```

---

## ✅ 10. Final Testing Checklist

### Before Release
```
🔍 PRE-RELEASE CHECKLIST
□ All unit tests passing
□ Integration tests completed
□ E2E scenarios validated
□ Security audit clean
□ Performance benchmarks met
□ Cross-browser testing done
□ Mobile testing completed
□ Documentation updated
□ User guides verified
□ Deployment scripts tested

🚀 RELEASE READINESS
□ Staging environment tested
□ Production deployment plan
□ Rollback procedures ready
□ Monitoring alerts configured
□ User communication prepared
□ Support team briefed
□ Analytics tracking setup
□ Backup procedures verified
```

---

## 🎯 Conclusion

Comprehensive E2E testing approach ensures:
- **Quality Assurance**: Systematic validation
- **Risk Mitigation**: Early bug detection  
- **User Experience**: Smooth workflows
- **Security**: Vulnerability prevention
- **Performance**: Optimal system behavior
- **Reliability**: Consistent functionality

**Remember**: Testing is not just about finding bugs - it's about ensuring the system works as intended for real users in real scenarios! 🧪✨
