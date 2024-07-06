const {ethers} = require("ethers");
const oracleABI = require("./oracle.ABI.json");
const reserveABI = require("./h2usdReserves.ABI.json");
const h2usdABI = require("./h2usd.ABI.json");

const oracleEthMainnet = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";  // Chainlink Eth Fairly Actual Price 
const reserveContract = "0x3007628dA48D228C23b67De2fFeF2A6b3D5e0e09";
const h2usdContract = "0x9E66067C87Cba0FE643c85e5998EB59EDa661ef6"; 

const ethRPC = "https://rpc.ankr.com/eth";
const sepoliaRPC = "https://ethereum-sepolia.blockpi.network/v1/rpc";

const ethProvider = new ethers.JsonRpcProvider(ethRPC);
const sepoliaProvider = new ethers.JsonRpcProvider(sepoliaRPC);

const privateKey = "89b0896f8b0fea1cec2d7dfd0204ba63e896d4b58581d299aea477dc3f2b2a35"; // wallet key to call on the blockchain
// A Wallet manages a single private key which is used to sign transactions, messages and other common payloads. ethWallet and sepoliaWallet are attached to our rpc nodes
const ethWallet = new ethers.Wallet(privateKey, ethProvider); 
const sepoliaWallet = new ethers.Wallet(privateKey, sepoliaProvider);

const ethOracle = new ethers.Contract(oracleEthMainnet, oracleABI, ethWallet);
const reserves = new ethers.Contract(reserveContract, reserveABI, sepoliaWallet);
const h2usd = new ethers.Contract(h2usdContract, h2usdABI, sepoliaWallet);


const getEthPrice = async () => {
    await ethOracle.latestRoundData().then(data => {
        console.log(data);
    }).catch(err => console.error(err.message));
}

getEthPrice();