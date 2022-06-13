const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    [alice,bob] = await ethers.getSigners()
    const Greeter = await ethers.getContractFactory("IkonicVesting");
    const greeter = await Greeter.deploy();
    await greeter.deployed();
    const block = await ethers.getDefaultProvider().getBlock('latest')
    let time = block.timestamp-1000
    await greeter.setDates(time,true)
    // await greeter.setDay(60)
    await greeter.adminAddInvestors([[alice.address,ethers.utils.parseEther('1000'),8]])

    await network.provider.send("evm_increaseTime", [24*3600]);
    console.log(await greeter.getAvailableBalance(alice.address))
    // expect(await greeter.greet()).to.equal("Hello, world!");
    //
    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");
    //
    // // wait until the transaction is mined
    // await setGreetingTx.wait();
    //
    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
