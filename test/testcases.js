const { expect } = require("chai");
// const { ethers } = require("ethers");

describe("Marketplace Contract", function()
{
    let Token;
    let hardhatToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;
    let NFTListedPrice = 1;

    beforeEach(async () =>
    {
        Token = await ethers.getContractFactory("NFTMarketplace");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        hardhatToken =  await Token.deploy();
    });

    describe("Deployment", function()
    {
        it("Should set the right owner",  async function()
        {
            expect(await hardhatToken.owner()).to.equal(owner.address);
        });

        it("Minimum Ether value",  async function()
        {
            expect(await hardhatToken.getListPrice()).to.equal(NFTListedPrice);
        });
    });
});