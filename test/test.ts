import { arrayify } from "ethers/lib/utils";
import { getLottery } from "../src/utils/helper";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployments, ethers } from "hardhat";

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe("Lottery Contract", function () {
  let deployer: SignerWithAddress;
  let contract: any;

  before(async () => {
    await deployments.fixture();

    [deployer] = await ethers.getSigners();
    contract = await getLottery();
  });

  it("should generate a valid signature", async () => {
    const timestamp = Math.floor(Date.now() / 1000);
    const ticket = [deployer.address, timestamp];

    const data = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint256"],
      ticket
    );
    const dataHash = ethers.utils.keccak256(data);
    const message = arrayify(dataHash);

    const signature = await deployer.signMessage(message);

    console.log("signature: ", signature);

    const expectSigner = ethers.utils.verifyMessage(message, signature);
    console.log(" expected address ", expectSigner);
  });

  describe("claimDailyTicket", () => {
    it("should allow user to claim daily ticket", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const ticket = [deployer.address, timestamp];

      const data = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256"],
        ticket
      );
      const dataHash = ethers.utils.keccak256(data);
      const message = arrayify(dataHash);

      const signature = await deployer.signMessage(message);

      for (let i = 0; i < 7; i++) {
        await contract.claimDailyTicket(deployer.address, timestamp, signature);
      }

      const userLuckyNumber = await contract.getCurrentRoundTicket(deployer.address);
      console.log(userLuckyNumber);
    });
  });

  describe("rollLuckyTickets", () => {
    it("should roll lucky tickets", async () => {
      const result = await contract.connect(deployer).rollLuckyTickets();
      console.log("Result roll lucky ticket: ", result);

      // Add assertions to verify the result
    });
  });

  describe("setLottery", () => {
    it("should set lottery configurations", async () => {
      await contract.setLottery(4, 19 * 1);
      await contract.setLottery(5, 0 * 1);
      await contract.setLottery(6, 20 * 1);
      await contract.setLottery(7, 18 * 1);
      await contract.setLottery(3, 1);
      const lotteryConfig = await contract.getLottery();
      console.log(lotteryConfig);

    });
    async function runTest() {
      const timestamp = Math.floor(Date.now() / 1000);
      const ticket = [deployer.address, timestamp];

      const data = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256"],
        ticket
      );
      const dataHash = ethers.utils.keccak256(data);
      const message = arrayify(dataHash);

      const signature = await deployer.signMessage(message);

      for (let i = 0; i < 7; i++) {
        try {
          await contract.claimDailyTicket(
            deployer.address,
            timestamp,
            signature
          );
        } catch (error) {
          console.log("Error: ", error);
          continue;
        }
      }
      try {
        const userLuckyNumber = await contract.getCurrentRoundTicket(deployer.address);
        console.log(userLuckyNumber);
  
        const resultRollLuckyTicket = await contract
          .connect(deployer)
          .rollLuckyTickets();
          console.log("Result roll lucky ticket: ", resultRollLuckyTicket);
      } catch (error) {
        console.log("Error: ", error);
      }

      // Add assertions to verify the result if needed
      // expect(resultRollLuckyTicket).to.be.someValue;
    }

    it("should run test every 10 seconds", async function () {
      this.timeout(2 * 60 * 1000); // Set timeout to 1 minute for this test

      for (let i = 0; i < 6; i++) {
        console.log(`Running test iteration ${i + 1}`);
        await runTest();
        if (i < 5) {
          // Delay only if it's not the last iteration
          await delay(5 * 1000);
        }
      }
    });
    it("should get round start time", async function () {
      const rollTime = await contract.getRollLuckyTicketsTime(1);
      console.log(rollTime);
    });
  });

  // Additional tests can be added here, following the same pattern
});
