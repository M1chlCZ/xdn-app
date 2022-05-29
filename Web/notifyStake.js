const CampusAsync = require('./lib/campus-async.js');
const mysql = require('mysql2/promise');
require('dotenv').config();

const rpc = new CampusAsync(process.env.ENC_CRYPTO_STAKE);
const rpcNormal = new CampusAsync(process.env.ENC_CRYPTO);

var con;

// exports.runNotify = runNotify;

setInterval(runNotify, 100000);
// console.log(process.argv[2]);
// runNotify();

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
    // console.log("cleaning messages");
    await rpcNormal.run('smsginbox', ["clear"]);
    await rpcNormal.run('smsgoutbox', ["clear"]);
    console.log("Checking stakes")
    await saveTransactions();
    await credit();
    await saveNormalTransactions();
    con.end();
}


async function saveTransactions() {
    var json;
    try {
        const res = await rpc.run('liststakerewards', [10]);
        var k = JSON.stringify(res);
        json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
        // console.log(json);
        await insertTransactions(json);
    } catch (error) {
        console.log(error);
    }
}

async function saveNormalTransactions() {
    var json;
    try {
      const res = await rpcNormal.run('listtransactions', ["*", 9999999]);
      var k = JSON.stringify(res);
      json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      // console.log(json);
      await insertNormalTransactions(json);
    } catch (error) {
      console.log(error);
    }
  }

async function insertNormalTransactions(js) {
    for (let key of js.result) {
      var account = key.account;
      var txid = key.txid;
      var amount = key.amount;
      var confirmation = key.confirmations;
      if (parseInt(confirmation) < 0) continue;
      var address = key.address;
      var cat = key.category;
      if (cat === 'immature' || cat === 'generate') continue;
      var timed = new Date(Number(key.time + "000"));
      var time = timed.toISOString().slice(0, 19).replace('T', ' ');
  
      var [r, f] = await con.query('SELECT * FROM transaction WHERE txid = ? AND category = ?', [txid, cat]);
      if (r[0] == null) {
        if (!isEmptyStr(account)) {
  
          var [rows, fields] = await con.query('SELECT * FROM transaction WHERE txid = ? AND account = ?', [txid, account]);
          if (rows[0] != null) {
            await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND account = ?', [confirmation, txid, account], function (err, result) {
            }).catch((e) => {
              console.log(e);
            });
          } else {
            await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category, date) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat, time], function (err, result) {
            }).catch((e) => {
              console.log(e);
            });
          }
  
        } else {
          var [rows, fields] = await con.query('SELECT * FROM transaction WHERE txid = ? AND category = ?', [txid, cat]);
          if (rows[0] != null) {
            await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND category = ?', [confirmation, txid, cat], function (err, result) {
            }).catch((e) => {
              console.log(e);
            });
          } else {
            await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category, date) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat, time], function (err, result) {
            }).catch((e) => {
              console.log(e);
            });
          }
        }
      } else {
        await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND category = ?', [confirmation, txid, cat]);
      }
    }
  
  }

  function isEmptyStr(str) {
    return (!str || 0 === str.length);
  }
  
  async function saveAddrBook(id, name, addr) {
    try {
      var [rows, fields] = await con.query('SELECT * FROM addressbook WHERE idUser = ? AND addr = ?', [id, addr]);
      console.log(rows);
      if (rows[0] == null) {
        await con.query("INSERT INTO addressbook (idUser, name, addr) VALUES (?,?,?)", [id, name, addr]);
      }
      var res = await con.query("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", [id]);
      return JSON.stringify(res[0]);
    } catch (e) {
      console.log(e);
    }
  }


async function insertTransactions(js) {
    for (let key of js.result) {
        var txid = key.txid;
        var amount = key.amount;
        var cat = key.category;
        // var time = key.time;
        var timed = new Date(Number(key.time + "000") + 5400000);
        // console.log(timed);
        var time = timed.toISOString().slice(0, 19).replace('T', ' ')
        if (cat === 'generate') {
            var [r, f] = await con.query('SELECT * FROM transaction_stake WHERE txid = ?', [txid]);
            if (r[0] == null) {
                console.log("Inserting new stake TX");
                await con.query('INSERT INTO transaction_stake(txid, amount, datetime) VALUES (?, ?, ?)', [txid, amount, time], function (err, result) {
                }).catch((e) => {
                    console.log(e);
                });
            }
        }
    }
}

async function credit() {
    var grandtotal = 0;
    var checkCredit = 0.0;
    var lastTX = [];
    var [rowsAmount, failAmount] = await con.query('SELECT SUM(amount) as amount FROM users_stake WHERE active = ?', [1]);
    if (rowsAmount[0].amount != null) {
        grandtotal = rowsAmount[0].amount;
    }
    var [rows, f] = await con.query('SELECT * FROM transaction_stake WHERE credited = ?', [0]);
    var [rowsUsers, failUsers] = await con.query('SELECT idUser, amount, session FROM users_stake WHERE active = ?', [1]);
    for (var i = 0; i < rows.length; i++) {
        console.log("///////////NEW STAKE INSERT///////////");
        checkCredit = 0.0
        var idTx = rows[i].id;
        var stakeAmount = rows[i].amount;
        var txid = rows[i].txid;
        if(lastTX === txid) continue;
        lastTX = txid;
        var dateTime = rows[i].datetime;
        console.log(idTx + " " + dateTime);
        for (var x = 0; x < rowsUsers.length; x++) {
            var idUser = rowsUsers[x].idUser;
            var balance = rowsUsers[x].amount;
            var session = rowsUsers[x].session;

            var percentage = parseFloat(balance / grandtotal);
            var credit = parseFloat((stakeAmount) * percentage);
            if(credit > 0.002) credit -= 0.002
            // var percentage = parseFloat((balance / grandtotal).toFixed(2));
            // var credit = parseFloat(Math.abs(stakeAmount * percentage - 0.002)).toFixed(3);
            checkCredit += parseFloat(credit);

            // console.log("Inserting stake: uid:" + idUser + " credit:" + credit);
            await con.query('INSERT INTO payouts_stake(idUser, txid, session, amount, datetime) VALUES (?, ?, ?, ?,?)', [idUser, txid, session, credit, dateTime]);
          
        }
        await con.query("UPDATE transaction_stake SET credited = ? WHERE id = ?", [1, idTx]);
        // console.log("==Total credit: "+ parseFloat(checkCredit) + "==");
        console.log("///////////================///////////");
    }
    await cleanupDuplicities();
}

async function cleanupDuplicities() {
    var [r, f] = await con.query('SELECT txid, COUNT(idUser) as type FROM payouts_stake WHERE 1 GROUP BY txid, idUser');
    for (var i = 0; i < r.length; i++) {
        if (r[i].type == 2) {
            console.log("duplicate " + r[i].txid);
            await con.query('DELETE FROM payouts_stake WHERE txid = ? LIMIT 1', [r[i].txid]);
        }
    }
}