const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = require("ethers")

const name                = "My NFT";
const symbol              = "MNFT";
const maxSupply           = 100;
const baseURI1             = "https://one.com/"
const baseURI2             = "https://two.com/"
const baseURI3             = "https://three.com/"
const baseURI4             = "https://four.com/"
const baseURI5             = "https://five.com/"
const notRevealedURI       = "https://notRevealedURI.com"
const mintLimitPreSale     = 1;
const mintLimitPublicSale  = 1;
const preSalePrice         = utils.parseEther("0.1");
const publicSalePrice      = utils.parseEther("0.15");


describe("Token contract", function () {
    let MyNFT, NFT, owner, addr1, addr2, addr3;

    before(async () => {
        MyNFT = await ethers.getContractFactory('MyNFT');
        NFT = await MyNFT.deploy();
        await NFT.deployed();
        [owner, addr1, addr2, addr3, _] = await ethers.getSigners();
    });

    describe('Deployment', () => {
      it('Should set the right name', async() => {
          expect(await NFT.name()).to.equal(name);
      });

      it('Should set the right symbol', async() => {
          expect(await NFT.symbol()).to.equal(symbol);
      });

      it('Should set the right owner', async() => {
        expect(await NFT.owner()).to.equal(owner.address);
      });

      it('Should set revealed = false', async() => {
        expect(await NFT.revealed()).to.equal(false);
      });

      it('Should set the correct base URI', async() => {
        await NFT.setURI(baseURI1, baseURI2, baseURI3, baseURI4, baseURI5);
        expect(await NFT.baseURI1()).to.equal(baseURI1);
        expect(await NFT.baseURI2()).to.equal(baseURI2);
        expect(await NFT.baseURI3()).to.equal(baseURI3);
        expect(await NFT.baseURI4()).to.equal(baseURI4);
        expect(await NFT.baseURI5()).to.equal(baseURI5);
      });

      it('Should return the correct balance of the owner', async() => {
        expect(await NFT.balanceOf(owner.address, 0)).to.equal(0);
      });

      it('Should set the correct paused state', async() => {
        expect(await NFT.paused()).to.equal(true);
      });

      it('Should set the correct totalSupply', async() => {
        expect(await NFT.totalSupply(0)).to.equal(0);
      });
    });

    describe('Set not revealed URI', () => {
      it('Only owner can call setNotRevealedURI', async() => {
        await expect(NFT.connect(addr1).setNotRevealedURI(notRevealedURI)).to.be.revertedWith('Ownable: caller is not the owner');
      });

      it('Able to set not revealed URI', async() => {
        await NFT.setNotRevealedURI(notRevealedURI);
        expect(await NFT.notRevealedUri()).to.equal(notRevealedURI);
      });
    });

    describe('Whitelist', () => {
      it('Only owner can Whitelist', async() => {
        const _address = [addr1.address, addr2.address];
        await expect(NFT.connect(addr1).addToWhitelist(_address)).to.be.revertedWith('Ownable: caller is not the owner');
      });

      it('Whitelist works', async() => {
        const _address = [addr1.address, addr2.address];
        await NFT.addToWhitelist(_address);
        expect(await NFT.isWhiteListed(addr1.address)).to.equal(true);
      });
    });

    describe('Test functions for state variables', () => {
      describe('setPreSalePrice', () => {
        it('Only owner can setPreSalePrice', async() => {
          await expect(NFT.connect(addr1).setPreSalePrice(preSalePrice)).to.be.revertedWith('Ownable: caller is not the owner');
        });
        it('SetPreSalePrice works', async() => {
          await NFT.setPreSalePrice((preSalePrice));
          expect(await NFT.preSalePrice()).to.equal(preSalePrice);
        });
      });

      describe('setPublicSalePrice', () => {
        it('Only owner can setPublicSalePrice', async() => {
          await expect(NFT.connect(addr1).setPublicSalePrice(publicSalePrice)).to.be.revertedWith('Ownable: caller is not the owner');
        });
        it('SetPublicSalePrice works', async() => {
          await NFT.setPublicSalePrice((publicSalePrice));
          expect(await NFT.publicSalePrice()).to.equal(publicSalePrice);
        });
      });
    });
    
    describe('Test functions for state variables', () => {
      it('pause and unpause works', async() => {
        expect(await NFT.paused()).to.equal(true);
        await NFT.unpause();
        expect(await NFT.paused()).to.equal(false);
        await NFT.pause();
        expect(await NFT.paused()).to.equal(true);
      });

      it('Only owner can pause and unpause the contract', async() => {
        await expect(NFT.connect(addr1).pause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(NFT.connect(addr1).unpause()).to.be.revertedWith('Ownable: caller is not the owner');
      });

      it('Toggle publicSale works', async() => {
        expect(await NFT.publicSaleActive()).to.equal(false);
        await NFT.togglePublicSale();
        expect(await NFT.publicSaleActive()).to.equal(true);
        await NFT.togglePublicSale();
        expect(await NFT.publicSaleActive()).to.equal(false);
      });

      it('Only owner can change the public sale', async() => {
        await expect(NFT.connect(addr1).togglePublicSale()).to.be.revertedWith('Ownable: caller is not the owner');
      });

      it('Toggle preSale works', async() => {
        expect(await NFT.preSaleActive()).to.equal(false);
        await NFT.togglePreSale();
        expect(await NFT.preSaleActive()).to.equal(true);
        await NFT.togglePreSale();
        expect(await NFT.preSaleActive()).to.equal(false);
      });

      it('Only owner can change the public sale', async() => {
        await expect(NFT.connect(addr1).togglePreSale()).to.be.revertedWith('Ownable: caller is not the owner');
      });
    });

    describe('Public Sale', () => {

      it('Mint does not exceed limit when payee holds zero tokens and amount > limit', async() => {
        await NFT.unpause();
        await expect(NFT.connect(addr1).publicSaleMint(8)).to.be.revertedWith("");
      });

      it('Mint 1 token', async() => {
        // before mint the token should show not existent
        //await expect(NFT.uri(0)).to.be.revertedWith("ERC1155Metadata: URI query for nonexistent token");
        await NFT.togglePublicSale();
        // mint 1 NFT
        await NFT.connect(addr1).publicSaleMint(1, {
            value: ethers.utils.parseEther((parseFloat(0.15)).toString())
        });
        // total supply should increase
        expect(await NFT.totalSupply(0)).to.equal(1);
        // balance of minter should show correct amount
        expect(await NFT.balanceOf(addr1.address, 0)).to.equal(1);
      });

      it('Only owner can call reveal', async() => {
        await expect(NFT.connect(addr1).reveal()).to.be.revertedWith('Ownable: caller is not the owner');
      });

      it('Reveal works', async() => {
        await NFT.reveal();
        expect(await NFT.revealed()).to.equal(true);
      });

      it('Check uri for >+10%' , async() => {
        let currentPrice = 110;
        let oldPrice     = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        console.log(await NFT.currentPrice());
        console.log(await NFT.oldPrice());
        expect(await NFT.uri(0)).to.equal(baseURI1);
      });

      it('Check uri for 5%<=x<10%' , async() => {
        let currentPrice = 105;
        let oldPrice     = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        console.log(await NFT.currentPrice());
        console.log(await NFT.oldPrice());
        expect(await NFT.uri(0)).to.equal(baseURI2);
      });

      it('Check uri for -5%<x<5%' , async() => {
        let currentPrice = 102;
        let oldPrice     = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI3);
        currentPrice = 98;
        oldPrice = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI3);
        currentPrice = 95;
        oldPrice = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI3);
      });

      it('Check uri for -5% < x < 5%' , async() => {
        let currentPrice = 94;
        let oldPrice     = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI4);
      });

      it('Check uri for x < -10%' , async() => {
        let currentPrice = 90;
        let oldPrice     = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI5);
        currentPrice = 80;
        oldPrice = 100;
        await NFT.setPriceOld(currentPrice, oldPrice)
        expect(await NFT.uri(0)).to.equal(baseURI5);
      });
    });

});
