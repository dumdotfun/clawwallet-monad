import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying ClawWallet with account:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "MON");

  if (balance < ethers.parseEther("0.1")) {
    console.log("⚠️  Low balance! Get testnet MON from faucet.");
    return;
  }

  const treasury = deployer.address;
  
  const ClawWallet = await ethers.getContractFactory("ClawWallet");
  console.log("Deploying...");
  
  const clawWallet = await ClawWallet.deploy(treasury);
  await clawWallet.waitForDeployment();
  
  const address = await clawWallet.getAddress();
  console.log("\n✅ ClawWallet deployed to:", address);
  
  console.log("\n--- Deployment Info ---");
  console.log("Chain ID:", (await ethers.provider.getNetwork()).chainId.toString());
  console.log("Contract:", address);
  console.log("Treasury:", treasury);
  console.log("Fee: 0.5%");
  console.log("Welcome Points: 100");
  
  // Test creating a wallet
  console.log("\n--- Testing ---");
  const tx = await clawWallet.createWallet("test-agent");
  await tx.wait();
  const agentId = await clawWallet.getAgentId("test-agent");
  const wallet = await clawWallet.getWallet(agentId);
  console.log("Created test wallet, points:", wallet.points.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
