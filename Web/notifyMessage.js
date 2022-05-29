const mysql = require('mysql2/promise');
const ms = require('mysql2');
const CampusAsync = require('./lib/campus-async.js');
var gcm = require('node-gcm');
require('dotenv').config();

const fireSender = new gcm.Sender(process.env.ENC_FIRE);
const rpc = new CampusAsync(process.env.ENC_CRYPTO);

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
runNotify();

async function runNotify() {
    saveMessages();
    setTimeout(notify, 1000);
    setTimeout(closeConnection, 5000);
}

function closeConnection() {
    con.end();
}



function Utf8Decode(strUtf) {
    // note: decode 2-byte chars last as decoded 2-byte strings could appear to be 3-byte or 4-byte char!
    return String(strUtf).replace(
        /[\u00f0-\u00f7][\u0080-\u00bf][\u0080-\u00bf][\u0080-\u00bf]/g,  // 4-byte chars
        function (c) {  // (note parentheses for precedence)
            var cc = ((c.charCodeAt(0) & 0x07) << 18) | ((c.charCodeAt(1) & 0x3f) << 12) | ((c.charCodeAt(2) & 0x3f) << 6) | (c.charCodeAt(3) & 0x3f);
            var tmp = cc - 0x10000;
            // TODO: throw error(invalid utf8) if tmp > 0xfffff
            return String.fromCharCode(0xd800 + (tmp >> 10), 0xdc00 + (tmp & 0x3ff)); // surrogate pair
        }
    ).replace(
        /[\u00e0-\u00ef][\u0080-\u00bf][\u0080-\u00bf]/g,  // 3-byte chars
        function (c) {  // (note parentheses for precedence)
            var cc = ((c.charCodeAt(0) & 0x0f) << 12) | ((c.charCodeAt(1) & 0x3f) << 6) | (c.charCodeAt(2) & 0x3f);
            return String.fromCharCode(cc);
        }
    ).replace(
        /[\u00c0-\u00df][\u0080-\u00bf]/g,                 // 2-byte chars
        function (c) {  // (note parentheses for precedence)
            var cc = (c.charCodeAt(0) & 0x1f) << 6 | c.charCodeAt(1) & 0x3f;
            return String.fromCharCode(cc);
        }
    );
}



async function saveMessages() {
    var json;
    try {
        await rpc.run('walletpassphrase', [process.env.ENC_WALLET_PASS, 300]);
        const res = await rpc.run('smsginbox', ["all", 1]);
        var k = JSON.stringify(res);
        // console.log(k);
        var json = JSON.parse(k.toString('utf8').replace(/^\uFFFD/, ''));
        // console.log(json);
        inserMessages(json);

        // const res2 = await rpc.run('smsgoutbox', ["all", 1]);
        // await rpc.run('walletlock', []);
        // var k2 = JSON.stringify(res2);
        // var json2 = JSON.parse(k2.toString('utf8').replace(/^\uFFFD/, ''));
        // inserMessagesOut(json2);
    } catch (error) {
        console.log(error);
    }
}

async function inserMessages(js) {
    if (con == null) {
        con = mysql.createPool({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_SELECT,
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0,
        });
    }
    var count = 0;

    var json = js["result"];
    for (var i = 0; i < json['messages'].length; i++) {
        var direction = "in";
        var sentAddr = json['messages'][i].from;
        var receiveAddr = json['messages'][i].to;
        var sentTimeDate = new Date(json['messages'][i].sent);
        var sentTime = sentTimeDate.toISOString().slice(0, 19).replace('T', ' ');
        var receiveTimeDate = new Date(json['messages'][i].received);
        var receiveTime = receiveTimeDate.toISOString().slice(0, 19).replace('T', ' ')
        var text = json['messages'][i].text;

        text = Utf8Decode(decodeURIComponent(escape(text)));
        var [r, f] = await con.query('SELECT * FROM messages WHERE sentAddr = ? AND receiveAddr = ? AND sentTime = ?', [sentAddr, receiveAddr, sentTime]);

        if (r[0] == null) {
            await con.query('INSERT INTO messages(sentAddr, receiveAddr, sentTime, receiveTime, text, direction) VALUES (?, ?, ?, ?, ?, ?)', [sentAddr, receiveAddr, sentTime, receiveTime, text, direction]);
        }

    }
}


async function inserMessagesOut(js) {
    if (con == null) {
        con = mysql.createPool({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_SELECT,
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0,
        });
    }
    var json = js["result"];
    for (var i = 0; i < json['messages'].length; i++) {
        var direction = "out";
        var sentAddr = json['messages'][i].from;
        var receiveAddr = json['messages'][i].to;
        var sentTimeDate = new Date(json['messages'][i].sent);
        var sentTime = sentTimeDate.toISOString().slice(0, 19).replace('T', ' ');
        var receiveTimeDate = new Date(json['messages'][i].sent);;
        var receiveTime = receiveTimeDate.toISOString().slice(0, 19).replace('T', ' ')
        var text = json['messages'][i].text;

        text = Utf8Decode(decodeURIComponent(escape(text)));
        var [r, f] = await con.query('SELECT * FROM messages WHERE sentAddr = ? AND receiveAddr = ? AND sentTime = ?', [sentAddr, receiveAddr, sentTime]);

        if (r[0] == null) {
            await con.query('INSERT INTO messages(sentAddr, receiveAddr, sentTime, receiveTime, text, direction) VALUES (?, ?, ?, ?, ?, ?)', [sentAddr, receiveAddr, sentTime, receiveTime, text, direction]);
        }
    }
    await notify();
}



async function notify() {
    if (con == null) {
        con = mysql.createPool({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_SELECT,
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0,
        });
    }
    try {
        var registrationReceiveTokens = [];
        var registrationSendTokens = [];

        var [x, z] = await con.query("SELECT * FROM messages WHERE notify = 1");
        for (var i = 0; i < x.length; i++) {
            var message = new gcm.Message({
                priority: 'high',
                contentAvailable: true,
                notification: {
                    body: "You have a new message",
                    title: x[i].text,
                    icon: "@drawable/ic_notification",
                    sound: "default",
                    android_channel_id: "ccash2",
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
                if (err) console.error(err);
            });
        }

        var [f, g] = await con.query("SELECT sentAddr FROM konjungate.messages WHERE notify = 1 GROUP BY sentAddr");
        for (var i = 0; i < f.length; i++) {
            var message = new gcm.Message({
                priority: 'high',
                contentAvailable: true,
                notification: {
                    android_channel_id: "ccash2",
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

        var [c, d] = await con.query('UPDATE messages SET notify = 0 WHERE id <> 0');

    } catch (e) {
        console.log(e);
    }

}