const { expect } = require('chai');
// const { ethers } = require('hardhat');

describe('BlueICO', function () {
  let BlueCoin,
    bluecoin,
    BlueICO,
    blueico,
    State,
    dev,
    owner,
    depositAccount,
    investor1,
    investor2,
    investor3,
    demoAccount;

  const token_price = 10 ** 9; // expressed in wei, the price is 1gwei

  const SUPPLY_INITIAL = ethers.utils.parseEther('2000000'); // number of initial tokens
  const SUPPLY_FOR_ICO = ethers.utils.parseEther('1000000'); // number of initial tokens // tokens approved for ICO
  const decimals_str = '000000000000000000';
  const price_gap_decimals = '000000000'; // the gap of decimals between 18 and the price (9) is 9

  const TWO_WEEKS = 60 * 60 * 24 * 7 * 2; // two weeks in seconds

  // delay the blockchain for a given time
  const delay = (seconds) => {
    // NOTE: this is how we check the block timestamp
    // let block1 = await ethers.provider.getBlock();
    // console.log(block1.timestamp);
    ethers.provider.send('evm_increaseTime', [seconds]);
    ethers.provider.send('evm_mine');
    // let block2 = await ethers.provider.getBlock();
    // console.log(block2.timestamp);
  };

  beforeEach(async function () {
    State = {
      inactive: 0,
      active: 1,
    };

    [dev, owner, depositAccount, investor1, investor2, investor3, demoAccount] = await ethers.getSigners();

    // deploy Token
    Coin = await ethers.getContractFactory('BlueCoin');
    coin = await Coin.connect(dev).deploy(owner.address, SUPPLY_INITIAL);
    await coin.deployed();

    // deploy ICO based on this Token
    BlueICO = await ethers.getContractFactory('BlueICO');
    blueico = await BlueICO.connect(dev).deploy(coin.address);
    await blueico.deployed();

    // approve a certain supply for ICO
    await coin.connect(owner).approve(blueico.address, SUPPLY_FOR_ICO);
  });

  describe('Deployement setup of ICO', function () {
    it('Owner is the legitimate owner of ICO', async function () {
      expect(await blueico.getOwner()).to.equal(owner.address);
    });

    it('Initial Token Supply (SUPPLY_INITIAL) is minted to owner', async function () {
      let balance = await coin.balanceOf(owner.address);
      expect(balance).to.equal(SUPPLY_INITIAL + decimals_str);
    });

    it('Partial ICO Supply (SUPPLY_FOR_ICO) is delegated from owner to contract address', async function () {
      // the allowance is equal to 1000000
      expect(await coin.allowance(owner.address, blueico.address)).to.equal(SUPPLY_FOR_ICO);
    });

    it('Initially the contract should be active', async function () {
      // NOTE: for the first two weeks the contract will be active
      expect(await blueico.getState()).to.equal(State.active);
    });

    it('After two weeks the contract should be inactive', async function () {
      delay(TWO_WEEKS);
      expect(await blueico.getState()).to.equal(State.inactive);
    });
  });

  describe('Transfer Ether', function () {
    it('direct transfer of Ether to the ICO contract (receive)', async function () {
      // IMPORTANT NOTE! await is outside the expect() function
      await expect(() => investor1.sendTransaction({ to: blueico.address, value: token_price })).to.changeEtherBalance(
        blueico,
        token_price
      );
    });

    it('transfer of Ether through function buyTokens()', async function () {
      // Javascript converts number + string into a string
      await blueico.connect(investor2).buyTokens({ value: 5 * token_price });
      expect(await coin.balanceOf(investor2.address)).to.equal(5 * token_price + price_gap_decimals);
    });

    it('can not transfer Ether if it is not divisible by the price', async function () {
      let failure = blueico.connect(investor2).buyTokens({ value: 5 * token_price + 1 });
      await expect(failure).to.revertedWith(
        "BlueICO: Contract doesn't give back change. The received amount must be divisible by price."
      );
    });
  });

  describe('Test contract expiration', function () {
    it('Can not buy 1 token when ICO is expired', async function () {
      delay(TWO_WEEKS);

      await expect(blueico.connect(investor3).buyTokens({ value: token_price })).to.be.revertedWith(
        'BlueICO: This operation is reserved for active contracts.'
      );
    });

    it('Can not transfer Ether directly to the ICO contract (receive) when expired', async function () {
      delay(TWO_WEEKS);
      await expect(investor1.sendTransaction({ to: blueico.address, value: 1000 })).to.revertedWith(
        'BlueICO: This operation is reserved for active contracts.'
      );
    });
  });

  describe('Owner withdraws investment from ICO', function () {
    it('Before ICO gets expired, owner can not withdraw investment', async function () {
      await blueico.connect(investor1).buyTokens({ value: token_price });

      // IMPORTANT! await must be outside of expect(), not inside
      await expect(blueico.connect(owner).withdrawEther()).to.revertedWith(
        'BlueICO: This operation is reserved for inactive contracts.'
      );
    });

    it('After ICO gets expired, owner withdraws investment', async function () {
      await blueico.connect(investor2).buyTokens({ value: token_price });

      delay(TWO_WEEKS);

      expect(await blueico.connect(owner).withdrawEther()).to.changeEtherBalances(
        [blueico, owner],
        [-token_price, token_price]
      );
    });

    it('After ICO gets expired, non-owner can not withdraw investment', async function () {
      await blueico.connect(investor2).buyTokens({ value: token_price });

      delay(TWO_WEEKS);

      await expect(blueico.connect(investor2).withdrawEther()).to.reverted;
    });
  });

  describe('Check emission of events', function () {
    it('When buying tokens with buyTokens(), a Deposit event emits', async function () {
      let buy = await blueico.connect(investor2).buyTokens({ value: token_price });

      await expect(buy).to.emit(blueico, 'Deposit').withArgs(investor2.address, token_price);
    });

    it('When buying tokens directly, with receive(), a Deposit event emits', async function () {
      let buy = await investor1.sendTransaction({ to: blueico.address, value: token_price });

      await expect(buy).to.emit(blueico, 'Deposit').withArgs(investor1.address, token_price);
    });

    it('When owner withdraws all ether, a Withdraw event emits', async function () {
      await blueico.connect(investor3).buyTokens({ value: token_price });

      delay(TWO_WEEKS);

      let ContractBalance = await ethers.provider.getBalance(blueico.address);

      let withdrawal = await blueico.connect(owner).withdrawEther();

      await expect(withdrawal).to.emit(blueico, 'Withdraw').withArgs(owner.address, ContractBalance);
    });
  });
});
