const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = require("ethers")

const DECIMALS = "18";
const INITIAL_PRICE = '200000000000000000000'

describe("Greeter", function () {
    before(async () => {
        MockV3Aggregator = await ethers.getContractFactory('MockV3Aggregator');
        mockV3Aggregator = await MockV3Aggregator.deploy(DECIMALS, INITIAL_PRICE);
        await mockV3Aggregator.deployed();

        PriceConsumerV3 = await ethers.getContractFactory('PriceConsumerV3');
        priceConsumerV3 = await PriceConsumerV3.deploy(mockV3Aggregator.address);
        await mockV3Aggregator.deployed();
    });

    it('Fetch mock value', async function () {
        console.log(await priceConsumerV3.data());
    });
/* 
    let DummyChainlinkFactory, dummyChainlink;
    let PriceConsumerV3Factory, oracle, owner, addr1, addr2, addr3;

    beforeEach(async () => {
        DummyChainlinkFactory  = await ethers.getContractFactory('DummyChainLink');
        dummyChainlink         = await DummyChainlinkFactory.deploy()
        await dummyChainlink.deployed();
        //console.log(dummyChainlink);
        PriceConsumerV3Factory = await ethers.getContractFactory('PriceConsumerV3');
        oracle = await PriceConsumerV3Factory.deploy();
        await oracle.deployed(); 
        [owner, addr1, addr2, addr3, _] = await ethers.getSigners();
    }); */

});
