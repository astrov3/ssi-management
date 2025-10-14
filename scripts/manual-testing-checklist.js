const readline = require('readline');
const fs = require('fs');

class ManualTestingChecklist {
	constructor() {
		this.rl = readline.createInterface({
			input: process.stdin,
			output: process.stdout,
		});

		this.results = {
			metadata: {
				tester: '',
				startTime: new Date().toISOString(),
				endTime: null,
				environment: 'manual',
				browser: '',
				device: '',
			},
			categories: {
				'Pre-Testing Setup': [],
				'Dashboard Testing': [],
				'DID Management': [],
				'VC Operations': [],
				'QR Scanner': [],
				Settings: [],
				'Cross-browser': [],
				'Mobile Testing': [],
				Security: [],
				Performance: [],
			},
			summary: {
				totalChecks: 0,
				passedChecks: 0,
				failedChecks: 0,
				skippedChecks: 0,
			},
			notes: [],
			issues: [],
		};

		this.setupChecklist();
	}

	setupChecklist() {
		this.checklist = {
			'Pre-Testing Setup': [
				'Fresh browser installation/incognito mode activated',
				'MetaMask extension installed and configured',
				'Sepolia testnet selected in MetaMask',
				'Test accounts have sufficient Sepolia ETH (>0.01 ETH)',
				'Test data prepared (organizations, credentials)',
				'Screen recording/screenshots ready for documentation',
				'Network connection stable',
				'Developer tools accessible',
			],

			'Dashboard Testing': [
				'Page loads without console errors',
				'Wallet connection button visible and functional',
				'MetaMask popup appears on connection attempt',
				'Connection status updates correctly after wallet connection',
				'Account address displays correctly',
				'Statistics cards show appropriate data (0 initially)',
				'Quick actions buttons are clickable and navigate correctly',
				'Current status section updates based on wallet state',
				'Responsive layout works on different screen sizes',
				'Loading states appear during wallet operations',
				'Error messages display clearly for connection failures',
			],

			'DID Management': [
				'Organization ID input accepts valid format',
				'Organization ID validation prevents empty/invalid inputs',
				'Check DID button functions and shows appropriate results',
				'Register DID form appears when clicking register button',
				'DID data textarea accepts valid JSON format',
				'JSON validation prevents malformed data submission',
				'Transaction confirmation appears in MetaMask',
				'Transaction success/failure feedback is clear',
				'DID status updates correctly after registration',
				'QR code generates successfully for registered DID',
				'QR scanner opens and functions correctly',
				'Error handling works for duplicate DID registrations',
				'Gas estimation appears reasonable (< 100,000 gas)',
				'Network errors are handled gracefully',
			],

			'VC Operations': [
				'Page shows appropriate state based on wallet/DID status',
				'Warning messages appear when wallet not connected',
				'Warning messages appear when DID not registered',
				'Authorize Issuer form functions correctly',
				'Issuer address validation works properly',
				'Issue VC form accepts credential data correctly',
				'VC data JSON validation prevents malformed submissions',
				'Transaction confirmations appear for VC operations',
				'Issued VCs appear in the list correctly',
				'VC verification function works with valid credentials',
				'VC verification correctly identifies invalid/revoked VCs',
				'QR code generation works for each VC',
				'VC revocation function works correctly',
				'Status updates immediately after revocation',
				'Error messages are clear and actionable',
				'Loading states appear during blockchain operations',
			],

			'QR Scanner': [
				'Camera permission request appears appropriately',
				'Camera feed displays correctly',
				'QR code detection works reliably',
				'Different QR code types are recognized (DID, VC, etc.)',
				'Scanned data displays in correct format',
				'Auto-verification works for VC QR codes',
				'Manual verification input functions correctly',
				'Copy data button works and provides feedback',
				'Download data function works correctly',
				'Error handling for invalid QR codes',
				'Camera switching works on devices with multiple cameras',
				'Works in different lighting conditions',
				'Graceful handling when camera not available',
				'Responsive design works on mobile devices',
			],

			Settings: [
				'Connected wallet address displays correctly',
				'Organization ID setting saves and persists',
				'RPC URL can be updated and validated',
				'Contract address updates correctly',
				'Pinata credentials can be set (with masking)',
				'Show/hide secrets toggle works correctly',
				'Reset to defaults function works properly',
				'User guide sections are expandable/collapsible',
				'User guide content is helpful and accurate',
				'Configuration changes persist across page reloads',
				'Validation prevents invalid network configurations',
				'Current values display correctly for all settings',
				'Save confirmation appears after successful updates',
				'Network switching works properly',
			],

			'Cross-browser': [
				'Chrome: Full functionality works',
				'Firefox: All features accessible and functional',
				'Safari: MetaMask integration works (or shows appropriate error)',
				'Edge: Complete feature set available',
				'Mobile Chrome: Touch interactions work properly',
				'Mobile Safari: Basic functionality available',
				'Consistent UI appearance across browsers',
				'Performance acceptable on all tested browsers',
			],

			'Mobile Testing': [
				'Responsive design adapts to mobile screen sizes',
				'Touch interactions work smoothly',
				'Form inputs are appropriately sized for mobile',
				'Camera access works for QR scanning',
				'MetaMask mobile app integration functions',
				'Text is readable without horizontal scrolling',
				'Navigation menu works on mobile',
				'Loading indicators are visible and appropriate',
				'Error messages display properly on small screens',
			],

			Security: [
				'No sensitive data logged in browser console',
				'Private keys never exposed in UI or logs',
				'HTTPS enforced (if applicable)',
				'Input sanitization prevents XSS attacks',
				'Proper wallet disconnection clears sensitive state',
				'Transaction data matches user input',
				'No unauthorized access to restricted functions',
				'IPFS hashes match uploaded content',
				"Error messages don't leak sensitive information",
				'Network requests use secure endpoints',
			],

			Performance: [
				'Initial page load completes within 3 seconds',
				'Wallet connection completes within 10 seconds',
				'Blockchain transactions confirm within 60 seconds',
				'QR code generation completes within 2 seconds',
				'IPFS uploads complete within 10 seconds',
				'UI remains responsive during background operations',
				'Memory usage stays reasonable during extended use',
				'No significant lag in user interactions',
				'File operations complete in reasonable time',
				'Network timeouts are handled gracefully',
			],
		};
	}

