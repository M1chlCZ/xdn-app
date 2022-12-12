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
    console.log("Restoring accounts");
    await getAccounts();
    con.end();
}

async function getAccounts() {
    try {
      var [r, f] = await con.query("SELECT priv_key as privkey FROM masternode_clients WHERE 1");
      for (var i = 0; i < r.length; i++) {
        // var address = r[i].addr;
        var privKey = r[i].privkey
        console.log(privKey)
        // var nick = r[i].username
        // await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 1000]);
        var priv = await setPrivKey(privKey);
        // var account = await assignAccount(nick, address);
        if(priv !== "err") {
          console.log("Imported priv key for user: " + priv);
          // await con.query("UPDATE users SET privkey = ? WHERE addr = ?", [priv, address]);
        }
        await rpc.run('walletlock', []);
      }
    } catch (e) {
      console.log(e);
      return e;
    }
  }


async function setPrivKey(address) {
  try {
    var r = await rpc.run('importprivkey', [address.toString()]);
    if (r.error === null) {
      return r.result;
    } else {
      return "err";
    }
  } catch (e) {
    return "err";
  }
}

async function assignAccount(account, address) {
  try {
    var r = await rpc.run('setaccount', [address.toString(), account.toString()]);
    if (r.error === null) {
      return r.result;
    } else {
      return "err";
    }
  } catch (e) {
    return "err";
  }
}