import { deployments } from "hardhat";
import hre from "hardhat";
export const getSignOnChain = async () => {
  const SignOnChainDeployment = await deployments.get("SignOnChain");
  const SignOnChain = await hre.ethers.getContractFactory("SignOnChain");
  const signOnChain = SignOnChain.attach(SignOnChainDeployment.address);
  console.log("SignOnChain Contract at: ", signOnChain.address);
  return signOnChain;
};

export const getVerifynOnChain = async () => {
  const VerifynOnChainDeployment = await deployments.get("VerifyOnChain");
  const VerifynOnChain = await hre.ethers.getContractFactory("VerifyOnChain");
  const verifynOnChain = VerifynOnChain.attach(VerifynOnChainDeployment.address);
  console.log("VerifyOnChain Contract at: ", verifynOnChain.address);
  return verifynOnChain;
};

export const getLottery = async () => {
  const LotteryDeployment = await deployments.get("Lottery");
  const Lottery = await hre.ethers.getContractFactory("Lottery");
  const lottery = Lottery.attach(LotteryDeployment.address);
  console.log("Lottery Contract at: ", lottery.address);
  return lottery;
};
