/* eslint-disable no-undef */
const { expect } = require('chai');

describe('Calculator', () => {
  let BlueICO, blueico, Calculator, calculator, Coin, coin, dev, owner, user1, user2, user3;

  beforeEach(async () => {
    const token_price = 10 ** 9; // expressed in wei, the price is 1gwei
    const SUPPLY_INITIAL = ethers.utils.parseEther('2000000'); // number of initial tokens
    const SUPPLY_FOR_ICO = ethers.utils.parseEther('1000000'); //
    [dev, owner, user1, user2, user3] = await ethers.getSigners();

    Coin = await ethers.getContractFactory('BlueCoin');
    coin = await Coin.connect(dev).deploy(owner.address, SUPPLY_INITIAL);
    await coin.deployed();

    BlueICO = await ethers.getContractFactory('BlueICO');
    blueico = await BlueICO.connect(dev).deploy(coin.address);
    await blueico.deployed();

    Calculator = await ethers.getContractFactory('Calculator');
    calculator = await Calculator.deploy(coin.address);
    await calculator.deployed();

    // approve a certain supply for ICO
    await coin.connect(owner).approve(blueico.address, SUPPLY_FOR_ICO);

    // user1 buys 1 token  -  balance 1000000000000000000
    await blueico.connect(user1).buyTokens({ value: 1 * token_price });

    // user2 buys 2 tokens - balance 2000000000000000000
    await blueico.connect(user2).buyTokens({ value: 2 * token_price });

    // user3 buys 3 tokens - balance 3000000000000000000
    await blueico.connect(user3).buyTokens({ value: 3 * token_price });

    // approve a certain supply for Calculator ???
    // await coin.approve(calculator.address, ethers.utils.parseEther('4'));
  });

  describe('Emit Basic Calculations', function () {
    beforeEach(async function () {
      // approve 1 token -  balance 1000000000000000000
      await coin.connect(user2).approve(calculator.address, ethers.utils.parseEther('1'));
    });

    it('add', async function () {
      expect(await calculator.connect(user2).add(3, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('add', user2.address, 3, 2, 5);
      1;
    });

    it('substract', async function () {
      expect(await calculator.connect(user2).sub(3, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('sub', user2.address, 3, 2, 1);
      1;
    });
  });
});