	async askQuestion(question) {
		return new Promise(resolve => {
			this.rl.question(question, resolve);
		});
	}

	async runChecklist() {
		console.log('🧪 SSI Identity Manager - Manual Testing Checklist');
		console.log('==================================================\n');

		// Collect tester information
		this.results.metadata.tester = await this.askQuestion(
			'👤 Enter tester name: ',
		);
		this.results.metadata.browser = await this.askQuestion(
			'🌐 Enter browser (Chrome/Firefox/Safari/Edge): ',
		);
		this.results.metadata.device = await this.askQuestion(
			'📱 Enter device type (Desktop/Mobile/Tablet): ',
		);

		console.log('\nStarting manual testing checklist...\n');
		console.log('For each item, enter:');
		console.log('  ✅ PASS (p) - Test passed');
		console.log('  ❌ FAIL (f) - Test failed');
		console.log('  ⏭️  SKIP (s) - Test skipped');
		console.log('  📝 NOTE (n) - Add note and continue\n');

		for (const [category, items] of Object.entries(this.checklist)) {
			await this.testCategory(category, items);
		}

		this.results.metadata.endTime = new Date().toISOString();
		this.generateSummary();
		await this.saveResults();
	}

	async testCategory(categoryName, items) {
		console.log(`\n🔍 ${categoryName.toUpperCase()}`);
		console.log('='.repeat(categoryName.length + 2));

		for (let i = 0; i < items.length; i++) {
			const item = items[i];
			console.log(`\n${i + 1}. ${item}`);

			let result = '';
			let notes = '';

			while (!['p', 'f', 's'].includes(result.toLowerCase())) {
				result = await this.askQuestion('   Result (p/f/s/n): ');

				if (result.toLowerCase() === 'n') {
					notes = await this.askQuestion('   📝 Enter note: ');
					this.results.notes.push({
						category: categoryName,
						item,
						note: notes,
						timestamp: new Date().toISOString(),
					});
					result = ''; // Reset to ask for actual result
				} else if (!['p', 'f', 's'].includes(result.toLowerCase())) {
					console.log(
						'   Invalid input. Please enter p (pass), f (fail), s (skip), or n (note)',
					);
				}
			}

			const status = this.mapResult(result.toLowerCase());

			if (status === 'failed') {
				const issue = await this.askQuestion('   🐛 Describe the issue: ');
				this.results.issues.push({
					category: categoryName,
					item,
					issue,
					timestamp: new Date().toISOString(),
				});
			}

			this.results.categories[categoryName].push({
				item,
				status,
				notes,
				timestamp: new Date().toISOString(),
			});

			this.updateSummary(status);
		}
	}

