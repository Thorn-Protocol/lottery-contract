// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

// import ecdsa library
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {SignatureRSV, EthereumUtils} from "@oasisprotocol/sapphire-contracts/contracts/EthereumUtils.sol";

import "hardhat/console.sol";

contract Lottery is Ownable {

    struct LuckyTicket {
        uint luckyNumber;
        uint round;
        address userAddress;
        uint timestamp;
    }

    struct RoundReward {
        uint luckyNumber;
        address winner;
        // uint amount;
        // address token;
    }

    // save all tickets
    mapping(address => LuckyTicket[]) public dailyTicketsByUser;
    // map to lucky number to retrieve user
    mapping(uint => LuckyTicket) public dailyTickets;
    mapping(uint => RoundReward[]) public roundReward;
    mapping(address => uint[]) public winnings;
    uint public ticketCounter;
    uint epochTime;
    uint currentRound;
    uint[10] attendeeCountByRound;
    // round i start from the value ticketCountByRound[i]
    uint[10] ticketCountByRound;
    address public admin;

    event eventClaimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes32 dataHash,
        bytes signature
    );
    event rollLuckyTicketsEvent(uint256[] luckyNumbers);

    using ECDSA for bytes32;
    using Sapphire for bytes;

    constructor() Ownable() {
        epochTime =
            block.timestamp -
            (block.timestamp % 86400) +
            18 *
            3600 +
            30 *
            60 -
            7 *
            3600;
        ticketCounter = 0;
        currentRound = 0;
        attendeeCountByRound = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        ticketCountByRound = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        admin = msg.sender;
    }

    uint randNonce = 0;

    function randMod() internal returns (uint) {
        // increase nonce
        randNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            );
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
    }

    function getHash(
        address userAddress,
        uint256 timestamp
    ) public pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encode(userAddress, timestamp));
        return msgHash;
    }

    // user function
    /// @notice user claim ticket to get lucky number
    /// @param adminAddress address of user
    /// @param timestamp timestamp of user claim ticket
    /// @param signature a string of ecdsa signature of address of user, signed by admin's public key
    function claimDailyTicket(
        address adminAddress,
        address userAddress,
        uint256 timestamp,
        bytes32 dataHash,
        bytes memory signature
    ) public returns (uint) {
        // bytes32 dataHash = getHash(userAddress, timestamp);

        require (checkUserClaimDailyTicket(userAddress) == false, "User already claimed ticket today");

        address recovered = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );
        bool verified = false;
        if (adminAddress == recovered) {
            verified = true;
        }
        recovered = dataHash.recover(signature);
        if (adminAddress == recovered) {
            verified = true;
        }
        console.log("(Contract) Signer: %s", recovered);
        console.log("(Contract) Admin: %s", adminAddress);
        require(verified == true, "Invalid ticket: signer is not admin");

        // // returns a lucky number - increment number from start of campaign
        // // todo check timestamp on ticket

        console.log(timestamp);

        uint round = getRound();

        ticketCounter++;
        LuckyTicket memory ticket = LuckyTicket(
            ticketCounter,
            round,
            userAddress,
            timestamp
        );
        dailyTicketsByUser[userAddress].push(ticket);
        dailyTickets[ticketCounter] = ticket;
        attendeeCountByRound[round]++;
        if (round < 10) {
            ticketCountByRound[round + 1] = ticketCounter + 1;
        }
        console.log("Ticket counter: %s", ticketCounter);
        return ticketCounter;
    }

    modifier onlyAdmin() {
        console.log("Adminn: %s", admin);
        console.log("Sender: %s", msg.sender);
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        console.log("Length: %s", b.length);
        for (uint i = 0; i < b.length; i++) {
            console.log("Byte: %s", uint8(b[i]));
            number |= uint256(uint8(b[i])) << (8 * (b.length - (i + 1)));
        }
        return number;
    }

    // todo add back modifier
    // todo not call this until ticket count of each day > 5
    // admin function
    function rollLuckyTickets() public returns (uint[] memory) {
        // use oasis sapphire random bytes function
        uint[] memory luckyNumbers = new uint[](5);
        uint8 count = 0;
        uint round = getRound();
        while (count < 5) {
            // get random bytes
            bytes memory rand = Sapphire.randomBytes(4, "");
            uint luckyNumber = bytesToUint(rand);

            // // mock random generator
            // uint luckyNumber = randMod();

            luckyNumber = luckyNumber % ticketCounter;
            bool skip = false;
            // if number already exists, skip
            for (uint i = 0; i < count; i++) {
                if (luckyNumbers[i] == luckyNumber) {
                    skip = true;
                    break;
                }
            }
            if (skip) {
                continue;
            }
            // if number is from previous round, skip
            if (round > 0 && ticketCountByRound[round] < luckyNumber) {
                continue;
            }

            // find winner
            // if cannot find address, address = 0x0
            address winner = dailyTickets[luckyNumber].userAddress;
            if (winner == address(0)) {
                continue;
            }

            luckyNumbers[count] = luckyNumber;
            count++;

            roundReward[round].push(RoundReward(luckyNumber, winner));
            winnings[winner].push(luckyNumber);

            console.log("Lucky number %s", luckyNumber);
            console.log("Winner %s", winner);
        }
        emit rollLuckyTicketsEvent(luckyNumbers);
        return luckyNumbers;
    }

    function getTotalRewards() public pure returns (uint) {
        // return 50 usdt
        return 50;
    }

    function getRollLuckyTicketsTime() public view returns (uint) {
        // 18h30 utc of that day
        return
            block.timestamp - (block.timestamp % 86400) + 18 * 3600 + 30 * 60;
    }

    function getRound() public returns (uint round) {
        console.log("Block time: %s", block.timestamp);
        console.log("Epoch time: %s", epochTime);
        if (block.timestamp < epochTime) {
            currentRound = 0;
        } else {
            uint currentTime = getRollLuckyTicketsTime();
            currentRound = (currentTime - epochTime) / 86400;
        }
        console.log("Current round: %s", currentRound);
        round = currentRound;
    }

    function getLuckyTicketsByUser(
        address userAddress
    )
        public
        view
        returns (LuckyTicket[] memory)
    {
        return dailyTicketsByUser[userAddress];
    }

    function getTotalLuckyNumbersByRound(
        uint round
    ) public view returns (RoundReward[] memory) {
        if (roundReward[round].length > 0)
            return roundReward[round];
        return new RoundReward[](0);
    }

    function checkUserClaimDailyTicket(
        address userAddress
    ) public returns (bool) {
        uint round = getRound();
        uint numberTicket = dailyTicketsByUser[userAddress].length;
        console.log("Number ticket: %s", numberTicket);
        if (numberTicket == 0) {
            console.log("User not claimed ticket");
            return false;
        }
        LuckyTicket memory ticket = dailyTicketsByUser[userAddress][numberTicket - 1];
        if (ticket.round == round) {
            console.log("User claimed ticket");
            return true;}
        console.log("User not claimed ticket");
        return false;
    }

    function getTotalAttendeeByRound(uint round) public view returns (uint) {
        return attendeeCountByRound[round];
    }

    function getUserInfo(
        address userAddress
    ) public view returns (uint numberTicketClaimed, uint numberWinnings, uint latestTicketClaimTime) {
        numberTicketClaimed = dailyTicketsByUser[userAddress].length;
        numberWinnings = winnings[userAddress].length;
        // latest ticket claimed
        latestTicketClaimTime = dailyTicketsByUser[userAddress][numberTicketClaimed-1].timestamp;

        console.log("Number ticket claimed: %s", numberTicketClaimed);
        console.log("Number winnings: %s", numberWinnings);
        console.log("Latest ticket claimed: %s", latestTicketClaimTime);

    }
}
