const CampusAsync = require('./lib/campus-async.js');
const mysql = require('mysql2/promise');
var gcm = require('node-gcm');
require('dotenv').config();

const rpc = new CampusAsync(process.env.ENC_CRYPTO);
const fireSender = new gcm.Sender(process.env.ENC_FIRE);

var con = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_SELECT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// console.log(process.argv[2]);
run();
async function run() {
  setTimeout(runNotify, 500);
}

async function runNotify() {  
  await saveTransactions();
  console.log("saving transactions");
  await notify();
  console.log("notifying");
}



async function saveTransactions() {
  var json;
  try {
    const res = await rpc.run('listtransactions', ["*", 5]);
    var k = JSON.stringify(res);
    json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
    // console.log(json);
    await insertTransactions(json);
  } catch (error) {
    console.log(error);
  }
}


async function insertTransactions(js) {
  for (let key of js.result) {
    var account = key.account;
    var txid = key.txid;
    var amount = key.amount;
    var confirmation = key.confirmations;
    if(parseInt(confirmation) < 0) continue;
    var address = key.address;
    var cat = key.category;
    if(cat === 'immature' || cat === 'generate') continue;
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
          await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat], function (err, result) {
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
          await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat], function (err, result) {
          }).catch((e) => {
            console.log(e);
          });
        }
      }
    } else {
      await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND category = ?', [confirmation, txid, cat]);
    }
  }
  await cleanupDuplicities();
}

function isEmptyStr(str) {
  return (!str || 0 === str.length);
}

async function cleanupDuplicities() {
  var [r, f] = await con.query('SELECT txid, COUNT(category) as type FROM  transaction WHERE 1 GROUP BY txid, category');
  for (var i = 0; i < r.length; i++) {
    if (r[i].type == 2) {
      console.log("duplicate " + r[i].txid);
      await con.query('DELETE FROM transaction WHERE txid = ? LIMIT 1', [r[i].txid]);
    }
  }
}

async function notify() {
  var registrationReceiveTokens = [];
  var registrationSendTokens = [];

  var [x, z] = await con.query(" SELECT amount, account FROM transaction WHERE notified = 0 AND category = 'receive' ");
  console.log(x.length);
  console.log(x);
  for (var i = 0; i < x.length; i++) {
    var message = new gcm.Message({
      priority: 'high',
      contentAvailable: true,
      notification: {
        body: "You've received " + x[i].amount + " XDN",
        title: "Incoming transaction",
        icon: "@drawable/ic_notification",
        sound: "default",
        android_channel_id: "xdn1",
        badge: "1"
      },
      data: {
        transaction: 'in',
      },
    });
    var [k, l] = await con.query("SELECT devices.token FROM devices, users WHERE users.username = ? AND users.id = devices.idUser GROUP BY devices.token", x[i].account);
    console.log(k);
    for (var i = 0; i < k.length; i++) {
      registrationReceiveTokens.push(k[i].token);
    }
    console.log(registrationReceiveTokens.length);

    fireSender.send(message, { registrationTokens: registrationReceiveTokens }, function (err, response) {
      if (err) console.error(err);
    });
  }

  var [f, g] = await con.query("SELECT amount, account FROM transaction WHERE notified = 0 AND category = 'send' ");

  console.log(f.length);
  for (var i = 0; i < f.length; i++) {
    var message = new gcm.Message({
      priority: 'high',
      contentAvailable: true,
      notification: {
        body: "You've sent " + Math.abs(f[i].amount) + " XDN",
        title: "Coins sent",
        icon: "@drawable/ic_notification",
        sound: "default",
        android_channel_id: "xdn1",
        badge: "1"
      },
      data: {
        transaction: 'out',
      },
    });
    var [r, t] = await con.query("SELECT devices.token FROM devices, users WHERE users.username = ? AND users.id = devices.idUser", f[i].account);

    for (var i = 0; i < r.length; i++) {
      registrationSendTokens.push(r[i].token);
    }
    console.log(registrationReceiveTokens.length);
    
    fireSender.send(message, { registrationTokens: registrationSendTokens }, function (err, response) {
      if (err) console.error(err);
    });
  }




  // var [a, b] = await con.query("SELECT token FROM  devices WHERE idUser IN (SELECT  users.id FROM  transaction,  users WHERE  transaction.notified = 0 AND  transaction.category = 'receive' AND  transaction.account =  users.username GROUP BY  users.id)");
  // for (var i = 0; i < a.length; i++) {
  //   registrationTokens.push(a[i].token);
  // }n

  // fireSender.send(message, { registrationTokens: registrationTokens }, function (err, response) {
  //   if (err) console.error(err);
  //   else console.log(response);
  // });

  var [c, d] = await con.query('UPDATE transaction SET notified = 1 WHERE id <> 0');


  con.end();
}