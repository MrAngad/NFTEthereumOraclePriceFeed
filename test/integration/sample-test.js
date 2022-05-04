const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = require("ethers")

describe("Test oracle", function () {
  let MyNFT, NFT, owner, addr1, addr2, addr3;

  beforeEach(async () => {
    PriceConsumerV3Factory = await ethers.getContractFactory('PriceConsumerV3');
    oracle = await PriceConsumerV3Factory.deploy();
    await oracle.deployed();
    [owner, addr1, addr2, addr3, _] = await ethers.getSigners();
  });

  it("", async function () {
    let priceCurrent;
    let price;
    let timeStamp;
    let deviation;
    let sign;
    let flag;

    [priceCurrent, price, timeStamp] = await oracle.loop();
    console.log("price current", priceCurrent);
    console.log("price old", price);
    console.log("timeStamp old\n", timeStamp);

    [deviation, sign] = await oracle.loop2();
    console.log("deviation = ", deviation);
    console.log("sign = \n", sign);
    
    flag = await oracle.loop3();
    console.log(flag);
    
  });
});
