const {getEthPrice, getH2USDPrice} = require("./getPrices");
const {readDB, writeDB} = require("./db/database");

const getDBData = async (token) => {
    try {
        let fromOutput = await readDB(token);
        let chartPrice = [];  // y-axis
        let chartTime = [];  // x-axis
        let chartEntry = [];  // gives the number of chart entries

        if(fromOutput != undefined){
            fromOutput.forEach((value) => {
                chartPrice.push(value.updatedPrice);
                chartTime.push(value.timeDate);
                chartEntry.push(value.entry);
            });
        }
        return {chartPrice, chartTime, chartEntry};

    } catch (error) {
        console.error(error.message);
    }
}

const storeEthPrice = async () => {
    try {
        const token = "eth";
        let price = await getEthPrice();
        const fetchTime = new Date();
        const time = `${fetchTime.getHours()} : ${fetchTime.getMinutes()} : ${fetchTime.getSeconds()}`

        const {chartPrice, chartTime, chartEntry} = await getDBData(token); 
        let rawLastEntry = chartEntry;

        if(rawLastEntry.length == 0){
            let entry = 0;
            await writeDB(price, time, entry, token);

        }else if(rawLastEntry.length > 0){
            let lastEntry = rawLastEntry[rawLastEntry.length - 1];
            await writeDB(price, time, lastEntry, token);
        }

    } catch (error) {
        console.error(error.message);
    }
}


// Store H2USD Price
const storeH2USDPrice = async () => {
    try {
        const token = "h2usd";
        let price = await getH2USDPrice();
        const fetchTime = new Date();
        const time = `${fetchTime.getHours()} : ${fetchTime.getMinutes()} : ${fetchTime.getSeconds()}`

        const {chartPrice, chartTime, chartEntry} = await getDBData(token); 
        let rawLastEntry = chartEntry;

        if(rawLastEntry.length == 0){
            let entry = 0;
            await writeDB(price, time, entry, token);

        }else if(rawLastEntry.length > 0){
            let lastEntry = rawLastEntry[rawLastEntry.length - 1];
            await writeDB(price, time, lastEntry, token);
        }

    } catch (error) {
        console.error(error.message);
    }
}

module.exports = {storeEthPrice, storeH2USDPrice, getDBData}