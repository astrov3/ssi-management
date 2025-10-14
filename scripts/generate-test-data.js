const fs = require('fs');
const path = require('path');

// Comprehensive test data generator for SSI Identity Manager
class TestDataGenerator {
    constructor() {
        this.organizations = [];
        this.credentials = [];
        this.testAccounts = [];
        this.qrCodes = [];
        this.generatedAt = new Date().toISOString();
    }

    // Generate realistic organization data
    generateOrganizations(count = 10) {
        const orgTypes = ['University', 'Company', 'Government', 'NGO', 'Hospital', 'School'];
        const universities = [
            'Tech University', 'State University', 'Medical College', 'Business School',
            'Engineering Institute', 'Art Academy', 'Science University', 'Community College'
        ];
        const companies = [
            'TechCorp Inc', 'Global Solutions Ltd', 'Innovation Labs', 'Digital Systems',
            'Cloud Technologies', 'Data Analytics Co', 'Blockchain Ventures', 'AI Solutions'
        ];

        for (let i = 0; i < count; i++) {
            const type = orgTypes[Math.floor(Math.random() * orgTypes.length)];
            let name;
            
            if (type === 'University' || type === 'School') {
                name = universities[Math.floor(Math.random() * universities.length)];
            } else if (type === 'Company') {
                name = companies[Math.floor(Math.random() * companies.length)];
            } else {
                name = `${type} Organization ${i + 1}`;
            }

            const orgID = `${type.toLowerCase()}_${name.toLowerCase().replace(/\s+/g, '_')}_${Date.now() + i}`;
            
            this.organizations.push({
                orgID,
                data: {
                    name,
                    type,
                    established: 1950 + Math.floor(Math.random() * 70),
                    website: `https://${name.toLowerCase().replace(/\s+/g, '')}.edu`,
                    email: `contact@${name.toLowerCase().replace(/\s+/g, '')}.edu`,
                    description: `${name} is a leading ${type.toLowerCase()} established for excellence in education and research.`,
                    accreditation: type === 'University' ? 'Ministry of Education' : 'Industry Standards Board',
                    address: {
                        street: `${100 + i} University Ave`,
                        city: ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'][Math.floor(Math.random() * 5)],
                        state: ['NY', 'CA', 'IL', 'TX', 'AZ'][Math.floor(Math.random() * 5)],
                        zipCode: `${10000 + Math.floor(Math.random() * 89999)}`,
                        country: 'United States'
                    },
                    contact: {
                        phone: `+1-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 9000) + 1000}`,
                        fax: `+1-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 9000) + 1000}`
                    }
                }
            });
        }
        console.log(`✅ Generated ${count} organizations`);
    }

