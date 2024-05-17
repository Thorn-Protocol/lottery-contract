import { arrayify } from "ethers/lib/utils";
import { getSignOnChain, getVerifynOnChain } from "../src/utils/helper";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Test on-chain signer", async () => {
  let deployer: SignerWithAddress;
  const setupTests = async () => {
    [deployer] = await ethers.getSigners();
  };
  it("Can send a Native Token Transfer userOp", async () => {
    await setupTests();
    const contract = await getVerifynOnChain();

    const data = ethers.utils.defaultAbiCoder.encode(["string"], ["123456"]);
    const dataHash = ethers.utils.keccak256(data);
    const message = arrayify(dataHash);

    const signature = await deployer.signMessage(message);

    console.log("signature: ", signature);

    const expectSigner = ethers.utils.verifyMessage(message, signature);
    console.log(" expect address ", expectSigner);
    try {
      const resultVerifyOnchain = await contract.verify(deployer.address, message, signature);
      console.log("Result verify on chain: ", resultVerifyOnchain);
    } catch (e) {
      console.log("error", e);
      console.log(" FAILED");
      console.log(" FAILED");
      console.log(" FAILED");
    }
    // console.log("etherSignature: ", etherSignature);
    // const isValid = ethers.utils.verifyMessage(message, etherSignature);
    // console.log(" expect address ", isValid);
    // let resultVerifyOnchain;
    // try {
    //   resultVerifyOnchain = await contract.verify(message, etherSignature);
    //   console.log("Result verify on chain: ", resultVerifyOnchain);
    // } catch (e) {
    //   console.log("error");
    // }
  }).timeout(200000);
});
