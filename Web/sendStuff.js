const CampusAsync = require('./lib/campus-async.js');
const mysql = require('mysql2/promise');
require('dotenv').config();

const rpc = new CampusAsync(process.env.ENC_CRYPTO);

var con;

// exports.runNotify = runNotify;

// setInterval(runNotify, 86400000);
// console.log(process.argv[2]);
runNotify();

async function runNotify() {
    con = mysql.createPool({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_SELECT,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
    });
    console.log("Accounts recreate");
    const daemonRPC = await rpc.run('getinfo');
    if (daemonRPC.result !== null) {
        console.log("Waiting for daemon to start");
        await sleep(10000);
        await getAccounts();
        con.end();
    } else {
        console.log("Daemon is not running");
    }
}

async function getAccounts() {
    console.log("GetAccounts");
    await sleep(1000);
    try {
        var [r, f] = await con.query("SELECT a.account as account, SUM(a.amount) as amount, b.addr as addr FROM transaction as a, users as b WHERE a.account = b.username GROUP BY a.account, b.addr");
        for (var i = 0; i < r.length; i++) {
            let address = r[i].addr;
            let amount = r[i].amount;
            let account = r[i].account;

            if (account === "aucrhi" || account === "copiercowboy" || account === "DnkeyStain" || account === "Duckie" || account === "editxx" || account === "fabrazio" || account === "goojachung" || account === "IamLupo" || account === "jahvinci" || account === "johnhamm" || account === "JuMoney" || account === "kingdavie" || account === "Leighw" || account === "litecoinfam") {
                console.log("continue");
                continue;
            }
            const daemonRPC = await rpc.run('sendtoaddress', [address.toString(), parseFloat(amount)]);
            if (daemonRPC.result === null) {
                break;
            }
            console.log(account + " " + daemonRPC.result);
            await sleep(80000);
        }
    } catch (e) {
        console.log(e);
        return e;
    }
}

function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}


async function getPrivKey(address) {
    try {
        var r = await rpc.run('dumpprivkey', [address.toString()]);
        if (r.error === null) {
            return r.result;
        } else {
            return "err";
        }
    } catch (e) {
        return "err";
    }
}




