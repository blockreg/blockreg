const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');
module.exports = {
  contracts_directory: "./src/contracts",
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    "kovan": {
      network_id: 42,
      gasPrice: 100000000000,
      provider: new HDWalletProvider(fs.readFileSync('./secret.env', 'utf-8'), "https://kovan.infura.io/v3/1d69cc96b8c84979933c05b7b350a175")
    }
  },
  compilers: {
    solc: {
      version: "0.8.10"
    }
  }
};
