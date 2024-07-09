import {ethers} from "ethers";
import rsvABI from "../../ABI/rsvabi.json";
import h2usdABI from "../../ABI/h2usdabi.json";

const rsvContract = "0x3007628dA48D228C23b67De2fFeF2A6b3D5e0e09";
const h2usdContract = "0x9E66067C87Cba0FE643c85e5998EB59EDa661ef6"; 

const sepoliaRPC = "https://eth-sepolia.public.blastapi.io";
const provider = new ethers.JsonRpcProvider(sepoliaRPC);
const privateKey = "89b0896f8b0fea1cec2d7dfd0204ba63e896d4b58581d299aea477dc3f2b2a35"; // wallet key to call on the blockchain
const wallet = new ethers.Wallet(privateKey, provider);  // A Wallet manages a single private key which is used to sign transactions, messages and other common payloads. sepoliaWallet are attached to our rpc nodes

const reserves = new ethers.Contract(rsvContract, rsvABI, wallet);
const h2usd = new ethers.Contract(h2usdContract, h2usdABI, wallet);

export const getReserves = async () => {
    try {
        const rsvCount = Number((await reserves.currentReserveId()).toString());
        const h2usdSupply = (await h2usd.totalSupply()).toString(); 

        let rsvAmount = [];
        for(let i = 0; i < rsvCount; i++){
            const vaultInfo = await reserves._rsvVault(i);
            const getBalance = vaultInfo.amount.toString();
            let formatBalance = ethers.formatEther(getBalance);
            rsvAmount.push(formatBalance);
        }
        return {rsvAmount, h2usdSupply}

    } catch (error) {
        console.error(error.message);
    }
}