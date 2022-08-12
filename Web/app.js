const CampusAsync = require('./lib/campus-async.js');
var authenticator = require('authenticator');
const mysql = require('mysql2/promise');
var express = require('express');
var jwt = require('jsonwebtoken');
var crypto = require('crypto');
var CryptoJS = require("crypto-js");
const nodemailer = require("nodemailer");
require('dotenv').config();
const bodyParser = require('body-parser');
const https = require('axios')
var gcm = require('node-gcm');
const fs = require('fs');
var http = require('http');
const moment = require('moment-timezone');
const Json2csvParser = require('json2csv').Parser;

const rpc = new CampusAsync(process.env.ENC_CRYPTO);
const rpcStake = new CampusAsync(process.env.ENC_CRYPTO_STAKE);
const fireSender = new gcm.Sender(process.env.ENC_FIRE);
const cryptoOptions = { mode: CryptoJS.mode.CBC, padding: CryptoJS.pad.Pkcs7 };
const KEY = process.env.ENC_JSON;
var app = express();
var priceData = {}

const jwt_decode = require('jwt-decode');

async function run() {
  //get price
  price()
  setInterval(price, 1800000);
}

async function unlock() {
  await sleep(60000);
  await rpcStake.run('walletlock', []);
  var r = await rpcStake.run('walletpassphrase', [process.env.ENC_STAKE_PASS, 99999999, true]);
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

unlock();
run();

require('dotenv').config();

var con = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_SELECT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: 'gmt',
});




app.post('/signup', async function (req, res) {
  console.log("registering");
  var payload;
  try { //some "magic" for library error
    payload = CryptoJS.AES.decrypt(req.headers.payload, process.env.ENC_PASS, cryptoOptions).toString(CryptoJS.enc.Utf8);
  } catch (e) {
    console.error("Failure / Signup");
    res.statusCode = 401;
    res.setHeader("Content-Type", "text/html");
    res.send("Bad Request");
    res.end();
    return;
  }
  console.log(payload);
  const jsonResponse = JSON.parse(payload);
  let username = jsonResponse.username;
  var passUser = jsonResponse.password;
  var email = jsonResponse.email;
  var realname = jsonResponse.realname;
  var udid = jsonResponse.udid;
  var password = crypto.createHash('sha256').update(passUser).digest('hex');
  try {
    var [rows, fields] = await con.query("SELECT * FROM users WHERE username = ? OR email= ?", [username, email]);
    console.log("Result: " + rows[0]);
    if (rows[0] != null) {
      console.error("can't create user " + username);
      res.status(409);
      res.send("An user with that username already exists");
    } else {
      const daemonRPC = await rpc.run('getnewaddress', [username]);
      if (daemonRPC.result[0] == null) {
        console.error("Failure / get new addr");
        res.statusCode = 410;
        res.setHeader("Content-Type", "text/html");
        res.send(CryptoJS.AES.encrypt("Server internal error", process.env.ENC_PASS).toString());
        res.end();
        throw "Daemon is not giving addr";
      } else {
        var newAddr = daemonRPC.result.toString();
        // console.log(wnd);
        var [rows2, fields2] = await con.query('INSERT INTO users(username, password, email, addr, nickname, realname, UDID) VALUES (?, ?, ?, ?, ?, ?, ?)', [username, password, email, newAddr, username, realname, udid]);
        if (rows2 != null) {
          res.status(201);
          res.send("Success");
        }
      }
    }
  } catch (e) {
    console.log(e);
    res.send(400);
  }

});

