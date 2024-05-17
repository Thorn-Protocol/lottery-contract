import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const result = await deploy("VerifyOnChain", {
    from: deployer,
    args: [],
    log: true,
    // deterministicDeployment: true,
    skipIfAlreadyDeployed: true,
    autoMine: true,
  });
};
deploy.tags = ["hardhat", "sapphire-testnet", "sapphire-localnet", "sapphire-mainnet"];
export default deploy;
