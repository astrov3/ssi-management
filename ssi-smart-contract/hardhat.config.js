require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

module.exports = {
	solidity: '0.8.24',
	networks: {
		sepolia: {
			url: process.env.SEPOLIA_RPC_URL,
			accounts: [`0x${process.env.PRIVATE_KEY}`],
			gas: 2100000,
			gasPrice: 8000000000,
		},
	},
	gasReporter: {
		enabled: true,
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY,
	},
};
