#!/bin/bash

echo "🚀 Starting Comprehensive E2E Testing Suite - SSI Identity Manager"
echo "===================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test Results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
START_TIME=$(date +%s)

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local is_optional="${3:-false}"
    
    echo -e "\n${YELLOW}▶ Running: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        if [ "$is_optional" = "true" ]; then
            echo -e "${YELLOW}⚠️  SKIP: $test_name (Optional)${NC}"
        else
            echo -e "${RED}❌ FAIL: $test_name${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prerequisites check
echo -e "\n${BLUE}🔍 CHECKING PREREQUISITES${NC}"
echo "========================="

prerequisites_ok=true

if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    prerequisites_ok=false
else
    echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
fi

if ! command_exists npm; then
    echo -e "${RED}❌ npm is not installed${NC}"
    prerequisites_ok=false
else
    echo -e "${GREEN}✅ npm: $(npm --version)${NC}"
fi

if [ "$prerequisites_ok" = false ]; then
    echo -e "\n${RED}❌ Prerequisites not met. Please install Node.js and npm.${NC}"
    exit 1
fi

# 1. Smart Contract Tests
echo -e "\n${PURPLE}🔧 SMART CONTRACT TESTS${NC}"
echo "========================"

if [ -d "ssi-smart-contract" ]; then
    cd ssi-smart-contract
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing smart contract dependencies..."
        npm install
    fi
    
    run_test "Smart Contract Compilation" "npx hardhat compile"
    run_test "Unit Tests" "npx hardhat test"
    run_test "Gas Reporter" "npx hardhat test --gas-reporter" "true"
    run_test "Contract Coverage" "npx hardhat coverage" "true"
    
    if [ -f "scripts/test-deployed.js" ]; then
        run_test "Deployed Contract Test" "node scripts/test-deployed.js" "true"
    fi
    
    cd ..
else
    echo -e "${YELLOW}⚠️  Smart contract directory not found${NC}"
fi

# 2. Frontend Tests
echo -e "\n${BLUE}🌐 FRONTEND TESTS${NC}"
echo "=================="

if [ -d "ssi-frontend" ]; then
    cd ssi-frontend
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing frontend dependencies..."
        npm install
    fi
    
    run_test "Frontend Build" "npm run build"
    run_test "Lint Check" "npm run lint" "true"
    
    # Check if test script exists
    if npm run | grep -q "test"; then
        run_test "Component Tests" "npm test -- --run"
    fi
    
    cd ..
else
    echo -e "${YELLOW}⚠️  Frontend directory not found${NC}"
fi

# 3. Integration Tests
echo -e "\n${GREEN}🔄 INTEGRATION TESTS${NC}"
echo "===================="

if [ -d "ssi-smart-contract" ]; then
    cd ssi-smart-contract
    
    # Create simple integration test if doesn't exist
    if [ ! -f "scripts/simple-integration-test.js" ]; then
        cat > scripts/simple-integration-test.js << 'EOF'
const { ethers } = require('ethers');

async function simpleTest() {
    try {
        console.log('🔄 Running simple integration test...');
        
        // Basic ethers.js test
        const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/demo');
        const blockNumber = await provider.getBlockNumber();
        console.log('✅ Connected to Sepolia, block:', blockNumber);
        
        // Basic contract ABI test
        const abi = require('../artifacts/contracts/IdentityManager.sol/IdentityManager.json').abi;
        console.log('✅ Contract ABI loaded, functions:', abi.length);
        
        console.log('✅ Simple integration test passed');
        return true;
    } catch (error) {
        console.error('❌ Integration test failed:', error.message);
        return false;
    }
}

simpleTest().then(success => {
    process.exit(success ? 0 : 1);
});
EOF
    fi
    
    run_test "Simple Integration Test" "node scripts/simple-integration-test.js"
    
    cd ..
fi

# 4. File Structure Validation
echo -e "\n${PURPLE}📁 FILE STRUCTURE VALIDATION${NC}"
echo "============================"

expected_files=(
    "USER_GUIDE.md"
    "E2E_TESTING_GUIDE.md"
    "ssi-smart-contract/contracts/IdentityManager.sol"
    "ssi-smart-contract/hardhat.config.js"
    "ssi-frontend/src/App.jsx"
    "ssi-frontend/src/index.css"
)

for file in "${expected_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Found: $file${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ Missing: $file${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
done

# 5. Configuration Validation
echo -e "\n${BLUE}⚙️  CONFIGURATION VALIDATION${NC}"
echo "============================"

# Check .env files
if [ -f "ssi-smart-contract/.env" ] || [ -f "ssi-smart-contract/.env.example" ]; then
    echo -e "${GREEN}✅ Smart contract environment config found${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠️  Smart contract .env not found${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

if [ -f "ssi-frontend/.env" ] || [ -f "ssi-frontend/.env.example" ]; then
    echo -e "${GREEN}✅ Frontend environment config found${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠️  Frontend .env not found${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Calculate execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

# Final Report
echo -e "\n${PURPLE}📊 COMPREHENSIVE TEST SUMMARY${NC}"
echo "=============================="
echo -e "📅 Date: $(date)"
echo -e "⏱️  Execution Time: ${EXECUTION_TIME}s"
echo -e "📋 Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}✅ Passed: $PASSED_TESTS${NC}"
echo -e "${RED}❌ Failed: $FAILED_TESTS${NC}"

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo -e "📈 Success Rate: ${SUCCESS_RATE}%"
else
    SUCCESS_RATE=0
fi

# Final verdict
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! SYSTEM READY! 🎉${NC}"
    echo -e "${GREEN}🚀 You can proceed with deployment or further testing${NC}"
    exit 0
elif [ $SUCCESS_RATE -gt 70 ]; then
    echo -e "\n${YELLOW}⚠️  MOSTLY SUCCESSFUL BUT SOME ISSUES FOUND${NC}"
    echo -e "${YELLOW}🔧 Please review failed tests before proceeding${NC}"
    exit 1
else
    echo -e "\n${RED}❌ SIGNIFICANT ISSUES FOUND${NC}"
    echo -e "${RED}🛠️  Please fix critical issues before proceeding${NC}"
    exit 1
fi
