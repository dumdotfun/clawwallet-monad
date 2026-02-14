import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying ClawWallet to Base Sepolia");
  console.log("Account:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  if (balance < ethers.parseEther("0.01")) {
    console.log("\n⚠️  Need Base Sepolia ETH!");
    console.log("Get from: https://faucet.quicknode.com/base/sepolia");
    console.log("Or: https://www.alchemy.com/faucets/base-sepolia");
    console.log("Address:", deployer.address);
    return;
  }

  const treasury = deployer.address;
  
  const ClawWallet = await ethers.getContractFactory("ClawWallet");
  console.log("\nDeploying...");
  
  const clawWallet = await ClawWallet.deploy(treasury);
  await clawWallet.waitForDeployment();
  
  const address = await clawWallet.getAddress();
  console.log("\n✅ ClawWallet deployed to Base Sepolia:", address);
  
  // Test
  const tx = await clawWallet.createWallet("test-agent");
  await tx.wait();
  console.log("Test wallet created successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
