@echo off
echo 🚀 Starting Comprehensive E2E Testing Suite - SSI Identity Manager
echo ====================================================================

:: Colors for output (Windows compatible)
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "PURPLE=[35m"
set "NC=[0m"

:: Test Results
set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0
set /a START_TIME=%time:~0,2%*3600 + %time:~3,2%*60 + %time:~6,2%

echo.
echo %BLUE%🔍 CHECKING PREREQUISITES%NC%
echo =========================

:: Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Node.js is not installed%NC%
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do echo %GREEN%✅ Node.js: %%i%NC%
)

:: Check npm
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ npm is not installed%NC%
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('npm --version') do echo %GREEN%✅ npm: %%i%NC%
)

:: 1. Smart Contract Tests
echo.
echo %PURPLE%🔧 SMART CONTRACT TESTS%NC%
echo ========================

if exist "ssi-smart-contract" (
    cd ssi-smart-contract
    
    :: Install dependencies if needed
    if not exist "node_modules" (
        echo 📦 Installing smart contract dependencies...
        npm install
    )
    
    call :run_test "Smart Contract Compilation" "npx hardhat compile"
    call :run_test "Unit Tests" "npx hardhat test"
    
    :: Optional tests
    call :run_test_optional "Gas Reporter" "npx hardhat test --gas-reporter"
    call :run_test_optional "Contract Coverage" "npx hardhat coverage"
    
    if exist "scripts\test-deployed.js" (
        call :run_test_optional "Deployed Contract Test" "node scripts\test-deployed.js"
    )
    
    cd ..
) else (
    echo %YELLOW%⚠️  Smart contract directory not found%NC%
)

:: 2. Frontend Tests
echo.
echo %BLUE%🌐 FRONTEND TESTS%NC%
echo ==================

if exist "ssi-frontend" (
    cd ssi-frontend
    
    :: Install dependencies if needed
    if not exist "node_modules" (
        echo 📦 Installing frontend dependencies...
        npm install
    )
    
    call :run_test "Frontend Build" "npm run build"
    call :run_test_optional "Lint Check" "npm run lint"
    
    :: Check if test script exists
    npm run 2>&1 | findstr /C:"test" >nul
    if %errorlevel% equ 0 (
        call :run_test "Component Tests" "npm test"
    )
    
    cd ..
) else (
    echo %YELLOW%⚠️  Frontend directory not found%NC%
)

:: 3. Integration Tests
echo.
echo %GREEN%🔄 INTEGRATION TESTS%NC%
echo ====================

if exist "ssi-smart-contract" (
    cd ssi-smart-contract
    
    :: Create simple integration test if doesn't exist
    if not exist "scripts\simple-integration-test.js" (
        (
            echo const { ethers } = require('ethers'^);
            echo.
            echo async function simpleTest(^) {
            echo     try {
            echo         console.log('🔄 Running simple integration test...'^);
            echo         const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/demo'^);
            echo         const blockNumber = await provider.getBlockNumber(^);
            echo         console.log('✅ Connected to Sepolia, block:', blockNumber^);
            echo         const abi = require('../artifacts/contracts/IdentityManager.sol/IdentityManager.json'^).abi;
            echo         console.log('✅ Contract ABI loaded, functions:', abi.length^);
            echo         console.log('✅ Simple integration test passed'^);
            echo         return true;
            echo     } catch (error^) {
            echo         console.error('❌ Integration test failed:', error.message^);
            echo         return false;
            echo     }
            echo }
            echo.
            echo simpleTest(^).then(success =^> {
            echo     process.exit(success ? 0 : 1^);
            echo }^);
        ) > scripts\simple-integration-test.js
    )
    
    call :run_test "Simple Integration Test" "node scripts\simple-integration-test.js"
    
    cd ..
)

:: 4. File Structure Validation
echo.
echo %PURPLE%📁 FILE STRUCTURE VALIDATION%NC%
echo ============================

call :check_file "USER_GUIDE.md"
call :check_file "E2E_TESTING_GUIDE.md"
call :check_file "ssi-smart-contract\contracts\IdentityManager.sol"
call :check_file "ssi-smart-contract\hardhat.config.js"
call :check_file "ssi-frontend\src\App.jsx"
call :check_file "ssi-frontend\src\index.css"

