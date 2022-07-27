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
        console.log(daemonRPC.result);
    
        await getAccounts();
        con.end();
    } else {
        console.log("Daemon is not running");
    }
}

async function getAccounts() {
    try {
        var [r, f] = await con.query("SELECT username, addr FROM users WHERE 1");
        for (var i = 0; i < r.length; i++) {
            let username = r[i].username;
            let oldAddr = r[i].addr;
            const daemonRPC = await rpc.run('getnewaddress', [username]);
            let newAddr = daemonRPC.result;
            let priv = await getPrivKey(newAddr);
            console.log("/////")
            console.log(username, oldAddr, newAddr, priv);
            console.log("/////")
            if (priv !== "err") {
                await con.query("UPDATE users SET privkey = ?, addr = ? WHERE username = ?", [priv, newAddr, username]);
                await con.query("UPDATE messages SET receiveAddr = ? WHERE receiveAddr = ?", [newAddr, oldAddr]);
                await con.query("UPDATE messages SET sentAddr = ? WHERE sentAddr = ?", [newAddr, oldAddr]);
                await con.query("UPDATE addressbook SET addr = ? WHERE addr = ?", [newAddr, oldAddr]);
                await con.query("UPDATE transaction SET address = ? WHERE address = ?", [newAddr, oldAddr]);
            }
        }
    } catch (e) {
        console.log(e);
        return e;
    }
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