	mapResult(input) {
		const mapping = {
			p: 'passed',
			f: 'failed',
			s: 'skipped',
		};
		return mapping[input];
	}

	updateSummary(status) {
		this.results.summary.totalChecks++;
		if (status === 'passed') this.results.summary.passedChecks++;
		else if (status === 'failed') this.results.summary.failedChecks++;
		else if (status === 'skipped') this.results.summary.skippedChecks++;
	}

	generateSummary() {
		const {
			totalChecks,
			passedChecks,
			failedChecks,
			skippedChecks,
		} = this.results.summary;
		const successRate =
			totalChecks > 0 ? Math.round(passedChecks / totalChecks * 100) : 0;

		console.log('\n📊 MANUAL TESTING SUMMARY');
		console.log('=========================');
		console.log(`👤 Tester: ${this.results.metadata.tester}`);
		console.log(`🌐 Browser: ${this.results.metadata.browser}`);
		console.log(`📱 Device: ${this.results.metadata.device}`);
		console.log(`⏰ Duration: ${this.calculateDuration()}`);
		console.log(`📋 Total Checks: ${totalChecks}`);
		console.log(`✅ Passed: ${passedChecks}`);
		console.log(`❌ Failed: ${failedChecks}`);
		console.log(`⏭️  Skipped: ${skippedChecks}`);
		console.log(`📈 Success Rate: ${successRate}%`);

		if (this.results.issues.length > 0) {
			console.log(`\n🐛 Issues Found: ${this.results.issues.length}`);
			this.results.issues.forEach((issue, index) => {
				console.log(`${index + 1}. [${issue.category}] ${issue.issue}`);
			});
		}

		if (this.results.notes.length > 0) {
			console.log(`\n📝 Notes Added: ${this.results.notes.length}`);
		}

		// Generate recommendations
		const recommendations = this.generateRecommendations(
			successRate,
			failedChecks,
		);
		if (recommendations.length > 0) {
			console.log('\n💡 RECOMMENDATIONS');
			console.log('==================');
			recommendations.forEach((rec, index) => {
				console.log(`${index + 1}. ${rec}`);
			});
		}
	}

	calculateDuration() {
		const start = new Date(this.results.metadata.startTime);
		const end = new Date(this.results.metadata.endTime);
		const durationMs = end - start;
		const minutes = Math.floor(durationMs / (1000 * 60));
		const seconds = Math.floor(durationMs % (1000 * 60) / 1000);
		return `${minutes}m ${seconds}s`;
	}

	generateRecommendations(successRate, failedChecks) {
		const recommendations = [];

		if (successRate < 70) {
			recommendations.push(
				'System requires significant improvements before release',
			);
		} else if (successRate < 85) {
			recommendations.push(
				'Address failed test cases before proceeding to production',
			);
		} else if (successRate < 95) {
			recommendations.push('Minor improvements recommended before release');
		}

		if (failedChecks > 0) {
			recommendations.push(
				'Document all failed test cases for development team',
			);
			recommendations.push('Retest after fixes are implemented');
		}

		// Check specific categories for recommendations
		Object.entries(this.results.categories).forEach(([category, items]) => {
			const failed = items.filter(item => item.status === 'failed').length;
			if (failed > 0) {
				if (category === 'Security') {
					recommendations.push(
						'🔒 Address security issues immediately - critical for production',
					);
				} else if (category === 'Cross-browser' && failed > 1) {
					recommendations.push(
						'🌐 Improve cross-browser compatibility for wider user base',
					);
				} else if (category === 'Mobile Testing' && failed > 2) {
					recommendations.push(
						'📱 Enhance mobile experience for better accessibility',
					);
				}
			}
		});

		if (this.results.notes.length > 5) {
			recommendations.push(
				'📝 Review detailed notes for potential improvements',
			);
		}

		return recommendations;
	}

