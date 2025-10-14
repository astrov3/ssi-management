const { performance } = require('perf_hooks');
const fs = require('fs');
const path = require('path');

class PerformanceTestSuite {
	constructor() {
		this.results = {
			timestamp: new Date().toISOString(),
			environment: {
				nodeVersion: process.version,
				platform: process.platform,
				arch: process.arch,
				memory: process.memoryUsage(),
				cpus: require('os').cpus().length,
			},
			tests: [],
			summary: {
				totalTests: 0,
				passedTests: 0,
				failedTests: 0,
				averageExecutionTime: 0,
				totalExecutionTime: 0,
			},
		};
	}

	// Measure execution time of a function
	async measureExecutionTime(testName, testFunction, iterations = 1) {
		console.log(`🚀 Running performance test: ${testName}`);

		const times = [];
		let success = true;
		let error = null;

		for (let i = 0; i < iterations; i++) {
			const startTime = performance.now();
			try {
				await testFunction();
				const endTime = performance.now();
				times.push(endTime - startTime);
			} catch (err) {
				success = false;
				error = err.message;
				break;
			}
		}

		const avgTime =
			times.length > 0 ? times.reduce((a, b) => a + b, 0) / times.length : 0;
		const minTime = times.length > 0 ? Math.min(...times) : 0;
		const maxTime = times.length > 0 ? Math.max(...times) : 0;

		const result = {
			testName,
			success,
			error,
			iterations,
			executionTimes: times,
			averageTime: avgTime,
			minTime,
			maxTime,
			memoryUsage: process.memoryUsage(),
		};

		this.results.tests.push(result);
		this.results.summary.totalTests++;

		if (success) {
			this.results.summary.passedTests++;
			console.log(`✅ ${testName}: ${avgTime.toFixed(2)}ms (avg)`);
		} else {
			this.results.summary.failedTests++;
			console.log(`❌ ${testName}: Failed - ${error}`);
		}

		return result;
	}

	// Test smart contract compilation performance
	async testSmartContractCompilation() {
		if (!fs.existsSync('ssi-smart-contract')) {
			throw new Error('Smart contract directory not found');
		}

		const { exec } = require('child_process');
		const util = require('util');
		const execAsync = util.promisify(exec);

		// Change to smart contract directory
		const originalCwd = process.cwd();
		process.chdir('ssi-smart-contract');

		try {
			await execAsync('npx hardhat compile');
			process.chdir(originalCwd);
		} catch (error) {
			process.chdir(originalCwd);
			throw error;
		}
	}

	// Test frontend build performance
	async testFrontendBuild() {
		if (!fs.existsSync('ssi-frontend')) {
			throw new Error('Frontend directory not found');
		}

		const { exec } = require('child_process');
		const util = require('util');
		const execAsync = util.promisify(exec);

		const originalCwd = process.cwd();
		process.chdir('ssi-frontend');

		try {
			await execAsync('npm run build');
			process.chdir(originalCwd);
		} catch (error) {
			process.chdir(originalCwd);
			throw error;
		}
	}

	// Test JSON parsing performance
	async testJSONParsing() {
		const largeJSON = {
			organizations: Array(1000).fill(null).map((_, i) => ({
				id: `org_${i}`,
				name: `Organization ${i}`,
				data: {
					credentials: Array(100).fill(null).map((_, j) => ({
						id: `cred_${i}_${j}`,
						type: 'TestCredential',
						timestamp: Date.now(),
					})),
				},
			})),
		};

		const jsonString = JSON.stringify(largeJSON);
		JSON.parse(jsonString);
	}

	// Test crypto operations performance
	async testCryptoOperations() {
		const crypto = require('crypto');

		// Test hash generation
		for (let i = 0; i < 100; i++) {
			const data = `test_data_${i}_${Date.now()}`;
			crypto.createHash('sha256').update(data).digest('hex');
		}
	}

	// Test file I/O performance
	async testFileIO() {
		const testData = 'x'.repeat(10000); // 10KB of data
		const tempFile = 'temp_performance_test.txt';

		// Write test
		fs.writeFileSync(tempFile, testData);

		// Read test
		fs.readFileSync(tempFile);

		// Cleanup
		fs.unlinkSync(tempFile);
	}

	// Test memory allocation performance
	async testMemoryAllocation() {
		const arrays = [];

		// Allocate memory
		for (let i = 0; i < 1000; i++) {
			arrays.push(new Array(1000).fill(Math.random()));
		}

		// Clear memory
		arrays.length = 0;

		// Force garbage collection if available
		if (global.gc) {
			global.gc();
		}
	}

	// Test network simulation (mock HTTP requests)
	async testNetworkSimulation() {
		const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

		// Simulate multiple network requests
		const promises = [];
		for (let i = 0; i < 10; i++) {
			promises.push(delay(Math.random() * 100)); // Random delay 0-100ms
		}

		await Promise.all(promises);
	}

	// Run all performance tests
	async runAllTests() {
		console.log('🔥 Starting Performance Test Suite');
		console.log('==================================\n');

		const startTime = performance.now();

		// Core performance tests
		await this.measureExecutionTime(
			'JSON Parsing (Large Dataset)',
			() => this.testJSONParsing(),
			5,
		);
		await this.measureExecutionTime(
			'Crypto Operations',
			() => this.testCryptoOperations(),
			3,
		);
		await this.measureExecutionTime(
			'File I/O Operations',
			() => this.testFileIO(),
			5,
		);
		await this.measureExecutionTime(
			'Memory Allocation',
			() => this.testMemoryAllocation(),
			3,
		);
		await this.measureExecutionTime(
			'Network Simulation',
			() => this.testNetworkSimulation(),
			3,
		);

		// Project-specific tests
		try {
			await this.measureExecutionTime(
				'Smart Contract Compilation',
				() => this.testSmartContractCompilation(),
				1,
			);
		} catch (error) {
			console.log(
				'⚠️  Skipping smart contract compilation test:',
				error.message,
			);
		}

		try {
			await this.measureExecutionTime(
				'Frontend Build',
				() => this.testFrontendBuild(),
				1,
			);
		} catch (error) {
			console.log('⚠️  Skipping frontend build test:', error.message);
		}

		const endTime = performance.now();
		this.results.summary.totalExecutionTime = endTime - startTime;
		this.results.summary.averageExecutionTime =
			this.results.summary.totalExecutionTime / this.results.summary.totalTests;

		return this.results;
	}