app.post('/login', async function (req, res) {
  var payload;
  try { //some "magic" for library error
    payload = CryptoJS.AES.decrypt(req.headers.payload, process.env.ENC_PASS, cryptoOptions).toString(CryptoJS.enc.Utf8);
  } catch (e) { }
  try {
    const jsonResponse = JSON.parse(payload);
    let userName = jsonResponse.username;
    let passUser = jsonResponse.password;
    let twoFactor = jsonResponse.twoFactor;

    console.log(userName + " attempted login");

    var password = crypto.createHash('sha256').update(passUser).digest('hex');
    var [rows, fields] = await con.query("SELECT * FROM users WHERE (username, password) = (?, ?) OR (email, password) = (?, ?)", [userName, password, userName, password]);
    if (rows[0].twoActive == true || rows[0].twoActive == 1) {
      console.log("2 FACTOR");
      if (twoFactor == null) {
        res.statusCode = 409;
        res.setHeader("Content-Type", "text/html");
        res.send("2FA required");
        res.end();

      } else {
        var t = await twoFactorValidate(rows[0].id, twoFactor);
        console.log(t);
        if (t !== "err") {
          if (rows[0] !== undefined) {
            var payload = {
              username: userName,
            }

            var token = jwt.sign(payload, KEY, { algorithm: 'HS256', expiresIn: "365d" });

            var add = {
              userid: rows[0].id,
              username: rows[0].username,
              nickname: rows[0].nickname,
              addr: rows[0].addr,
              admin: rows[0].admin,
              jwt: token,
            }


            console.log("Success");
            var json = JSON.stringify(add);
            res.statusCode = 200;
            res.setHeader("Content-Type", "text/html");
            var ciphertext = CryptoJS.AES.encrypt(json, process.env.ENC_PASS).toString();
            res.write(ciphertext);
            res.end();

          } else {
            res.statusCode = 401;
            res.setHeader("Content-Type", "text/html");
            res.send("No such user registered");
            res.end();

          }
        } else {
          res.statusCode = 401;
          res.setHeader("Content-Type", "text/html");
          res.send("No such user registered");
          res.end();

        }
      }
    } else {
      if (rows[0] !== undefined) {
        var payload = {
          username: userName,
        }

        var token = jwt.sign(payload, KEY, { algorithm: 'HS256', expiresIn: "365d" });

        var add = {
          userid: rows[0].id,
          username: rows[0].username,
          nickname: rows[0].nickname,
          addr: rows[0].addr,
          admin: rows[0].admin,
          jwt: token,
        }


        console.log("Success");
        let json = JSON.stringify(add);
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        let ciphertext = CryptoJS.AES.encrypt(json, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();


      } else {
        res.statusCode = 401;
        res.setHeader("Content-Type", "text/html");
        res.send("No such user registered");
        res.end();

      }

    }
  } catch (e) {
    console.error(e);
    console.error("Failure / login");
    res.statusCode = 401;
    res.setHeader("Content-Type", "text/html");
    res.send("Bad Request");
    res.end();

  }
});

app.get('/getinfo', async (req, res) => {
  console.log('shit');
  var t = await getInfo();
  if (t === "err") {
    res.statusCode = 400;
    res.setHeader("Content-Type", "text/html");
    var err = { "status": "ko" }
    var ciphertext = JSON.stringify(err);
    res.write(ciphertext);
    res.end();

  } else {
    res.statusCode = 200;
    res.setHeader("Content-Type", "text/html");
    res.write(t);
    res.end();

  }
});



app.post('/forgotPass', async function (req, res) {
  console.log("--------Forgot Pass--------");
  let passNew = Math.random().toString(36).substring(7);
  var pass = crypto.createHash('sha256').update(passNew).digest('hex');
  var [rr, f] = await con.query("SELECT * FROM users WHERE email = ?", [req.headers.username]);
  if (rr[0] != null) {
    await con.query("UPDATE users SET password = ? WHERE id = ?", [pass, rr[0].id]);
    await emailSend(passNew, rr[0].email)
    console.log("Success");
    res.status(200)
    res.send("ok");
  } else {
    console.error("Failure");
    res.status(401)
    res.send("There's no user matching that");
  }

});

app.use(bodyParser.urlencoded({ limit: "50mb", extended: true, parameterLimit: 50000 }));

app.post('/apiAvatar', async function (req, res) {
  var payload;
  try { //some "magic" for library error
    payload = CryptoJS.AES.decrypt(req.body.payload, process.env.ENC_PASS, cryptoOptions).toString(CryptoJS.enc.Utf8);
  } catch (e) {
    console.error("Failure / Avatar API");
    res.statusCode = 401;
    res.setHeader("Content-Type", "text/html");
    res.send("Bad Request");
    res.end();
    return;
  }
  const jsonResponse = JSON.parse(payload);
  var str = req.headers.authorization;
  console.log(str)
  var param1 = jsonResponse.param1;
  var param2 = jsonResponse.param2;
  var id = jsonResponse.id;

  try {
    jwt.verify(str, KEY, { algorithm: 'HS256' });
  } catch {
    res.status(401);
    res.send("Bad Token");
    return;
  }

  if (param2 === "upload") {
    var [rr, f] = await con.query("SELECT avatar FROM users WHERE id = ?", [id]);
    if (rr[0].avatar != null) {
      let filename = rr[0].avatar;
      fs.writeFile(__dirname + "/avatars/" + filename + ".xdf", param1, function (err) {
        if (err) {
          console.error("Failure");
          res.status(401);
          res.send("There is some problem");

        }
      });
      await con.query("UPDATE users SET av = av + 1 WHERE id = ?", [id]);
      console.log("Success");
      res.status(200);
      res.send("ok");

    } else {
      let filename = Math.random().toString(36).substring(3);
      fs.writeFile(__dirname + "/avatars/" + filename + ".xdf", param1, function (err) {
        if (err) {
          console.error("Failure");
          res.status(401);
          res.send("There is some problem");

        }
      });
      await con.query("UPDATE users SET avatar = ? WHERE id = ?", [filename, id]);
      await con.query("UPDATE users SET av = av + 1 WHERE id = ?", [id]);
      console.log("Success");
      res.status(200);
      res.send("ok");

    }
  } else {
    var ID;
    var r
    if (param1 === 0) {
      ID = id;
    } else {
      ID = param1;
    }
    if (ID.length > 10) {
      r = await con.query("SELECT avatar FROM users WHERE addr = ?", [ID]);
    } else {
      r = await con.query("SELECT avatar FROM users WHERE id = ?", [ID]);
    }
    console.log(r.length);
    if (r == null) {
      res.status(200);
      res.send("ok");

    } else if (r[0][0].avatar == null) {
      res.status(200);
      res.send("ok");

    } else {
      filename = r[0][0].avatar;
      console.log(filename);
      fs.readFile(__dirname + "/avatars/" + filename + ".xdf", "utf8", function (err, data) {
        if (err) {
          console.log(err);
          console.error("Failure");
          res.status(401);
          res.send("There is some problem with AVATARS");
          return;
        }
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        res.write(data);
        res.end();

      });
    }
  }

});

app.get('/data', async (req, res) => {
  var payload;
  try { //some "magic" for library error
    payload = CryptoJS.AES.decrypt(req.headers.payload, process.env.ENC_PASS, cryptoOptions).toString(CryptoJS.enc.Utf8);
  } catch (e) {
    console.error("Failure / Data");
    res.statusCode = 401;
    res.setHeader("Content-Type", "text/html");
    res.send("Bad Request");
    res.end();
    return;
  }
  console.log(payload);
  const jsonResponse = JSON.parse(payload);
  var str = req.headers.authorization;
  // console.log(jsonResponse)
  var rrr = jsonResponse.request;
  var param1 = jsonResponse.param1;
  var param2 = jsonResponse.param2;
  var param3 = jsonResponse.param3;
  var user = jsonResponse.User;
  var id = jsonResponse.id;

  try {
    jwt.verify(str, KEY, { algorithm: 'HS256' });
  } catch {
    res.status(401);
    res.send("Bad Token");
    return;
  }

  if (rrr === null) {
    res.statusCode = 400;
    res.setHeader("Content-Type", "text/html");
    let err = { "status": "ko" }
    let ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
    res.write(ciphertext);
    res.end();
    return;
  }

  try {
    if (rrr === "getBalance") {
      await saveTransactions();
      await cleanupDuplicities();
      var bal = await getBalanceUser(user);
      var balImature = await getBalanceImmature(user);
      var balSpendable = await getBalanceSpendable(user);
      var add = {
        balance: bal,
        immature: balImature,
        spendable: balSpendable
      }
      let ciphertext;
      if (param1 === 1) {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        ciphertext = CryptoJS.AES.encrypt(JSON.stringify(add), process.env.ENC_PASS).toString();
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        ciphertext = CryptoJS.AES.encrypt(bal.toString(), process.env.ENC_PASS).toString();
      }
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "getTransaction") {
      await saveTransactions();
      let trans = await getTransaction(user.toLocaleLowerCase(), param1);
      let ciphertext = CryptoJS.AES.encrypt(trans, process.env.ENC_PASS).toString();
      // console.log(trans);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "sendTransaction") {
      var t = await sendTransaction(user, param1, param2);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "sendRawTransaction") {
      var t = await sendRawTransaction(user, param1, param2);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "sendContactTransaction") {
      var t = await sendContactTransaction(user, id, param1, param2, param3);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "saveAdrrBook") {
      var addRes = await saveAddrBook(id, param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      res.write(addRes);
      res.end();
      return;
    }

    if (rrr === "getAddrBook") {
      var t = await getAddrBook(id);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "deleteContact") {
      await deleteContact(id, param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var err = { "status": "ok" }
      var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "searchUsers") {
      var t = await searchUsers(param1);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      res.write(t);
      res.end();
      return;
    }


    if (rrr === "renameUser") {
      var t = await renameUser(id, param1);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "getAdminNickname") {
      var t = await getAdminNickname(id);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }
    if (rrr === "changeStatus") {
      var t = await changeStatus(id, param1);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "registerFirebaseToken") {
      await saveFirebaseToken(id, param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var err = { "status": "ok" }
      var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "getMessageGroup") {
      var t = await getMessageGroup(param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "getMessages") {
      var t = await getMessages(param1, param2, param3, id);
      console.log(t);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "updateRead") {
      await updateRead(param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var err = { "status": "ok" }
      var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "updateLikes") {
      var t = await updateLikes(id, param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "sendMessage") {
      var t = await sendMessage(param1, param2, param3, id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "updateContact") {
      await updateContact(param1, param2);
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/html");
      var err = { "status": "ok" }
      var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
      res.write(ciphertext);
      res.end();
      return;
    }

    if (rrr === "changePassword") {
      var t = await changePassword(id, param1)
      console.log(t);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "avatarVersion") {
      var t = await getAvatarVersion(param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "setStake") { //id, amount, user
      var t = await setStake(id, param1, user);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else if (t === "bal") {
        res.statusCode = 406;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "unstake") {
      var t = await unstake(id, param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else if (t === 'time') {
        res.statusCode = 406;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "stakeAmount") {
      var t = await stakeAmount(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "stakeAmountReward") {
      var t = await stakeAmountReward(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "stakeAmountLocked") {
      var t = await stakeAmountLocked(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }



    if (rrr === "getRewards") {
      var t;
      if (param2 === 0) {
        t = await getRewardsPerDay(id, param1, param3);
      } else if (param2 === 1) {
        t = await getRewardsPerMonth(id, param1, param3);
      }

      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }


    if (rrr === "estimatedReward") {
      var t = await getEstimatedRewards(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "getPoolStats") {
      var t = await getStakeStats(id)
      console.log(t);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "getcsv") {
      console.log(user);
      var t = await getCSV(user);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
      else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "getPrivKey") {
      var t = await getPrivKey(param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
      else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "twofactor") {
      var t = await twoFactor(id);
      if (t === "err") {
        res.statusCode = 401;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else if (t === "err1") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "twofactorValidate") {
      var t = await twoFactorValidate(id, param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "twofactorRemove") {
      var t = await twoFactorRemove(id, param1);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "twofactorCheck") {
      var t = await twoFactorCheck(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t.toString(), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "priceData") {
      var t = await twoFactorCheck(id);
      if (priceData === null || priceData === undefined) {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(priceData), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "getDaemonStatus") {
      var t = await getDaemonStatus();
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
        return;
      }
    }

    if (rrr === "getInfo") {
      var t = await getInfo();
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();

      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var ciphertext = CryptoJS.AES.encrypt(t, process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();

      }
    }

    if (rrr === "deleteAccount") {
      console.log("DELETE ACC")
      var t = await deleteAccount(id);
      if (t === "err") {
        res.statusCode = 400;
        res.setHeader("Content-Type", "text/html");
        var err = { "status": "ko" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(err), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
      } else {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        var resP = { "status": "ok" }
        var ciphertext = CryptoJS.AES.encrypt(JSON.stringify(resP), process.env.ENC_PASS).toString();
        res.write(ciphertext);
        res.end();
      }
    }

  } catch (e) {
    console.log(e);
    res.status(401);
    res.send("err");
  }

});

async function getDaemonStatus() {
  let walletblk = false;
  let walletblkStake = false;
  let stakingActive = false;
  let blk = await getBlockheighReq();
  if (blk !== "err") {
    let res = await rpc.run('getblockcount');
    let k = JSON.stringify(res);
    let json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
    let localBlock = json.result
    let resStake = await rpcStake.run('getblockcount');
    let kk = JSON.stringify(resStake);
    let jsonStake = JSON.parse(kk.toString('utf8').replace(/^\uFFFD/, ''));
    let localBlockStake = jsonStake.result
    if (localBlock === blk) {
      walletblk = true;
    } else {
      walletblk = false;
    }
    if (localBlock === localBlockStake) {
      walletblkStake = true;
    } else {
      walletblkStake = false;
    }

    resStake = await rpcStake.run('getstakinginfo');
    kk = JSON.stringify(resStake);
    jsonStake = JSON.parse(kk.toString('utf8').replace(/^\uFFFD/, ''));
    stakingActive = jsonStake.result.staking;

    var resp = {
      "block": walletblk,
      "blockStake": walletblkStake,
      "stakingActive": stakingActive,
    }
    return JSON.stringify(resp);
  } else {
    return "err";
  }
}

async function getInfo() {
  try {
    var daemonRPC = await rpcStake.run('getinfo');
    var kk = JSON.stringify(daemonRPC);
    var jsonGetInfo = JSON.parse(kk.toString('utf8').replace(/^\uFFFD/, ''));
    return JSON.stringify(jsonGetInfo.result);
  } catch (e) {
    return err;
  }
}

async function getBlockheighReq() {
  let blockheight = 0;

  await https.get('https://xdn-explorer.com/api/getblockcount')
    .then(response => {
      blockheight = parseInt(response.data);
    })
    .catch(error => {
      blockheight = "err"
    });
  return blockheight;
}

async function price() {
  var p = await https.get('https://api.coingecko.com/api/v3/coins/digitalnote?tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false');
  priceData = p.data.market_data.current_price;
  console.log(priceData);
}


async function twoFactor(id) {
  try {
    var [rows, fields] = await con.query("SELECT twoActive FROM users WHERE id = ?", [id])
    if (rows[0].twoActive == true || rows[0].twoActive == 1) {
      return "err1";
    }
    var secret = authenticator.generateKey();
    var formatted = secret.replace(/\W/g, '').toLowerCase()
    await con.query("UPDATE users SET twoKey = ? WHERE id = ?", [formatted, id]);
    var res = {
      "secret": formatted
    }
    return JSON.stringify(res)
  } catch (e) {
    console.log(e)
    return "err"
  }
}

async function twoFactorValidate(id, token) {
  try {
    var [rows, fields] = await con.query("SELECT twoKey FROM users WHERE id = ?", [id])
    var key = rows[0].twoKey;
    console.log(key);
    let tk = token.toString();
    let valid = authenticator.verifyToken(key, tk);
    console.log(valid)
    if (valid !== null) {
      if (valid.delta == 0) {
        await con.query("UPDATE users SET twoActive = 1 WHERE id = ?", [id])
        var res = {
          "status": "ok"
        }
        return JSON.stringify(res)
      }
    }
    return "err"
  } catch (e) {
    // console.log(e);
    return "err"
  }
}

async function twoFactorCheck(id) {
  try {
    var [rows, fields] = await con.query("SELECT twoActive FROM users WHERE id = ?", [id])
    var key = rows[0].twoActive;
    var obj = {
      "twoFactor": key
    }
    return JSON.stringify(obj);
  } catch (e) {
    // console.log(e);
    return "err"
  }
}

async function twoFactorRemove(id, token) {
  try {
    var [rows, fields] = await con.query("SELECT twoKey FROM users WHERE id = ?", [id])
    var key = rows[0].twoKey;
    let tk = token.toString();
    let valid = authenticator.verifyToken(key, tk);

    if (valid !== null) {
      if (valid.delta == 0) {
        await con.query("UPDATE users SET twoActive = 0 WHERE id = ?", [id])
        await con.query("UPDATE users SET twoKey = NULL WHERE id = ?", [id])
        var res = {
          "status": "ok"
        }
        return JSON.stringify(res)
      }
    }
    return "err"
  } catch (e) {
    // console.log(e);
    return "err"
  }
}

async function getCSV(user) {
  let csv;
  console.log(user);
  var r = await con.query("SELECT txid, amount, category, address, date FROM transaction WHERE account = ?", [user])
  const jsonCustomers = JSON.parse(JSON.stringify(r[0]));
  const fields = ['txid', 'amount', 'category', 'address', 'date'];

  try {
    const json2csvParser = new Json2csvParser({ fields });
    csv = json2csvParser.parse(jsonCustomers);
  } catch (err) {
    console.log(err);
    return "err";
  }
  // console.log(csv)
  let base64data = Buffer.from(csv.toString()).toString('base64')
  return base64data;
}

let port = process.env.PORT || 3000;
app.listen(port, function () {
  return console.log("Started user authentication server listening on port " + port);
});

async function saveTransactions() {
  var json;
  try {
    const res = await rpc.run('listtransactions', ["*", 10]);
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
    if (parseInt(confirmation) < 0) continue;
    var address = key.address;
    var cat = key.category;
    if (cat === 'immature' || cat === 'generate') continue;
    var timed = new Date(Number(key.time + "000"));
    var time = timed.toISOString().slice(0, 19).replace('T', ' ');



    var [rows, fields] = await con.query('SELECT * FROM transaction WHERE txid = ?', [txid]);
    if (rows[0] != null) {
      await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? ', [confirmation, txid], function (err, result) {
      }).catch((e) => {
        console.log(e);
      });
    } else {
      console.log(txid, cat, account, address, amount);
      if (account == "") {
        var [name, fields] = await con.query('SELECT username FROM users WHERE addr = ?', [address]);
        account = name[0].username;
      }
      await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category, date) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat, time], function (err, result) {
      }).catch((e) => {
        console.log(e);
      });
    }
    // if (!isEmptyStr(account)) {

    //   var [rows, fields] = await con.query('SELECT * FROM transaction WHERE txid = ? AND category = ? AND account = ? AND address = ?', [txid,cat, account, address]);
    //   if (rows[0] != null) {
    //     await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND account = ? AND address = ? ', [confirmation, txid, account, address], function (err, result) {
    //     }).catch((e) => {
    //       console.log(e);
    //     });
    //   } else {
    //     await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category, date) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat, time], function (err, result) {
    //     }).catch((e) => {
    //       console.log(e);
    //     });
    //   }

    // } else {
    //   var [rows, fields] = await con.query('SELECT * FROM transaction WHERE txid = ? AND category = ? AND account = ? AND address = ?', [txid, cat, "", address]);
    //   if (rows[0] != null) {
    //     await con.query('UPDATE transaction SET confirmation = ? WHERE txid = ? AND category = ? AND address = ?', [confirmation, txid, cat, address], function (err, result) {
    //     }).catch((e) => {
    //       console.log(e);
    //     });
    //   } else {
    //     await con.query('INSERT INTO transaction(txid, account, amount, confirmation, address, category, date) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, account, amount, confirmation, address, cat, time], function (err, result) {
    //     }).catch((e) => {
    //       console.log(e);
    //     });
    //   }
    // }

  }

}

async function getTransaction(user, timezone) {
  let myArray = [];
  if (timezone === null) timezone = 'GMT';
  try {
    var [r, f] = await con.query("SELECT * FROM transaction WHERE account = ? ORDER BY id DESC", [user]);
    if (r != null) {
      for (var i = 0; i < r.length; i++) {
        var d = await getMessagesTime(r[i].date)
        var date = await dateTimeConvertZone(d, timezone);
        var add = {
          id: r[i].id,
          txid: r[i].txid,
          category: r[i].category,
          date: date,
          amount: r[i].amount,
          confirmation: r[i].confirmation,
          contactName: r[i].contactName,
        }
        myArray.push(add);
      }
    }

    return JSON.stringify(myArray);
  } catch (e) {
  }
}

async function getBalanceImmature(user) {
  var bal = 0;
  try {
    var [rows, fields] = await con.query("SELECT SUM(amount) as immature FROM transaction WHERE account = ? AND confirmation < 5 AND category = 'receive' ", [user]);
    bal += Math.abs(rows[0].immature);
    return bal.toFixed(3);
  } catch (error) {
    console.log("BALANCE: " + error);
    return "err";
  }
}

async function getBalanceUser(user) {
  var bal = 0;
  // var res = await rpc.run('listaccounts', []);
  // return res.result[user].toFixed(3);
  // console.log(res[0][user]);
  try {
    var [rows, fields] = await con.query("SELECT amount, category FROM transaction WHERE account = ? AND confirmation > 5 AND category = 'receive' UNION ALL SELECT amount, category FROM  transaction WHERE account = ? AND category = 'send' ", [user, user]);
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].category === "receive") {
        bal += Math.abs(rows[i].amount);
      } else {
        bal -= Math.abs(rows[i].amount);
      }
    }
    console.log(bal + " " + user);
    return bal.toFixed(3);
  } catch (error) {
    console.log("BALANCE: " + error);
    return "err";
  }
}

async function getBalanceSpendable(user) {
  var bal = 0;
  // var res = await rpc.run('listaccounts', []);
  // return res.result[user].toFixed(3);
  // console.log(res[0][user]);
  try {
    var [rows, fields] = await con.query("SELECT addr FROM users WHERE username = ?", [user]);
    if (rows[0] != null) {
      let address = rows[0].addr
      let res = await rpc.run('listunspent', [1, 99999999, [address]]);
      let k = JSON.stringify(res);
      let json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      for (let key of json.result) {
        if (key.spendable == true) {
          bal += key.amount;
        }
      }
      return bal.toFixed(3);
    } else {
      return "err";
    }
  } catch (error) {
    console.log("BALANCE: " + error);
    return "err";
  }
}

async function sendTransaction(user, address, amount) {
  let userBalance = await getBalanceUser(user);
  if (userBalance === "err") {
    let add = {
      error: "Can't get balance",
    }
    return add;
  }
  var [rows, fields] = await con.query("SELECT addr FROM users WHERE username = ?", [user]);
  if (rows[0] == null) {
    let add = {
      error: "User not found",
    }
    console.log(add)
    return add;
  }

  if (parseFloat(amount) < parseFloat(userBalance)) {
    try {
      let addrUser = rows[0].addr;
      console.log("---------SEND TRANSACTION---------")
      console.log(user + " " + address + " " + amount);
      console.log("----------------------------------")
      // const res = await rpc.run('sendtoaddress', [address.toString(), parseFloat(amount)]);
      await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
      let res = await doSendRequest(addrUser, address, parseFloat(amount));
      await rpc.run('walletlock', []);
      var k = JSON.stringify(res);
      var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      if (json.error != null) {
        console.log(json.error);
        return "err";
      }
      console.log(json.tx);
      // await saveTransactions();
      // await con.query('UPDATE transaction SET account = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1', [user, res.tx, 'send']);
      // var k = JSON.stringify(res);
      // var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      // return json;
    } catch (e) {
      console.log(e);
      return 'err';
    }
  } else {
    var add = {
      error: "Not enough balance",
    }
    return add;
  }
}

async function sendRawTransaction(user, address, amount) {
  let userBalance = await getBalanceUser(user);
  if (userBalance === "err") {
    let add = {
      error: "Can't get balance",
    }
    return add;
  }
  var [rows, fields] = await con.query("SELECT addr FROM users WHERE username = ?", [user]);
  if (rows[0] == null) {
    let add = {
      error: "User not found",
    }
    console.log(add)
    return add;
  }
  console.log(rows[0].addr);
  console.log(parseFloat(userBalance))
  console.log(parseFloat(amount))
  if (parseFloat(amount) < parseFloat(userBalance)) {
    try {
      let addrUser = rows[0].addr;
      console.log("---------SEND TRANSACTION---------")
      console.log(user + " " + address + " " + amount);
      console.log("----------------------------------")

      // const res = await rpc.run('sendtoaddress', [address.toString(), parseFloat(amount)]);
      await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
      // var res = await rpc.run('sendfrom', [user.toString(), address.toString(), parseFloat(amount)]);
      let res = await doSendRequest(addrUser, address, parseFloat(amount));
      await rpc.run('walletlock', []);
      var k = JSON.stringify(res);
      var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      if (json.error != null) {
        console.log(json.error);
        return "err";
      }
      console.log(json.tx);
      // await saveTransactions();
      // await con.query('UPDATE transaction SET account = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1', [user, res.tx, 'send']);

    } catch (e) {
      console.log(e);
      return 'err';
    }
  } else {
    var add = {
      error: "Not enough balance",
    }
    return add;
  }
}

async function sendContactTransaction(user, idUser, address, amount, contactName) {
  console.log("send transaction");
  var userBalance = await getBalanceUser(user);
  if (userBalance === "err") {
    var add = {
      error: "Can't get balance",
    }
    return "err";
  }
  var [rows, fields] = await con.query("SELECT addr FROM users WHERE username = ?", [user]);
  if (rows[0] == null) {
    let add = {
      error: "User not found",
    }
    return "err";
  }

  if (parseFloat(amount) < parseFloat(userBalance)) {
    try {
      let addrUser = rows[0].addr;
      console.log("---------SEND CONTACT TRANSACTION---------")
      console.log(user + " " + idUser + " " + address + " " + amount + " " + contactName);
      console.log("------------------------------------------")

      await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
      let res = await doSendRequest(addrUser, address, parseFloat(amount));
      await rpc.run('walletlock', []);
      var k = JSON.stringify(res);
      var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
      if (json.error != null) {
        return "err";
      }
      // await saveTransactions();
      // await con.query('UPDATE transaction SET account = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1', [user, res.tx, 'send']);
      await con.query('UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1', [contactName, json.tx, 'send']);

      return json;
    } catch (e) {
      console.log(e);
      return 'err';
    }
  } else {
    var add = {
      error: "bal",
    }
    return "err";
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

async function getAddrBook(user) {
  try {
    var res = await con.query("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", [user]);
    return JSON.stringify(res[0]);
  } catch (e) {

  }
}

async function deleteContact(id, name, addr) {
  var res = await con.query("DELETE FROM addressbook  WHERE idUser = ? AND name = ? AND addr = ?", [id, name, addr]);
  return 1;
}

async function cleanupDuplicities() {
  var [r, f] = await con.query('SELECT txid, COUNT(category) as type FROM  transaction WHERE 1 GROUP BY txid, category');
  for (var i = 0; i < r.length; i++) {
    if (r[i].type == 2) {
      await con.query('DELETE FROM transaction WHERE txid = ? LIMIT 1', [r[i].txid]);
    }
  }
}

async function emailSend(password, email) {

  try {
    let transporter = nodemailer.createTransport({
      host: process.env.MAIL_SERVER,
      port: 465,
      secure: true, // true for 465, false for other ports
      auth: {
        user: process.env.MAIL_USR,
        pass: process.env.MAIL_PASS
      },
    });

    let info = await transporter.sendMail({
      from: '"DigitalNote robot" <no-reply@digitalnote.org>',
      to: email,
      subject: "Password reset",
      text: "Your new password is: " + password + "\n Don't forget to change it afterwards in settings menu",
      html: "",
    });

    console.log("Message sent: %s", info.messageId);

  } catch (e) {
    console.log(e);
  }
}

async function searchUsers(filter) {
  if (filter == null) {
    filter = "";
  }
  try {
    var res = await con.query("SELECT id, username as name, admin, level, addr, nickname FROM users WHERE username LIKE CONCAT(?,'%') AND admin != 1", [filter]);
    return JSON.stringify(res[0]);
  } catch (e) {
    return e;
  }
}

async function renameUser(id, nickname) {
  try {
    var res = await con.query("UPDATE users SET nickname = ? WHERE id = ?", [nickname, id]);
    var add = {
      nick: nickname,
    }
    return JSON.stringify(add);
  } catch (e) {
    return e;
  }
}

async function getAdminNickname(idee) {
  try {
    var [r, f] = await con.query("SELECT username, nickname, admin, level FROM users WHERE id = ?", [idee]);
    if (r != null) {
      var add = {
        id: idee,
        name: r[0].username,
        nick: r[0].nickname,
        admin: r[0].admin,
        level: r[0].level,
      }
      return JSON.stringify(add);
    } else {
      return "err."
    }
  } catch (e) {
    return e;
  }
}

async function changeStatus(id, value) {
  var val;
  if (value === "true") {
    val = 2;
  } else {
    val = 0;
    try {
      var r = await con.query("UPDATE users SET LEVEL = 0 WHERE id = ?", [id]);
    } catch (e) {
      console.log(e);
    }
  }
  try {
    var res = await con.query("UPDATE users SET admin = ? WHERE id = ?", [val, id]);
    var add = {
      admin: val,
      level: 0,
    }
    return JSON.stringify(add);
  } catch (e) {
    return e;
  }
}

async function changeAmbassadorStatus(id, value) {
  try {
    var res = await con.query("UPDATE users SET level = ? WHERE id = ?", [value, id]);
    var add = {
      admin: value,
    }
    return JSON.stringify(add);
  } catch (e) {
    return e;
  }
}

async function generateAmbassadorCode(id) {
  try {
    var [r, f] = await con.query("SELECT code FROM ambassador_codes WHERE idAmbassador = ? AND addr IS NULL", [id]);
    if (r[0] != null) {
      var add = {
        code: r[0].code,
      }
      return JSON.stringify(add);
    } else {
      const c = crypto.randomBytes(20).toString('hex');
      await con.query("INSERT INTO ambassador_codes(idAmbassador, code) VALUES(?,?)", [id, c]);
      var add = {
        code: c,
      }
      return JSON.stringify(add);
    }
  } catch (e) {
    return e;
  }
}

async function getRecruits(id) {
  try {
    var [r, f] = await con.query("SELECT users.id, users.username, users.addr, users.nickname FROM ambassador_codes, users WHERE ambassador_codes.idAmbassador = ? AND ambassador_codes.username = users.username", [id]);
    console.log(r);
    return JSON.stringify(r);
  } catch (e) {
    return "err";
  }
}

async function saveFirebaseToken(id, token, device) {
  var [f, t] = await con.query("SELECT devices.id FROM devices WHERE token = ?", [token]);
  if (f.length == 0) {
    console.log("token saved");
    try {
      var [rows, fields] = await con.query('INSERT INTO devices(idUser, token, device_type) VALUES (?, ?, ?)', [id, token, device]);
      console.log(rows);
      return JSON.stringify(rows);
    } catch (e) {
      return "err";
    }
  }
}




function Utf8Decode(strUtf) {
  return String(strUtf).replace(
    /[\u00f0-\u00f7][\u0080-\u00bf][\u0080-\u00bf][\u0080-\u00bf]/g,
    function (c) {
      var cc = ((c.charCodeAt(0) & 0x07) << 18) | ((c.charCodeAt(1) & 0x3f) << 12) | ((c.charCodeAt(2) & 0x3f) << 6) | (c.charCodeAt(3) & 0x3f);
      var tmp = cc - 0x10000;
      return String.fromCharCode(0xd800 + (tmp >> 10), 0xdc00 + (tmp & 0x3ff));
    }
  ).replace(
    /[\u00e0-\u00ef][\u0080-\u00bf][\u0080-\u00bf]/g,
    function (c) {
      var cc = ((c.charCodeAt(0) & 0x0f) << 12) | ((c.charCodeAt(1) & 0x3f) << 6) | (c.charCodeAt(2) & 0x3f);
      return String.fromCharCode(cc);
    }
  ).replace(
    /[\u00c0-\u00df][\u0080-\u00bf]/g,
    function (c) {
      var cc = (c.charCodeAt(0) & 0x1f) << 6 | c.charCodeAt(1) & 0x3f;
      return String.fromCharCode(cc);
    }
  );
}


async function getMessageGroup(param1, timezone) {
  let myArray = [];
  if (timezone === null) timezone = 'GMT';
  try {
    var [r, f] = await con.query("SELECT finally.user as receiveAddr, finally.otherParticipant as sentAddr, finally.unread as unread, finally.lastMessage, finally.text FROM (SELECT myMessages.user, myMessages.otherParticipant, groupList.unread, groupList.lastMessage, myMessages.text FROM (SELECT  IF(sentAddr = ?, sentAddr, receiveAddr) as user, IF(receiveAddr = ?, sentAddr, receiveAddr) as otherParticipant, receiveTime,  messages.text,  messages.unread FROM  messages) myMessages INNER JOIN (SELECT otherParticipant, COUNT(IF(myMessages2.unread = 0, 1, NULL)) as unread, max(receiveTime) as lastMessage FROM (SELECT IF(receiveAddr = ?, sentAddr, receiveAddr) as otherParticipant, receiveTime,  messages.unread FROM  messages  WHERE sentAddr = ? or receiveAddr = ?) as myMessages2 GROUP BY otherParticipant) groupList ON myMessages.otherParticipant = groupList.otherParticipant AND myMessages.receiveTime = groupList.lastMessage) as finally", [param1, param1, param1, param1, param1]);
    if (r != null) {
      for (var i = 0; i < r.length; i++) {
        var date = await dateTimeConvertZone(r[i].lastMessage, timezone);
        var add = {
          sentAddr: r[i].sentAddr,
          unread: r[i].unread,
          lastMessage: date,
          text: r[i].text,
          receiveAddr: r[i].receiveAddr,
        }
        myArray.push(add);
      }
    }

    return JSON.stringify(myArray);
  } catch (e) {
    console.log(e);
    return "err";
  }

}

async function getMessagesTime(myTime) {
  var d = new Date(myTime);
  d.setHours(d.getHours()); //CEST TO GMT
  return d;
}

async function getMessages(param1, timezone, param3, lastChange) {
  var dateString;
  if (lastChange == null || lastChange === 0) {
    dateString = lastChange;
  } else {
    dateString = moment.unix(lastChange).tz('GMT').format('YYYY-MM-DD HH:mm:ss');
  }
  console.log(dateString);
  let myArray = [];
  if (timezone === null) timezone = 'GMT';

  try {
    var [r, f] = await con.query("SELECT  id, idReply, likes, lastChange, sentAddr, receiveAddr, unread, lastMessage, text FROM (SELECT id, idReply, (SUM(likeSent) + SUM(likeReceive)) as likes, lastChange, sentAddr, receiveAddr, unread, receiveTime as lastMessage, text FROM messages WHERE receiveAddr = ? AND sentAddr = ? OR receiveAddr = ? AND sentAddr = ? GROUP BY id ORDER BY id) as a WHERE lastChange > ?", [param1, param3, param3, param1, dateString]);
    if (r != null) {
      for (var i = 0; i < r.length; i++) {
        var d = await getMessagesTime(r[i].lastMessage);
        // console.log(d)
        var date = await dateTimeConvertZone(r[i].lastMessage, timezone);
        var add = {
          id: r[i].id,
          idReply: r[i].idReply,
          sentAddr: r[i].sentAddr,
          unread: r[i].unread,
          lastMessage: date,
          text: r[i].text,
          receiveAddr: r[i].receiveAddr,
          likes: parseInt(r[i].likes),
          lastChange: moment(r[i].lastChange, 'YYYY-MM-DD HH:mm:ss').unix(),
        }
        myArray.push(add);
      }
    }
    return JSON.stringify(myArray);
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function updateRead(param1, param2) {
  var [a, b] = await con.query("UPDATE messages SET messages.unread = 1 WHERE (receiveAddr = ? AND sentAddr = ? ) OR (receiveAddr = ? AND sentAddr = ?)", [param1, param2, param2, param1]);
  return "ok";
}

async function updateLikes(id, addr) {
  var r = 0;
  let add = {};
  var [rowDir, x] = await con.query("SELECT id FROM messages WHERE id = ? AND receiveAddr = ? ", [id, addr]);
  if (rowDir[0] === null) {
    console.log("//////SENDER");
    var [rowX, x] = await con.query("SELECT likeSent as lk FROM messages WHERE id = ?", [id]);
    if (parseInt(rowX[0].lk) === 1) {
      await con.query("UPDATE messages SET likeSent = 0 WHERE id = ? ", [id]);
    } else {
      await con.query("UPDATE messages SET likeSent = 1 WHERE id = ? ", [id]);
    }
  } else {
    console.log("//////RECEIVER");
    var [rowY, x] = await con.query("SELECT likeReceive as lk FROM messages WHERE id = ?", [id]);
    if (parseInt(rowY[0].lk) === 1) {
      await con.query("UPDATE messages SET likeReceive = 0 WHERE id = ? ", [id]);
    } else {
      await con.query("UPDATE messages SET likeReceive = 1 WHERE id = ? ", [id]);
    }
  }

  var [rowZ, x] = await con.query("SELECT (SUM(likeSent) + SUM(likeReceive)) as likes FROM messages WHERE id = ?", [id]);
  if (rowZ[0] == null) {
    add = {
      likes: r,
    }
  } else {
    r = parseInt(rowZ[0].likes);
    add = {
      likes: r,
    }
  }
  return JSON.stringify(add);
}

async function updateContact(param1, param2) {
  var [a, b] = await con.query("UPDATE addressbook SET name = ? WHERE id = ? ", [param2, param1]);
  return "ok";
}

async function sendMessage(param1, param2, param3, idReply) { //address from, address to, message
  try {
    let dateNow = new Date().toISOString().slice(0, 19).replace('T', ' ');
    var [r, f] = await con.query('SELECT * FROM messages WHERE sentAddr = ? AND receiveAddr = ? AND sentTime = ?', [param1, param2, dateNow]);

    if (r[0] == null) {
      await con.query('INSERT INTO messages(sentAddr, receiveAddr, sentTime, receiveTime, text, direction, idReply) VALUES (?, ?, ?, ?, ?, ?, ?)', [param1, param2, dateNow, dateNow, param3, "out", idReply]);
    }
    await notify();
    // await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
    // var r = await rpc.run('smsgsend', [param1.toString(), param2.toString(), param3.toString()]);
    // console.log(r);
    // await rpc.run('walletlock', []);
    // saveMessages(idReply);
    return "ok";
  } catch (error) {
    console.log(error);
    return "err.";
  }
}

async function saveMessages(idReply) {
  if (idReply == null) idReply = 0;
  try {
    // const { stdout, stderr } = await exec('./messagesOutbox.sh');
    await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
    const res = await rpc.run('smsgoutbox', ["all"]);
    await rpc.run('walletlock', []);
    var k = JSON.stringify(res);
    var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
    inserMessages(json, idReply);
  } catch (e) {
    console.error(e);
  }
}


async function inserMessages(js, idReply) {
  // console.log(js);
  var json = js["result"];
  for (var i = 0; i < json['messages'].length; i++) {
    var direction = "out";
    var sentAddr = json['messages'][i].from;
    var receiveAddr = json['messages'][i].to;
    var sentTimeDate = new Date(json['messages'][i].sent);
    var sentTime = sentTimeDate.toISOString().slice(0, 19).replace('T', ' ');
    var receiveTimeDate = new Date(json['messages'][i].sent);
    var receiveTime = receiveTimeDate.toISOString().slice(0, 19).replace('T', ' ')
    var text = json['messages'][i].text;
    // console.log(js);
    text = Utf8Decode(decodeURIComponent(escape(text)));
    // console.log(text);
    var [r, f] = await con.query('SELECT * FROM messages WHERE sentAddr = ? AND receiveAddr = ? AND sentTime = ?', [sentAddr, receiveAddr, sentTime]);

    if (r[0] == null) {
      await con.query('INSERT INTO messages(sentAddr, receiveAddr, sentTime, receiveTime, text, direction, idReply) VALUES (?, ?, ?, ?, ?, ?, ?)', [sentAddr, receiveAddr, sentTime, receiveTime, text, direction, idReply]);
    }
  }
  await notify();

}

async function changePassword(id, passUser) {
  try {
    var password = crypto.createHash('sha256').update(passUser).digest('hex');
    await con.query("UPDATE users SET password = ? WHERE id = ? ", [password, id]);
    return "ok";
  } catch (error) {
    return "err.";
  }
}

async function notify() {
  try {
    var registrationReceiveTokens = [];
    var registrationSendTokens = [];

    var [x, z] = await con.query("SELECT receiveAddr FROM messages WHERE notify = 1 GROUP BY receiveAddr");
    for (var i = 0; i < x.length; i++) {
      var message = new gcm.Message({
        priority: 'high',
        contentAvailable: true,
        notification: {
          body: "You have a new message",
          title: "Incoming message",
          icon: "@drawable/ic_notification",
          sound: "default",
          android_channel_id: "konj2",
          badge: "1"
        },
        data: {
          incomingMessage: 'intransaction',
        },
      });
      var [k, l] = await con.query("SELECT devices.token FROM devices, users WHERE users.addr = ? AND users.id = devices.idUser", x[i].receiveAddr);

      for (var i = 0; i < k.length; i++) {
        registrationReceiveTokens.push(k[i].token);
      }

      fireSender.send(message, { registrationTokens: registrationReceiveTokens }, function (err, response) {
        console.log(response);
        if (err) console.error(err);
      });
    }

    var [f, g] = await con.query("SELECT sentAddr FROM  messages WHERE notify = 1 GROUP BY sentAddr");
    for (var i = 0; i < f.length; i++) {
      var message = new gcm.Message({
        priority: 'high',
        contentAvailable: true,
        notification: {
          android_channel_id: "konj2",
        },
        data: {
          outMessage: 'intransaction',
        },
      });
      var [r, t] = await con.query("SELECT devices.token FROM devices, users WHERE users.addr = ? AND users.id = devices.idUser", f[i].sentAddr);

      for (var i = 0; i < r.length; i++) {
        registrationSendTokens.push(r[i].token);
      }

      fireSender.send(message, { registrationTokens: registrationSendTokens }, function (err, response) {
        if (err) {
          console.error(err);
        }
      });
    }

    await con.query('UPDATE messages SET notify = 0 WHERE id <> 0');

  } catch (e) {
    console.log(e);
  }
}

async function getAvatarVersion(addr) {
  var [a, b] = await con.query("SELECT av FROM users WHERE addr = ? ", [addr]);
  try {
    var va = {
      "addr": addr,
      "version": a[0]['av'],
    }
    return JSON.stringify(va);
  } catch (r) {
    var ve = {
      "addr": addr,
      "version": 0,
    }
    return JSON.stringify(ve);
  }
}

async function setStake(id, amount, user) {
  let mySqlTimestamp = await getCurrentDate();
  try {
    var [r, f] = await con.query('SELECT * FROM users_stake WHERE idUser = ? AND active = ?', [id, 1]);
    if (r[0] != null) {
      var [rServer, f] = await con.query('SELECT addr FROM servers_stake WHERE id = ?', [r[0].idServer]);
      var balance = parseFloat(r[0].amount) + parseFloat(amount);
      if (rServer[0].addr != null) {
        if (user == null || rServer[0].addr == null) {
          return "err";
        }

        var resWall = await sendContactTransaction(user, 0, rServer[0].addr, amount, "Staking");

        // console.log("///////////////////////////////");
        // console.log(id + " " + amount + " " + user);
        // console.log(resWall);
        // console.log(resWall.error);
        // console.log(resWall.result);
        // console.log("///////////////////////////////");

        if (resWall !== 'err' && resWall.error == null) {
          console.log("noted");
          await con.query("UPDATE users_stake SET amount = ? WHERE idUser = ? AND active = ?", [balance, id, 1]);
          await con.query("UPDATE users_stake SET dateStart = ? WHERE idUser = ? AND active = ?", [mySqlTimestamp, id, 1]);
          await timeout(2000);
          var objSucc = { "status": "ok" };
          return JSON.stringify(objSucc);
        } else if (resWall.error === "bal") {
          return "bal";
        } else {
          return "err."
        }
      } else {
        return "err";
      }
    } else {
      var [rSession, f] = await con.query('SELECT MAX(session) as smax FROM users_stake WHERE idUser = ?', [id]);
      var [rServer, f] = await con.query('SELECT addr FROM servers_stake WHERE id = ?', [1]);
      if (rServer[0].addr != null) {
        if (user == null || rServer[0].addr == null) {
          return "err";
        }
        var resWall = await sendContactTransaction(user, 0, rServer[0].addr, amount, "Staking");
        // console.log("///////////////////////////////");
        // console.log(id + " " + amount + " " + user);
        // console.log(resWall);
        // console.log(resWall.error);
        // console.log(resWall.result);
        // console.log("///////////////////////////////")

        if (resWall !== 'err' && resWall.error == null) {
          if (rSession[0].smax == null) {
            await con.query('INSERT INTO users_stake(idUser, amount, session, active, dateStart) VALUES (?, ?, ?, ?, ?)', [id, amount, 1, 1, mySqlTimestamp]);
          } else {
            var session = parseInt(rSession[0].smax) + 1;
            await con.query('INSERT INTO users_stake(idUser, amount, session, active, dateStart) VALUES (?, ?, ?, ?, ?)', [id, amount, session, 1, mySqlTimestamp]);
          }
          await timeout(2000);
          var objSucc = { "status": "ok" };
          return JSON.stringify(objSucc);
        } else {
          return "err";
        }
      } else {
        return "err";
      }
    }
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function unstake(id, reward) {
  var timeStamp = await getCurrentDate();
  try {
    var [rAddr, f] = await con.query('SELECT addr FROM users WHERE id = ?', [id]);
    var [r, f] = await con.query('SELECT * FROM users_stake WHERE idUser = ? AND active = ?', [id, 1]);
    if (r[0].idUser != null) {
      var dateStart = r[0].dateStart;
      var date1 = new Date(timeStamp);
      var date2 = new Date(dateStart);
      var diffTime = Math.abs(date2 - date1);
      diffTime = Math.abs(diffTime / 1000);

      if (Number(diffTime) < 86400 && reward === 0) {
        return "time";
      }
      var amount = r[0].amount;
      var [rAmount, f] = await con.query('SELECT SUM(amount) as earned FROM payouts_stake WHERE idUser = ? AND session = ? AND credited = 0', [id, r[0].session]);

      if (rAddr[0].addr != null) {
        if (reward === 1) {
          amount = parseFloat(rAmount[0].earned).toFixed(3);
        } else {
          if (rAmount[0].earned != null) {
            amount = parseFloat(amount + rAmount[0].earned).toFixed(3);
          } else {
            return "err";
          }
        }
        amount = amount - 0.002;
        await rpcStake.run('walletlock', []);
        await rpcStake.run('walletpassphrase', [process.env.ENC_STAKE_PASS, 100]);
        var sendRPC = await rpcStake.run('sendtoaddress', [rAddr[0].addr, Number(amount)]);
        await rpcStake.run('walletlock', []);
        await rpcStake.run('walletpassphrase', [process.env.ENC_STAKE_PASS, 99999999, true]);
        console.log("---------SEND STAKE TRANSACTION---------");
        console.log(id + " " + amount + " " + rAddr[0].addr);
        console.log(sendRPC);
        console.log("---------SEND STAKE TRANSACTION---------");
        if (sendRPC.error !== null) {
          console.log(sendRPC);
          return "err";
        }
        await timeout(2000);
        await saveTransactions();
        await con.query('UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1', ["Staking", sendRPC.result, 'receive']);
        if (reward === 1) {
          await con.query('UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND session = ? AND id <> 0', [1, id, r[0].session]);
        } else {
          await con.query('UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND id <> 0', [1, id]);
          await con.query("UPDATE users_stake SET active = ? WHERE id = ?", [0, r[0].id]);

        }
        return "ok";
      } else {
        return "err";
      }
    } else {
      return "err";
    }
  } catch (e) {
    console.log(e.toString());
    return "err";
  }
}

function timeout(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function stakeAmount(id) {
  try {
    var [r, f] = await con.query('SELECT * FROM users_stake WHERE idUser = ? AND active = ?', [id, 1]);
    if (r[0] != null) {
      var [rr, f] = await con.query('SELECT SUM(amount) as amount FROM payouts_stake WHERE idUser = ? AND session = ? AND credited = 0', [id, r[0].session]);
      var stakes = rr[0].amount;
      var s;
      if (rr[0].amount === null) {
        s = parseFloat(r[0].amount).toFixed(3);
      } else {
        s = parseFloat(r[0].amount + stakes).toFixed(3);
      }
      return s;
    } else {
      return 0;
    }
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function stakeAmountReward(id) {
  try {
    var [r, f] = await con.query('SELECT * FROM users_stake WHERE idUser = ? AND active = ?', [id, 1]);
    if (r[0] != null) {
      var [rr, f] = await con.query('SELECT SUM(amount) as amount FROM payouts_stake WHERE idUser = ? AND session = ? AND credited = 0', [id, r[0].session]);
      if (rr[0].amount === null) return 0;
      var stakes = rr[0].amount;
      var s = parseFloat(stakes).toFixed(3);
      return s;
    } else {
      return 0;
    }
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function stakeAmountLocked(id) {
  try {
    var [r, f] = await con.query('SELECT * FROM users_stake WHERE idUser = ? AND active = ?', [id, 1]);
    if (r[0] != null) {
      var s = parseFloat(r[0].amount).toFixed(3);
      return s;
    } else {
      return 0;
    }
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function getRewardsPerDay(id, date, timezone) {
  var datePhone = date + " " + "00:00:00";
  var timePhone = moment.tz(datePhone, 'YYYY-MM-DD HH:mm:ss', timezone);
  var dayCheck = timePhone.clone().tz(timezone).day();
  var timeDB = timePhone.clone().tz("GMT").utc().format();
  let myArray = [];
  var [rSession, f] = await con.query('SELECT MAX(session) as smax FROM users_stake WHERE idUser = ?', [id]);
  var [r, f] = await con.query("SELECT date(datetime) as date, HOUR(datetime) AS hourly, SUM(amount) AS value FROM payouts_stake WHERE idUser= ? AND session = ? AND datetime >= ? AND credited = 0 GROUP BY hourly, date(datetime)", [id, rSession[0].smax, timeDB]);
  if (r != null) {
    for (var i = 0; i < r.length; i++) {
      var hours;
      if (parseInt(r[i].hourly) < 10 || parseInt(r[i].hourly) == 0) {
        hours = "0" + r[i].hourly.toString();
      } else {
        hours = r[i].hourly.toString();
      }

      var time = date + "T" + hours + ":00:00Z";
      var s = moment.tz(time, 'GMT');
      var finalDate = s.clone().tz(timezone).format('YYYY-MM-DD HH:mm:ss');
      var dayOfTheWeek = s.clone().tz(timezone).day();
      // console.log(finalDate);
      // if (i == 1 || i == r.length - 2) {
      //   dayCheck = dayOfTheWeek;
      // }

      if (dayOfTheWeek != dayCheck && i != 0) {
        hours = 23
        var dt = moment(date, 'YYYY-MM-DD')
        var xxx = dt.subtract(1, "days").format('YYYY-MM-DD');
        time = xxx + "T" + hours + ":00:00Z";
        s = moment.tz(time, 'GMT');
        finalDate = s.clone().tz(timezone).format('YYYY-MM-DD HH:mm:ss');
      }
      // console.log(finalDate);
      // console.log(fn);
      var add = {
        date: finalDate,
        amount: r[i].value,
      }
      myArray.push(add);
    }
    return JSON.stringify(myArray);
  }
}

async function toUTC(date, timezone) {
  // console.log(date + " " + timezone);
  var timePhone = moment.tz(date, 'YYYY-MM-DD HH:mm:ss', timezone);
  return timePhone.clone().tz("GMT").utc().format();
}

async function fromUTC(date, timezone) {
  // console.log(date + " " + timezone);
  var s = moment.tz(date, 'GMT');
  var finalDate = s.clone().tz(timezone).format('YYYY-MM-DD HH:mm:ss');
  return finalDate;
}

async function dateTimeConvertZone(date, timezone) {
  var f;
  if (timezone == null) {
    f = "GMT";
  } else {
    f = timezone;
  }
  // console.log(timezone);
  var a = await toUTC(date, 'GMT');
  // console.log(date);
  return date;
}

async function getRewardsPerMonth(id, year, month) {
  let myArray = [];
  try {
    var [r, f] = await con.query('SELECT DATE(datetime) as date, ROUND(SUM(`amount`), 2) as amount FROM payouts_stake WHERE idUser =? AND YEAR(date(datetime))=? AND MONTH(date(datetime))=? GROUP BY DATE(datetime)', [id, year, month]);

    if (r != null) {
      for (var i = 0; i < r.length; i++) {
        var rt = await getMessagesTime(r[i].date);
        var add = {
          date: rt,
          amount: r[i].amount,
        }
        myArray.push(add);
      }
      return JSON.stringify(myArray);
    }
  } catch (e) {
    console.log(e);
    return "err";
  }
}

async function getEstimatedRewards(id) {
  var userAmount = 0;
  var grandtotal = 0;
  var totalCoins = 0;

  var [r, f] = await con.query("SELECT IFNULL(SUM(amount), 0) as amount FROM transaction_stake WHERE datetime >= now() - INTERVAL 1 DAY");
  if (r[0].amount !== null) totalCoins = r[0].amount;
  else return 0.0;

  var [rowsAmount, failAmount] = await con.query('SELECT IFNULL(SUM(amount), 0) as amount FROM users_stake WHERE active = ?', [1]);
  if (rowsAmount[0].amount != null) grandtotal = rowsAmount[0].amount;
  else return 0.0;

  var [rowsUserAmount, failUA] = await con.query('SELECT IFNULL(amount, 0) as amount FROM users_stake WHERE active = ? AND idUser = ?', [1, id]);
  if (rowsUserAmount !== null) userAmount = rowsUserAmount[0].amount;
  else return 0.0;

  var percentage = parseFloat((userAmount / grandtotal).toFixed(3));
  var credit = parseFloat(totalCoins * percentage).toFixed(3);

  return credit;
}

async function getStakeStats(id) {
  var [rowsSum, failAmount] = await con.query('SELECT ROUND(sum(amount), 2) as sum FROM users_stake where active = 1');
  var sum = rowsSum != null ? rowsSum[0].sum : 0.0;
  var [rowsUserAmount, failUA] = await con.query('SELECT amount FROM users_stake WHERE active = ? AND idUser = ?', [1, id]);
  var percentage = rowsUserAmount[0] != undefined ? parseFloat((rowsUserAmount[0].amount / sum).toFixed(3)) : 0.0;
  var est = await getEstimatedRewards(id);
  var locker = await stakeAmountLocked(id);
  var rew = await stakeAmountReward(id);
  var sa = await stakeAmount(id);
  var add = {
    total: sum,
    contribution: percentage * 100,
    estimated: est,
    locked: locker,
    reward: rew,
    amount: sa,
  }
  return JSON.stringify(add);
}

async function getPrivKey(address) {
  try {
    await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 100]);
    var r = await rpc.run('dumpprivkey', [address.toString()]);
    await rpc.run('walletlock', []);
    if (r.error === null) {
      return r.result;
    } else {
      return "err";
    }
  } catch (e) {
    return "err";
  }
}

async function deleteAccount(id) {
  console.log("SHIT " + id)
  let [rows, fields] = await con.query('SELECT * FROM users WHERE id = ?', [id]);
  if (rows.length > 0) {
    let addr = rows[0].addr;
    console.log(addr);
    let username = rows[0].username;
    console.log(username);
    await con.query('DELETE FROM users_stake WHERE idUser = ?', [id]);
    await con.query('DELETE FROM devices WHERE idUser = ?', [id]);
    await con.query('DELETE FROM transaction WHERE account = ?', [username]);
    await con.query('DELETE FROM payouts_stake WHERE idUser = ?', [id]);
    await con.query('UPDATE addressbook SET name = ? WHERE addr = ?', ["Deleted user", addr]);
    let [rowsDelete, fields2] = await con.query('DELETE FROM users WHERE id = ?', [id]);
    if (rowsDelete.affectedRows > 0) {
      return "ok";
    } else {
      return "err";
    }
  } else {
    return "err";
  }

}

async function getCurrentDate() {
  let d = new Date()
  let mySqlTimestamp = new Date(
    d.getFullYear(),
    d.getMonth(),
    d.getDate(),
    d.getHours(),
    (d.getMinutes() + 30), // add 30 minutes
    d.getSeconds(),
    d.getMilliseconds()
  ).toISOString().slice(0, 19).replace('T', ' ');
  return mySqlTimestamp;
}



function doRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      res.setEncoding('utf8');
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        resolve(JSON.parse(responseBody));
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(data)
    req.end();
  });
}

async function doSendRequest(addrReceive, addrSend, amount) {
  const data = JSON.stringify({
    "address_receive": addrReceive,
    "address_send": addrSend,
    "amount": amount
  });

  const options = {
    hostname: 'localhost',
    port: 6900,
    path: '/send',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    },
  };
  return await doRequest(options, data);
}
