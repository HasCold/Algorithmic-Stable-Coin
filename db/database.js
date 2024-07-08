const ethPriceDB = require("./ethPrice.db.json");   // Database - 1
const h2usdPriceDB = require("./h2usdPrice.db.json");  // Database - 2
const fs = require("fs").promises; // we are not using the node file-system module or fs module. Here we are using fs with asynchoronous or promise way

const readDB = async (token) => {
    try {
        if(token === "eth"){
            const output = await fs.readFile("./db/ethPrice.db.json", function(err, data) {
                if(err) throw err;
                return Buffer.from(data);  // In JavaScript, a buffer is a region of memory used to temporarily store data while it is being moved from one place to another. 
            });
            console.log(output);
            const priceDB = JSON.parse(output);
            return priceDB
        }else {
            const output = await fs.readFile("./db/h2usdPrice.db.json", function(err, data) {
                if(err) throw err;
                return Buffer.from(data);  // In JavaScript, a buffer is a region of memory used to temporarily store data while it is being moved from one place to another. 
            });
            console.log(output);
            const priceDB = JSON.parse(output);
            return priceDB;
        }

    } catch (err) {
        console.error(err.message);
    }
}


const writeDB = async (price, time, lastEntry, token) => {
    try {
        let entry = {
            updatedPrice: price,
            timeDate: time,
            entry: lastEntry + 1
        }

        if(token === "eth"){
            ethPriceDB.push(entry);
            let output = await fs.writeFile("./db/ethPrice.db.json", JSON.stringify(ethPriceDB), err => {
                if(err) throw err;
                return "Done" 
            });
            return output;
        }else{
            h2usdPriceDB.push(entry);
            let output = await fs.writeFile("./db/h2usdPrice.db.json", JSON.stringify(h2usdPriceDB), err => {
                if(err) throw err;
                return "Done" 
            });
            return output;
        }

    } catch (error) {
        console.error(error.message);
    }
}

module.exports = {readDB, writeDB}