	// Generate performance report
	generateReport() {
		const report = {
			title: 'SSI Identity Manager - Performance Test Report',
			...this.results,
			benchmarks: this.evaluateBenchmarks(),
			recommendations: this.generateRecommendations(),
		};

		return report;
	}

	// Evaluate performance against benchmarks
	evaluateBenchmarks() {
		const benchmarks = {
			'JSON Parsing (Large Dataset)': { target: 50, unit: 'ms' },
			'Crypto Operations': { target: 100, unit: 'ms' },
			'File I/O Operations': { target: 10, unit: 'ms' },
			'Memory Allocation': { target: 200, unit: 'ms' },
			'Network Simulation': { target: 150, unit: 'ms' },
			'Smart Contract Compilation': { target: 30000, unit: 'ms' },
			'Frontend Build': { target: 60000, unit: 'ms' },
		};

		const evaluation = {};

		this.results.tests.forEach(test => {
			const benchmark = benchmarks[test.testName];
			if (benchmark && test.success) {
				evaluation[test.testName] = {
					actual: test.averageTime,
					target: benchmark.target,
					status: test.averageTime <= benchmark.target ? 'PASS' : 'FAIL',
					ratio: (test.averageTime / benchmark.target).toFixed(2),
				};
			}
		});

		return evaluation;
	}

	// Generate performance recommendations
	generateRecommendations() {
		const recommendations = [];
		const benchmarks = this.evaluateBenchmarks();

		Object.entries(benchmarks).forEach(([testName, result]) => {
			if (result.status === 'FAIL') {
				if (testName.includes('JSON Parsing')) {
					recommendations.push(
						'Consider implementing JSON streaming for large datasets',
					);
				} else if (testName.includes('Crypto Operations')) {
					recommendations.push(
						'Optimize cryptographic operations or use hardware acceleration',
					);
				} else if (testName.includes('File I/O')) {
					recommendations.push(
						'Consider asynchronous I/O operations and file caching',
					);
				} else if (testName.includes('Memory')) {
					recommendations.push(
						'Implement memory pooling and better garbage collection',
					);
				} else if (testName.includes('Smart Contract')) {
					recommendations.push(
						'Optimize smart contract code and compilation settings',
					);
				} else if (testName.includes('Frontend')) {
					recommendations.push(
						'Optimize build configuration and implement code splitting',
					);
				}
			}
		});

		// General recommendations
		if (this.results.summary.failedTests > 0) {
			recommendations.push(
				'Review failed tests and implement error handling improvements',
			);
		}

		if (recommendations.length === 0) {
			recommendations.push(
				'Performance is within acceptable limits. Consider monitoring for regression.',
			);
		}

		return recommendations;
	}

	// Save results to file
	saveResults(filename = 'performance-test-results.json') {
		const report = this.generateReport();

		// Ensure directory exists
		const dir = path.dirname(filename);
		if (!fs.existsSync(dir) && dir !== '.') {
			fs.mkdirSync(dir, { recursive: true });
		}

		fs.writeFileSync(filename, JSON.stringify(report, null, 2));

		console.log('\n📊 PERFORMANCE TEST SUMMARY');
		console.log('============================');
		console.log(`📁 Report saved: ${filename}`);
		console.log(`🧪 Total Tests: ${this.results.summary.totalTests}`);
		console.log(`✅ Passed: ${this.results.summary.passedTests}`);
		console.log(`❌ Failed: ${this.results.summary.failedTests}`);
		console.log(
			`⏱️  Total Time: ${this.results.summary.totalExecutionTime.toFixed(2)}ms`,
		);
		console.log(
			`📈 Average Time: ${this.results.summary.averageExecutionTime.toFixed(
				2,
			)}ms`,
		);

		// Display benchmark results
		const benchmarks = this.evaluateBenchmarks();
		if (Object.keys(benchmarks).length > 0) {
			console.log('\n🎯 BENCHMARK RESULTS');
			console.log('===================');
			Object.entries(benchmarks).forEach(([test, result]) => {
				const status = result.status === 'PASS' ? '✅' : '❌';
				console.log(
					`${status} ${test}: ${result.actual.toFixed(
						2,
					)}ms (target: ${result.target}ms)`,
				);
			});
		}

		// Display recommendations
		if (report.recommendations.length > 0) {
			console.log('\n💡 RECOMMENDATIONS');
			console.log('==================');
			report.recommendations.forEach((rec, index) => {
				console.log(`${index + 1}. ${rec}`);
			});
		}

		return report;
	}
}

// Main execution
if (require.main === module) {
	async function runPerformanceTests() {
		const testSuite = new PerformanceTestSuite();

		try {
			await testSuite.runAllTests();
			const report = testSuite.saveResults();

			console.log('\n🚀 Performance testing completed!');

			// Exit with appropriate code
			const failedTests = testSuite.results.summary.failedTests;
			process.exit(failedTests > 0 ? 1 : 0);
		} catch (error) {
			console.error('❌ Performance testing failed:', error.message);
			process.exit(1);
		}
	}

	runPerformanceTests();
}

module.exports = PerformanceTestSuite;
