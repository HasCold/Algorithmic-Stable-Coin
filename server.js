
// --------------------------------------- Body-Parser ------------------------------------------------
// body-parser: Used to parse the body of incoming HTTP requests, making it easy to handle data sent in various formats like JSON and URL-encoded forms.
// Parse application/x-www-form-urlencoded
// app.use(bodyParser.urlencoded({ extended: false }));

// Parse application/json
// app.use(bodyParser.json());
// console.log(req.body); // Access the parsed body data


// ------------------------------------------ Cookie-Parser ------------------------------------------ 
// cookie-parser: Used to parse cookies attached to the client request, making it easy to handle and access cookie data in your application. 
// req.cookies // Access the parsed cookies
// req.signedCookies  // Access the parsed signed cookies if any


const express = require('express');
const cors= require("cors");
const { getDbData, storeEthPrice, storeH2USDPrice } = require('./interface');

const corsOptions ={
    origin:'*', 
    optionSuccessStatus:200,
}

const app = express();

app.use(express.json());  // accept json data from frontend
app.use(express.urlencoded({extended: true}));  
app.use(cors(corsOptions));

app.post("/getChartInfo", (req, res) => {
    const {token} = req.body;
    if(!token) throw new Error("Not Authenticated !");

    return new Promise((resolve, reject) => {
        getDbData(token).then(response => {
            res.statusCode = 200;
            res.setHeader("Content-Type", "application/json");
            res.setHeader("Cache-Control", "max-age=180000");
            res.end(JSON.stringify(response));
            resolve();
        }).catch(err => {
            res.json(err.message);
            res.status(405).end();
        }) 
    });
});

const refreshEthPrice = async () => setInterval(() => {
    storeEthPrice();
}, 20000);  // 20 milliseconds = 20 seconds

const refreshH2USDPrice = async () => setInterval(() => {
    storeH2USDPrice();
}, 20000);  // 20 milliseconds = 20 seconds

const server = app.listen(5000, () => {
    const port = server.address().port;
    refreshEthPrice();
    refreshH2USDPrice();

    console.log('Server Is Running On Port: ' + port)
});