	async saveResults() {
		const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
		const filename = `manual-test-results-${timestamp}.json`;

		// Save JSON results
		fs.writeFileSync(filename, JSON.stringify(this.results, null, 2));
		console.log(`\n💾 Results saved to: ${filename}`);

		// Generate markdown report
		const markdownFilename = `manual-test-report-${timestamp}.md`;
		const markdown = this.generateMarkdownReport();
		fs.writeFileSync(markdownFilename, markdown);
		console.log(`📄 Report saved to: ${markdownFilename}`);

		// Ask if user wants to continue with additional testing
		const continueTest = await this.askQuestion(
			'\n🔄 Run additional test category? (y/n): ',
		);
		if (continueTest.toLowerCase() === 'y') {
			console.log('\nSelect category to test:');
			const categories = Object.keys(this.checklist);
			categories.forEach((cat, index) => {
				console.log(`${index + 1}. ${cat}`);
			});

			const selection = await this.askQuestion('Enter category number: ');
			const categoryIndex = parseInt(selection) - 1;

			if (categoryIndex >= 0 && categoryIndex < categories.length) {
				const categoryName = categories[categoryIndex];
				await this.testCategory(categoryName, this.checklist[categoryName]);
				await this.saveResults();
			}
		}
	}

	generateMarkdownReport() {
		const {
			totalChecks,
			passedChecks,
			failedChecks,
			skippedChecks,
		} = this.results.summary;
		const successRate =
			totalChecks > 0 ? Math.round(passedChecks / totalChecks * 100) : 0;

		let markdown = `# 📋 Manual Testing Report - SSI Identity Manager

## Test Information
- **Tester**: ${this.results.metadata.tester}
- **Browser**: ${this.results.metadata.browser}
- **Device**: ${this.results.metadata.device}
- **Start Time**: ${new Date(this.results.metadata.startTime).toLocaleString()}
- **End Time**: ${new Date(this.results.metadata.endTime).toLocaleString()}
- **Duration**: ${this.calculateDuration()}

## Summary
- **Total Checks**: ${totalChecks}
- **Passed**: ${passedChecks} ✅
- **Failed**: ${failedChecks} ❌
- **Skipped**: ${skippedChecks} ⏭️
- **Success Rate**: ${successRate}%

## Test Results by Category

`;

		Object.entries(this.results.categories).forEach(([category, items]) => {
			if (items.length > 0) {
				const categoryPassed = items.filter(item => item.status === 'passed')
					.length;
				const categoryFailed = items.filter(item => item.status === 'failed')
					.length;
				const categorySkipped = items.filter(item => item.status === 'skipped')
					.length;

				markdown += `### ${category}
**Results**: ${categoryPassed} ✅ | ${categoryFailed} ❌ | ${categorySkipped} ⏭️

`;

				items.forEach((result, index) => {
					const statusIcon =
						result.status === 'passed'
							? '✅'
							: result.status === 'failed' ? '❌' : '⏭️';
					markdown += `${index + 1}. ${statusIcon} ${result.item}\n`;
					if (result.notes) {
						markdown += `   *Note: ${result.notes}*\n`;
					}
				});
				markdown += '\n';
			}
		});

		if (this.results.issues.length > 0) {
			markdown += `## 🐛 Issues Found

| Category | Issue Description | Timestamp |
|----------|-------------------|-----------|
`;
			this.results.issues.forEach(issue => {
				markdown += `| ${issue.category} | ${issue.issue} | ${new Date(
					issue.timestamp,
				).toLocaleString()} |\n`;
			});
			markdown += '\n';
		}

		if (this.results.notes.length > 0) {
			markdown += `## 📝 Additional Notes

`;
			this.results.notes.forEach((note, index) => {
				markdown += `${index + 1}. **${note.category}**: ${note.note}\n`;
			});
			markdown += '\n';
		}

		markdown += `## 📊 Conclusion

`;

		if (successRate >= 95) {
			markdown +=
				'🎉 **EXCELLENT**: System is ready for production with excellent manual test results.';
		} else if (successRate >= 85) {
			markdown +=
				'👍 **GOOD**: System performs well in manual testing with minor issues to address.';
		} else if (successRate >= 70) {
			markdown +=
				'⚠️ **ACCEPTABLE**: System has notable issues that should be addressed before release.';
		} else {
			markdown +=
				'❌ **NEEDS IMPROVEMENT**: Significant manual testing issues found. Major improvements required.';
		}

		markdown += `

---
*Manual test report generated on ${new Date().toLocaleString()}*
`;

		return markdown;
	}

	close() {
		this.rl.close();
	}
}

// Main execution
if (require.main === module) {
	async function runManualTesting() {
		const checklist = new ManualTestingChecklist();

		try {
			await checklist.runChecklist();
			console.log('\n✅ Manual testing checklist completed!');
		} catch (error) {
			console.error('\n❌ Manual testing failed:', error.message);
		} finally {
			checklist.close();
		}
	}

	runManualTesting();
}

module.exports = ManualTestingChecklist;
