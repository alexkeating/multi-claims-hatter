import { config as dotEnvConfig } from "dotenv";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet, Contract } from "zksync-ethers";
import * as hre from "hardhat";

const MultiClaimsHatterFactory = require("../artifacts-zk/src/MultiClaimsHatterFactory.sol/MultiClaimsHatterFactory.json");

// Before executing a real deployment, be sure to set these values as appropriate for the environment being deployed
// to. The values used in the script at the time of deployment can be checked in along with the deployment artifacts
// produced by running the scripts.
const contractName = "MultiClaimsHatter";
const HATS_ID = 1;
const HATS = "0x32Ccb7600c10B4F7e678C7cbde199d98453D0e7e";
const SALT_NONCE = 1;
const FACTORY_ADDRESS = "0xE893c6CA3F0AC1689231385243439806E443fF17"

async function main() {
  dotEnvConfig();

  const deployerPrivateKey = process.env.PRIVATE_KEY;
  if (!deployerPrivateKey) {
    throw "Please set PRIVATE_KEY in your .env file";
  }

  console.log("Deploying " + contractName + "...");

  const zkWallet = new Wallet(deployerPrivateKey);
  const deployer = new Deployer(hre, zkWallet);
  const multiHatsHatterFactory = await new Contract(FACTORY_ADDRESS, MultiClaimsHatterFactory.abi, deployer.zkWallet);

  const tx = await multiHatsHatterFactory.deployMultiClaimsHatter(HATS_ID, HATS, "0x", SALT_NONCE);
  const tr = await tx.wait();
	console.log(tr)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
