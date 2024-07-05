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
const FACTORY_ADDRESS = "0x1e8C2a171e5c5D92d15F5363fd136CAf3bBf86E2"
// What does this need to be?
// const INIT_DATA = "0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000030000000100010001000000000000000000000000000000000000000000000000000000010001000100010000000000000000000000000000000000000000000000000001000100010001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001"

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

  const tx = await multiHatsHatterFactory.deployMultiClaimsHatter(HATS_ID, HATS, "0x0000000000000000000000000000", SALT_NONCE);
  const tr = await tx.wait();
	console.log(tr)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
