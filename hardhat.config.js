require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();
const { ETHERSCAN_KEY, API_URL, API_URL_TESTNET, PRIVATE_KEY } = process.env;
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [{version: "0.8.4"},
    {version: "0.6.6"}],

  },
  networks: {
    hardhat: {
      forking:  {
        url: API_URL
      }
    }
  },
  networks: {
		local: {
			url: 'http://127.0.0.1:8545'
	  	},
    hardhat: {
      forking:  {
        url: API_URL
      }
    },
    rinkeby: {
      url: API_URL_TESTNET,
      accounts: [`0x${PRIVATE_KEY}`]
    }
	},
};


