const { ethers } = require("hardhat");

async function main() {
  const IdentityManager = await ethers.getContractFactory("IdentityManager");
  const identityManager = await IdentityManager.deploy();
  await identityManager.waitForDeployment();
  const address = await identityManager.getAddress();
  console.log("IdentityManager deployed to:", address);
  console.log("Run `npx hardhat verify --network sepolia ${address}` to verify.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});