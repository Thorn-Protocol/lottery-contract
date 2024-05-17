import { deployments } from "hardhat";
import hre from "hardhat";
export const getSignOnChain = async () => {
  const SignOnChainDeployment = await deployments.get("SignOnChain");
  const SignOnChain = await hre.ethers.getContractFactory("SignOnChain");
  const signOnChain = SignOnChain.attach(SignOnChainDeployment.address);
  return signOnChain;
};
