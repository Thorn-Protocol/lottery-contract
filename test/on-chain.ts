import { arrayify } from "ethers/lib/utils";
import { getSignOnChain } from "../src/utils/helper";
import { ethers } from "hardhat";

describe("Test on-chain signer", async () => {
  const setupTests = async () => {};
  it("Can send a Native Token Transfer userOp", async () => {
    await setupTests();
    const contract = await getSignOnChain();
    console.log(" public key: ", await contract.publicAddress());
    console.log(" secret =   ", await contract.privateSecret());

    const data = ethers.utils.defaultAbiCoder.encode(["string"], ["123456"]);

    const dataHash = ethers.utils.keccak256(data);
    console.log(" data hash: ", dataHash);
    const message = arrayify(dataHash);

    const signature = await contract.sign(message);

    //console.log("signature: ", signature);

    const etherSignature = ethers.utils.joinSignature({
      r: signature.r,
      s: signature.s,
      v: signature.v.toNumber(),
    });

    console.log("etherSignature: ", etherSignature);

    const isValid = ethers.utils.verifyMessage(message, etherSignature);
    console.log(" expect address ", isValid);
    let resultVerifyOnchain;
    try {
      resultVerifyOnchain = await contract.verify(message, etherSignature);
      console.log("Result verify on chain: ", resultVerifyOnchain);
    } catch (e) {
      console.log("error");
    }
  }).timeout(200000);
});