    // Generate realistic credential data
    generateCredentials(count = 50) {
        const credentialTypes = {
            'DiplomaCredential': {
                degrees: ['Bachelor of Science', 'Master of Arts', 'PhD in Computer Science', 'Bachelor of Engineering'],
                majors: ['Computer Science', 'Business Administration', 'Electrical Engineering', 'Biology', 'Psychology']
            },
            'CertificationCredential': {
                certifications: ['AWS Certified', 'Google Cloud Professional', 'Microsoft Azure', 'Cisco CCNA', 'CompTIA Security+'],
                providers: ['Amazon', 'Google', 'Microsoft', 'Cisco', 'CompTIA']
            },
            'LicenseCredential': {
                licenses: ['Professional Engineer', 'Medical License', 'Teaching License', 'Nursing License', 'Legal Practice'],
                authorities: ['State Board', 'Medical Board', 'Education Department', 'Professional Council']
            }
        };

        const firstNames = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'Robert', 'Lisa', 'William', 'Jennifer'];
        const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];

        for (let i = 0; i < count; i++) {
            const types = Object.keys(credentialTypes);
            const type = types[Math.floor(Math.random() * types.length)];
            const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
            const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
            const studentId = `ST${2020 + Math.floor(Math.random() * 5)}${String(i + 1).padStart(3, '0')}`;

            let credentialData = {
                type,
                credentialId: `cred_${Date.now()}_${i}`,
                recipient: {
                    name: `${firstName} ${lastName}`,
                    id: studentId,
                    email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}@student.university.edu`,
                    dateOfBirth: `${1990 + Math.floor(Math.random() * 15)}-${String(Math.floor(Math.random() * 12) + 1).padStart(2, '0')}-${String(Math.floor(Math.random() * 28) + 1).padStart(2, '0')}`
                },
                issuer: {
                    name: this.organizations[Math.floor(Math.random() * this.organizations.length)]?.data.name || 'Tech University',
                    id: this.organizations[Math.floor(Math.random() * this.organizations.length)]?.orgID || 'university_tech_2024'
                },
                issuedDate: new Date(Date.now() - Math.floor(Math.random() * 365) * 24 * 60 * 60 * 1000).toISOString(),
                expiryDate: new Date(Date.now() + Math.floor(Math.random() * 1825) * 24 * 60 * 60 * 1000).toISOString(),
                status: 'active'
            };

            // Add type-specific data
            if (type === 'DiplomaCredential') {
                const degreeInfo = credentialTypes[type];
                credentialData.credential = {
                    degree: degreeInfo.degrees[Math.floor(Math.random() * degreeInfo.degrees.length)],
                    major: degreeInfo.majors[Math.floor(Math.random() * degreeInfo.majors.length)],
                    gpa: (2.0 + Math.random() * 2.0).toFixed(2),
                    graduationDate: credentialData.issuedDate,
                    honors: Math.random() > 0.7 ? ['Cum Laude', 'Magna Cum Laude', 'Summa Cum Laude'][Math.floor(Math.random() * 3)] : null
                };
            } else if (type === 'CertificationCredential') {
                const certInfo = credentialTypes[type];
                const certIndex = Math.floor(Math.random() * certInfo.certifications.length);
                credentialData.credential = {
                    certification: certInfo.certifications[certIndex],
                    provider: certInfo.providers[certIndex],
                    level: ['Associate', 'Professional', 'Expert'][Math.floor(Math.random() * 3)],
                    score: Math.floor(Math.random() * 40) + 60 + '%',
                    validUntil: new Date(Date.now() + 2 * 365 * 24 * 60 * 60 * 1000).toISOString()
                };
            } else if (type === 'LicenseCredential') {
                const licenseInfo = credentialTypes[type];
                const licenseIndex = Math.floor(Math.random() * licenseInfo.licenses.length);
                credentialData.credential = {
                    license: licenseInfo.licenses[licenseIndex],
                    authority: licenseInfo.authorities[Math.floor(Math.random() * licenseInfo.authorities.length)],
                    licenseNumber: `LIC${Math.floor(Math.random() * 900000) + 100000}`,
                    renewalDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
                    restrictions: Math.random() > 0.8 ? 'Supervised practice required' : 'None'
                };
            }

            this.credentials.push(credentialData);
        }
        console.log(`✅ Generated ${count} credentials`);
    }

    // Generate test accounts
    generateTestAccounts() {
        this.testAccounts = [
            {
                role: 'owner',
                name: 'University Administrator',
                address: '0x742d35Cc6634C0532925a3b8D1DE9c61F8E7c982',
                privateKey: 'OWNER_PRIVATE_KEY_PLACEHOLDER',
                permissions: ['registerDID', 'updateDID', 'authorizeIssuer', 'revokeVC'],
                description: 'Main account for DID registration and management'
            },
            {
                role: 'issuer',
                name: 'Credential Issuer',
                address: '0x8ba1f109551bD432803012645Hac136c0532925a',
                privateKey: 'ISSUER_PRIVATE_KEY_PLACEHOLDER',
                permissions: ['issueVC', 'viewVC'],
                description: 'Authorized account for issuing verifiable credentials'
            },
            {
                role: 'verifier',
                name: 'Credential Verifier',
                address: '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
                privateKey: 'VERIFIER_PRIVATE_KEY_PLACEHOLDER',
                permissions: ['verifyVC', 'viewVC'],
                description: 'Account for verifying credentials and accessing public data'
            },
            {
                role: 'student',
                name: 'Test Student',
                address: '0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0',
                privateKey: 'STUDENT_PRIVATE_KEY_PLACEHOLDER',
                permissions: ['viewVC'],
                description: 'Student account for receiving and sharing credentials'
            }
        ];
        console.log(`✅ Generated ${this.testAccounts.length} test accounts`);
    }

    // Generate QR code test data
    generateQRCodeData() {
        // DID QR Code
        this.qrCodes.push({
            type: 'DID',
            title: 'University DID QR Code',
            data: {
                type: 'DID',
                orgID: this.organizations[0]?.orgID || 'university_tech_2024',
                owner: this.testAccounts[0]?.address || '0x742d35Cc6634C0532925a3b8D1DE9c61F8E7c982',
                hashData: '0x' + Array(64).fill().map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
                uri: 'ipfs://QmTestHashForDIDData123456789',
                active: true,
                timestamp: Date.now()
            }
        });

        // VC QR Code
        this.qrCodes.push({
            type: 'VC',
            title: 'Diploma Credential QR Code',
            data: {
                type: 'VC',
                orgID: this.organizations[0]?.orgID || 'university_tech_2024',
                hashCredential: '0x' + Array(64).fill().map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
                issuer: this.testAccounts[1]?.address || '0x8ba1f109551bD432803012645Hac136c0532925a',
                uri: 'ipfs://QmTestHashForVCData123456789',
                valid: true,
                index: 0,
                timestamp: Date.now()
            }
        });

        // Verification Request QR Code
        this.qrCodes.push({
            type: 'VERIFICATION_REQUEST',
            title: 'Verification Request QR Code',
            data: {
                type: 'VERIFICATION_REQUEST',
                orgID: this.organizations[0]?.orgID || 'university_tech_2024',
                vcIndex: 0,
                requester: 'Employer Company',
                timestamp: Date.now()
            }
        });

        console.log(`✅ Generated ${this.qrCodes.length} QR code samples`);
    }

    // Generate all test data
    generateAll() {
        console.log('🔄 Generating comprehensive test data for SSI Identity Manager...\n');
        
        this.generateTestAccounts();
        this.generateOrganizations(15);
        this.generateCredentials(75);
        this.generateQRCodeData();
        
        return {
            metadata: {
                generatedAt: this.generatedAt,
                version: '1.0.0',
                description: 'Comprehensive test data for SSI Identity Manager E2E testing',
                totalOrganizations: this.organizations.length,
                totalCredentials: this.credentials.length,
                totalAccounts: this.testAccounts.length,
                totalQRCodes: this.qrCodes.length
            },
            testAccounts: this.testAccounts,
            organizations: this.organizations,
            credentials: this.credentials,
            qrCodes: this.qrCodes,
            testScenarios: this.generateTestScenarios()
        };
    }

    // Generate test scenarios
    generateTestScenarios() {
        return [
            {
                id: 'E2E-001',
                name: 'University Issues Diploma',
                description: 'Complete flow from DID registration to VC issuance and verification',
                steps: [
                    'Connect wallet with owner account',
                    'Register DID for university',
                    'Authorize issuer account',
                    'Issue diploma credential',
                    'Generate QR code',
                    'Verify credential',
                    'Test QR code scanning'
                ],
                testData: {
                    orgID: this.organizations[0]?.orgID,
                    issuerAccount: this.testAccounts[1]?.address,
                    studentCredential: this.credentials.find(c => c.type === 'DiplomaCredential')
                }
            },
            {
                id: 'E2E-002',
                name: 'Multi-Organization Workflow',
                description: 'Cross-organization credential verification',
                steps: [
                    'Setup multiple organizations',
                    'Issue credentials from different orgs',
                    'Cross-verify credentials',
                    'Test revocation workflow'
                ],
                testData: {
                    organizations: this.organizations.slice(0, 3),
                    crossCredentials: this.credentials.slice(0, 5)
                }
            },
            {
                id: 'E2E-003',
                name: 'Error Handling & Edge Cases',
                description: 'System behavior under error conditions',
                steps: [
                    'Test unauthorized access attempts',
                    'Test invalid data inputs',
                    'Test network error scenarios',
                    'Test malformed QR codes'
                ],
                testData: {
                    invalidInputs: [
                        { orgID: '', error: 'Empty organization ID' },
                        { orgID: 'duplicate_org', error: 'Duplicate DID registration' },
                        { hash: 'invalid_hash', error: 'Invalid hash format' }
                    ]
                }
            }
        ];
    }

    // Save test data to file
    saveToFile(filename = 'test-data.json') {
        const testData = this.generateAll();
        
        // Ensure directory exists
        const dir = path.dirname(filename);
        if (!fs.existsSync(dir) && dir !== '.') {
            fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(filename, JSON.stringify(testData, null, 2));
        
        console.log(`\n📊 TEST DATA SUMMARY`);
        console.log('===================');
        console.log(`📁 File: ${filename}`);
        console.log(`🏢 Organizations: ${testData.organizations.length}`);
        console.log(`🎓 Credentials: ${testData.credentials.length}`);
        console.log(`👤 Test Accounts: ${testData.testAccounts.length}`);
        console.log(`📱 QR Codes: ${testData.qrCodes.length}`);
        console.log(`📋 Test Scenarios: ${testData.testScenarios.length}`);
        console.log(`📅 Generated: ${testData.metadata.generatedAt}`);
        
        return testData;
    }
}

// Main execution
if (require.main === module) {
    const generator = new TestDataGenerator();
    const outputFile = process.argv[2] || 'test-data.json';
    
    try {
        const testData = generator.saveToFile(outputFile);
        console.log(`\n✅ Test data successfully generated!`);
        console.log(`🚀 Ready for comprehensive E2E testing!`);
    } catch (error) {
        console.error(`❌ Error generating test data:`, error.message);
        process.exit(1);
    }
}

module.exports = TestDataGenerator;
