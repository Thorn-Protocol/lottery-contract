import { deployments } from "hardhat";
import hre from "hardhat";
export const getSignOnChain = async () => {
  const SignOnChainDeployment = await deployments.get("SignOnChain");
  const SignOnChain = await hre.ethers.getContractFactory("SignOnChain");
  const signOnChain = SignOnChain.attach(SignOnChainDeployment.address);
  return signOnChain;
};

export const getVerifynOnChain = async () => {
  const VerifynOnChainDeployment = await deployments.get("VerifyOnChain");
  const VerifynOnChain = await hre.ethers.getContractFactory("VerifyOnChain");
  const verifynOnChain = VerifynOnChain.attach(VerifynOnChainDeployment.address);
  return verifynOnChain;
};
