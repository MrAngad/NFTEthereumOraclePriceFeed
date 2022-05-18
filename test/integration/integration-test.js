const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = require("ethers")

describe("Test NFT", function () {
    let MyNFT, NFT, owner, addr1, addr2, addr3;

    before(async () => {
        MyNFT = await ethers.getContractFactory('MyNFT');
        NFT = await MyNFT.deploy();
        await NFT.deployed();
        [owner, addr1, addr2, addr3, _] = await ethers.getSigners();
    });

    it("Deploy checks", async function () {
        let currentPrice = 110;
        let oldPrice     = 100;

        await NFT.setURI("one.com", "two.com", "three.com", "four.com", "five.com");
        console.log(await NFT.baseURI2());
    });
});
