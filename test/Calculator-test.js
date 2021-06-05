const { expect } = require('chai');

describe('Calculator', () => {
  let BlueICO, blueico, Calculator, calculator, Coin, coin, dev, owner, user1, user2, user3, alice, john;
  const token_price = 10 ** 9; // expressed in wei, the price is 1gwei

  beforeEach(async () => {
    const SUPPLY_INITIAL = ethers.utils.parseEther('2000000'); // number of initial tokens
    const SUPPLY_FOR_ICO = ethers.utils.parseEther('1000000'); //
    [dev, owner, user1, user2, user3, alice, john] = await ethers.getSigners();

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

  describe('Deployment', function () {
    it('Calculator has same owner with Coin', async function () {
      expect(await calculator.getOwner()).to.equal(await coin.getOwner());
    });

    // it('When alice makes 2 calculations, owner gets back 2 tokens', async function () {

    //   expect(await calculator.getOwner()).to.equal(await coin.getOwner());
    // });
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
    });

    it('substract', async function () {
      expect(await calculator.connect(user2).sub(3, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('sub', user2.address, 3, 2, 1);
    });

    it('divide', async function () {
      expect(await calculator.connect(user2).div(10, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('div', user2.address, 10, 2, 5);
    });

    it('multiply', async function () {
      expect(await calculator.connect(user2).mul(10, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('mul', user2.address, 10, 2, 20);
    });

    it('modulo', async function () {
      expect(await calculator.connect(user2).mod(11, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('mod', user2.address, 11, 2, 1);
    });
  });

  describe('Alice buys 2 tokens, but approves only 1 for the Calculator', function () {
    beforeEach(async function () {
      await blueico.connect(alice).buyTokens({ value: 2 * token_price });
      await coin.connect(alice).approve(calculator.address, ethers.utils.parseEther('1'));
    });

    it('Alice can perform one calculation', async function () {
      expect(await calculator.connect(alice).mod(11, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('mod', alice.address, 11, 2, 1);
    });

    it('Alice does not have enough allowance to perform a second calculation', async function () {
      firstCalculation = await calculator.connect(alice).mod(11, 2);

      await expect(calculator.connect(alice).add(2, 2)).to.be.revertedWith('ERC20: transfer amount exceeds allowance');
    });
  });

  describe('John buys 2 tokens, but approves 4 for the Calculator', function () {
    beforeEach(async function () {
      await blueico.connect(john).buyTokens({ value: 2 * token_price });
      await coin.connect(john).approve(calculator.address, ethers.utils.parseEther('4'));
    });

    it('John can perform two calculations', async function () {
      expect(await calculator.connect(john).add(2, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('add', john.address, 2, 2, 4);

      expect(await calculator.connect(john).add(2, 2))
        .to.emit(calculator, 'Calculation')
        .withArgs('add', john.address, 2, 2, 4);
    });

    it('John has allowance, but not enough tokens to perform a third calculation', async function () {
      let first = await calculator.connect(john).add(2, 2);
      let second = await calculator.connect(john).add(2, 2);
      await expect(calculator.connect(john).add(2, 2)).to.be.revertedWith(
        'Calculator: you need to buy more tokens to perform this operation'
      );
    });
  });
});
