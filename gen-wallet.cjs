const { ethers } = require('ethers');
const wallet = ethers.Wallet.createRandom();
console.log(JSON.stringify({
  address: wallet.address,
  privateKey: wallet.privateKey,
  mnemonic: wallet.mnemonic.phrase
}, null, 2));
