// var Ownable = artifacts.require("Ownable");

// NOTE: Use this file to easily deploy the contracts you're writing.
//   (but make sure to reset this file before committing
//    with `git checkout HEAD -- migrations/2_deploy_contracts.js`)

var TonerCoin = artifacts.require("./TonerCoin.sol");
var TonerCoinCrowdsale = artifacts.require("./TonerCoinCrowdsale.sol");


module.exports = function (deployer,network, accounts) {

  // helpers
  const BigNumber = web3.BigNumber;

  const userAddress = accounts[0];
  const rate = new BigNumber(5787); // количество токенов за единицу эфира
  const wallet = userAddress;

  deployer.deploy(TonerCoin);

  TonerCoin.deployed().then(function(tToner) {

    deployer.deploy(
      TonerCoinCrowdsale,
      rate,
      wallet,
      tToner.address,
    ).then(function() {
      TonerCoinCrowdsale.deployed().then(function(tCrowdsale) {
        tToner.transferOwnership(tCrowdsale.address);
      })
    })
  });

};