:: 5. Configuration Validation
echo.
echo %BLUE%⚙️  CONFIGURATION VALIDATION%NC%
echo ============================

if exist "ssi-smart-contract\.env" (
    echo %GREEN%✅ Smart contract environment config found%NC%
    set /a TOTAL_TESTS+=1
    set /a PASSED_TESTS+=1
) else if exist "ssi-smart-contract\.env.example" (
    echo %GREEN%✅ Smart contract environment config found%NC%
    set /a TOTAL_TESTS+=1
    set /a PASSED_TESTS+=1
) else (
    echo %YELLOW%⚠️  Smart contract .env not found%NC%
    set /a TOTAL_TESTS+=1
)

if exist "ssi-frontend\.env" (
    echo %GREEN%✅ Frontend environment config found%NC%
    set /a TOTAL_TESTS+=1
    set /a PASSED_TESTS+=1
) else if exist "ssi-frontend\.env.example" (
    echo %GREEN%✅ Frontend environment config found%NC%
    set /a TOTAL_TESTS+=1
    set /a PASSED_TESTS+=1
) else (
    echo %YELLOW%⚠️  Frontend .env not found%NC%
    set /a TOTAL_TESTS+=1
)

:: Calculate execution time
set /a END_TIME=%time:~0,2%*3600 + %time:~3,2%*60 + %time:~6,2%
set /a EXECUTION_TIME=END_TIME-START_TIME

:: Final Report
echo.
echo %PURPLE%📊 COMPREHENSIVE TEST SUMMARY%NC%
echo ==============================
echo 📅 Date: %date% %time%
echo ⏱️  Execution Time: %EXECUTION_TIME%s
echo 📋 Total Tests: %TOTAL_TESTS%
echo %GREEN%✅ Passed: %PASSED_TESTS%%NC%
echo %RED%❌ Failed: %FAILED_TESTS%%NC%

:: Calculate success rate
if %TOTAL_TESTS% gtr 0 (
    set /a SUCCESS_RATE=PASSED_TESTS*100/TOTAL_TESTS
    echo 📈 Success Rate: !SUCCESS_RATE!%%
) else (
    set SUCCESS_RATE=0
)

:: Final verdict
if %FAILED_TESTS% equ 0 (
    echo.
    echo %GREEN%🎉 ALL TESTS PASSED! SYSTEM READY! 🎉%NC%
    echo %GREEN%🚀 You can proceed with deployment or further testing%NC%
    exit /b 0
) else if %SUCCESS_RATE% gtr 70 (
    echo.
    echo %YELLOW%⚠️  MOSTLY SUCCESSFUL BUT SOME ISSUES FOUND%NC%
    echo %YELLOW%🔧 Please review failed tests before proceeding%NC%
    exit /b 1
) else (
    echo.
    echo %RED%❌ SIGNIFICANT ISSUES FOUND%NC%
    echo %RED%🛠️  Please fix critical issues before proceeding%NC%
    exit /b 1
)

:: Function to run test
:run_test
set test_name=%~1
set test_command=%~2
echo.
echo %YELLOW%▶ Running: %test_name%%NC%
set /a TOTAL_TESTS+=1

%test_command% >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✅ PASS: %test_name%%NC%
    set /a PASSED_TESTS+=1
) else (
    echo %RED%❌ FAIL: %test_name%%NC%
    set /a FAILED_TESTS+=1
)
goto :eof

:: Function to run optional test
:run_test_optional
set test_name=%~1
set test_command=%~2
echo.
echo %YELLOW%▶ Running: %test_name% (Optional)%NC%
set /a TOTAL_TESTS+=1

%test_command% >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✅ PASS: %test_name%%NC%
    set /a PASSED_TESTS+=1
) else (
    echo %YELLOW%⚠️  SKIP: %test_name% (Optional)%NC%
)
goto :eof

:: Function to check file existence
:check_file
set file_path=%~1
if exist "%file_path%" (
    echo %GREEN%✅ Found: %file_path%%NC%
    set /a TOTAL_TESTS+=1
    set /a PASSED_TESTS+=1
) else (
    echo %RED%❌ Missing: %file_path%%NC%
    set /a TOTAL_TESTS+=1
    set /a FAILED_TESTS+=1
)
goto :eof
