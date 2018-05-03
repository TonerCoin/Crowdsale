module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      from: "0xc94362c0e8106b521d9122a0127bbd63125cd99b",
      host: "127.0.0.1",
      port: 8545,
      network_id: "4",
      gas: 4684588
      //gas: 4704588
    },
  }
};
