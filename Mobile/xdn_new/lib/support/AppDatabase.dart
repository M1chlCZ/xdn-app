import 'dart:convert';
import 'dart:io' show Platform;
import "dart:io" as io;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprintf/sprintf.dart';
import 'package:sqflite/sqflite.dart';

import '../globals.dart' as globals;
import '../models/Contact.dart';
import '../models/DateSeparator.dart';
import '../models/Message.dart';
import '../models/MessageGroup.dart';
import 'NetInterface.dart';
import '../models/TranSaction.dart';

const dbVersion = 1;

class AppDatabase {
  static Database? _db;
  static final AppDatabase _instance = AppDatabase.internal();

  factory AppDatabase() => _instance;
  List<String> tablesSql = [];

  AppDatabase.internal();

  final String tableAddr = sprintf('CREATE TABLE IF NOT EXISTS %s (%s INTEGER PRIMARY KEY, %s STRING, %s STRING)', [globals.TABLE_ADDR, globals.ADDR_ID, globals.ADDR_NAME, globals.ADDR_ADDR]);

  final String tableMessageGroup = sprintf('CREATE TABLE IF NOT EXISTS %s (%s STRING, %s STRING, %s INTEGER, %s STRING, %s STRING)',
      [globals.TABLE_MGROUP, globals.MGROUP_OG_SENT_ADDR, globals.MGROUP_SENT_ADDR, globals.MGROUP_UNREAD, globals.MGROUP_LAST_MESSAGE, globals.MGROUP_TEXT]);

  final String tableMessages = sprintf('CREATE TABLE IF NOT EXISTS %s (%s INTEGER PRIMARY KEY, %s STRING, %s STRING, %s INTEGER, %s STRING, %s STRING, %s INTEGER, %s INTEGER, %s INTEGER)', [
    globals.TABLE_MESSAGES,
    globals.MESSAGES_ID,
    globals.MESSAGES_RECEIVE_ADDR,
    globals.MESSAGES_SENT_ADDR,
    globals.MESSAGES_UNREAD,
    globals.MESSAGES_LAST_MESSAGE,
    globals.MESSAGES_TEXT,
    globals.MESSAGES_ID_REPLY,
    globals.MESSAGES_LIKES,
    globals.MESSAGES_LAST_CHANGE,
  ]);

  final String tableTransactions = sprintf('CREATE TABLE IF NOT EXISTS %s (%s INTEGER PRIMARY KEY, %s STRING, %s STRING, %s STRING, %s STRING, %s INTEGER, %s STRING)', [
    globals.TABLE_TRANSACTION,
    globals.TRAN_ID,
    globals.TRAN_TXID,
    globals.TRAN_CATEGORY,
    globals.TRAN_DATE,
    globals.TRAN_AMOUNT,
    globals.TRAN_CONFIRMATION,
    globals.TRAN_CONTACT,
  ]);

  final String tableAvatars = sprintf('CREATE TABLE IF NOT EXISTS %s (%s STRING, %s INTEGER)', [
    globals.TABLE_AVATARS,
    globals.AV_ID,
    globals.AV_VER,
  ]);

  Future<Database> get db async {
    tablesSql.add(tableAddr);
    tablesSql.add(tableMessageGroup);
    tablesSql.add(tableMessages);
    tablesSql.add(tableTransactions);
    tablesSql.add(tableAvatars);
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, 'db_diginot.db');
    var db = await openDatabase(path, version: dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return db;
  }

  Future countTable() async {
    final dbClient = await db;
    var res = await dbClient.rawQuery("""SELECT count(*) as count FROM sqlite_master
         WHERE type = 'table' 
         AND name != 'android_metadata' 
         AND name != 'sqlite_sequence';""");
    return res[0]['count'];
  }

  Future addAddrBook(List<Contact> input) async {
    final dbClient = await db;
    await dbClient.delete(globals.TABLE_ADDR);
    await dbClient.execute(tableAddr);
    for (var i = 0; i < input.length; i++) {
      await dbClient.insert(globals.TABLE_ADDR, input[i].toMap());
    }
    return 1;
  }

  Future<void> deleteTableAddr() async {
    final dbClient = await db;
    await dbClient.delete(globals.TABLE_ADDR);
  }

  Future<void> deleteTableTran() async {
    final dbClient = await db;
    await dbClient.delete(globals.TABLE_TRANSACTION);
  }

  Future<void> deleteTableMessages() async {
    final dbClient = await db;
    await dbClient.delete(globals.TABLE_MESSAGES);
  }

  Future<void> deleteTableMgroup() async {
    final dbClient = await db;
    await dbClient.delete(globals.TABLE_MGROUP);
  }

  Future addContact(String name, String addr) async {
    final dbClient = await db;
    dynamic user = {
      "name": name,
      "addr": addr,
    };
    var res = dbClient.insert(globals.TABLE_ADDR, user);
    return res;
  }

  Future editContact(String name, String id) async {
    final dbClient = await db;
    dynamic contact = {
      "name": name,
    };
    var res = dbClient.update(globals.TABLE_ADDR, contact, where: "${globals.ADDR_ID} = ?", whereArgs: [id]);
    NetInterface.updateContact(name, id);
    return res;
  }

  Future<List<Map<String, Object?>>> getContacts() async {
    final dbClient = await db;
    var res = dbClient.query(globals.TABLE_ADDR, orderBy: "id DESC");
    return res;
  }

  Future<List<Contact>> getContact(int id) async {
    final dbClient = await db;
    var res = await dbClient.query(globals.TABLE_ADDR, where: "id = ?", whereArgs: [id], limit: 1);
    return List.generate(res.length, (i)  {
      return Contact(
        id: res[i]['id'] as int,
        name: res[i]['name'] as String,
        addr: res[i]['addr'] as String,
      );
    });
  }

  Future<String?> getContactByAddr(String addr) async {
    final dbClient = await db;
    var res = await dbClient.query(globals.TABLE_ADDR, columns: ['id'], where: "addr = ?", whereArgs: [addr], limit: 1);
    var l = List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
      );
    });
    if (l.isEmpty) {
      return null;
    } else {
      return l[0].id.toString();
    }
  }

  Future<String?> getContactNameByAddr(String addr) async {
    final dbClient = await db;
    var res = await dbClient.query(globals.TABLE_ADDR, columns: ['name'], where: "addr = ?", whereArgs: [addr], limit: 1);
    var l = List.generate(res.length, (i) {
      return Contact(
        name: res[i]['name'] as String,
      );
    });
    if (l.isEmpty) {
      return null;
    } else {
      return l[0].name.toString();
    }
  }

  Future<String> getContactByNameAddr(String name, String addr) async {
    final dbClient = await db;
    var res = await dbClient.query(globals.TABLE_ADDR, columns: ['id'], where: "name = ? AND addr = ?", whereArgs: [name, addr], limit: 1);
    var l = List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
      );
    });
    return l[0].id.toString();
  }

  Future deleteContact(int id) async {
    final dbClient = await db;
    var res = await dbClient.delete(globals.TABLE_ADDR, where: 'id = ?', whereArgs: [id]);
    return res;
  }

  Future<List<Contact>> searchContact(String searchQuery) async {
    var d = await db;
    var res = await d.rawQuery("SELECT * FROM ${globals.TABLE_ADDR} WHERE name LIKE '$searchQuery%' COLLATE NOCASE");
    return List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
        name: res[i]['name'] as String,
        addr: res[i]['addr'] as String,
      );
    });
  }

  Future<List<Contact>> getShareContactList(String searchQuery) async {
    var d = await db;
    var res = await d.rawQuery("SELECT * FROM ${globals.TABLE_ADDR} WHERE name IS NOT '$searchQuery'");
    return List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
        name: res[i]['name'] as String,
        addr: res[i]['addr'] as String,
      );
    });
  }

  Future<void> addMessageGroup(List<MessageGroup> input) async {
    final dbClient = await db;
    // await dbClient.delete(globals.TABLE_MGROUP);
    // await dbClient.execute(tableMessageGroup);
    // print(input.length.toString());
    for (var i = 0; i < input.length; i++) {
      var check = await dbClient.query(globals.TABLE_MGROUP, where: "${globals.MGROUP_SENT_ADDR} = ? ", whereArgs: [input[i].sentAddr]);
      if (check.isNotEmpty) {
        var getUnread = await dbClient.query(globals.TABLE_MGROUP, columns: [globals.MGROUP_UNREAD], where: "${globals.MGROUP_SENT_ADDR} = ? ", whereArgs: [input[i].sentAddr]);
        if (int.parse(getUnread.first['unread'].toString()) < input[i].unread!.toInt()) {
          await dbClient.update(globals.TABLE_MGROUP, input[i].toMap(), where: "${globals.MGROUP_SENT_ADDR} = ? ", whereArgs: [input[i].sentAddr]);
        } else {
          Map<String, dynamic> row = {globals.MGROUP_LAST_MESSAGE: input[i].lastReceivedMessage, globals.MGROUP_TEXT: input[i].text};
          await dbClient.update(globals.TABLE_MGROUP, row, where: "${globals.MGROUP_OG_SENT_ADDR}= ?", whereArgs: [input[i].sentAddressOrignal]);
        }
      } else {
        await dbClient.insert(globals.TABLE_MGROUP, input[i].toMap());
      }
    }
  }

  Future<List<MessageGroup>> getMessageGroup() async {
    final dbClient = await db;
    var res = await dbClient.rawQuery("SELECT COALESCE(t2.name, t1.sentAddr) as sentAddr, t1.sentAddressOrignal, t1.unread, t1.lastReceivedMessage, t1.text FROM ${globals.TABLE_MGROUP} t1 LEFT JOIN ${globals.TABLE_ADDR} t2 ON t1.sentAddr = t2.addr ORDER BY t1.lastReceivedMessage DESC");
    return List.generate(res.length, (i) {
      return MessageGroup(
          sentAddr: res[i]['sentAddr'].toString(),
          unread: res[i]['unread'] as int,
          lastReceivedMessage: res[i]['lastReceivedMessage'].toString(),
          text: res[i]['text'].toString(),
          sentAddressOrignal: res[i]['sentAddressOrignal'].toString());
    });
  }


  Future<MessageGroup?> getMessageGroupByAddr(String addr) async {
    final dbClient = await db;
    var res = await dbClient.rawQuery("SELECT COALESCE(t2.name, t1.sentAddr) as sentAddr, t1.sentAddressOrignal, t1.unread, t1.lastReceivedMessage, t1.text FROM ${globals.TABLE_MGROUP} t1 LEFT JOIN ${globals.TABLE_ADDR} t2 ON t1.sentAddr = t2.addr WHERE t1.sentAddressOrignal = '$addr' ORDER BY t1.lastReceivedMessage DESC");
    if(res.isEmpty) return null;

      return MessageGroup(
          sentAddr: res[0]['sentAddr'].toString(),
          unread: res[0]['unread'] as int,
          lastReceivedMessage: res[0]['lastReceivedMessage'].toString(),
          text: res[0]['text'].toString(),
          sentAddressOrignal: res[0]['sentAddressOrignal'].toString());
  }

  Future<int>? getUnread() async {
    final dbClient = await db;
    var res = await dbClient.rawQuery("SELECT sum(unread) as unread FROM messageGroup");
    if (res.first['unread'] == null) return 0;
    return res.first['unread'] as int;
  }

  Future<int>? getLikes(int id) async {
    final dbClient = await db;
    var res = await dbClient.rawQuery("SELECT likes FROM messages WHERE id = $id");
    if (res.first['likes'] == null) return 0;
    return res.first['likes'] as int;
  }

  Future<int> addMessages(List<Message> input) async {
    final dbClient = await db;
    // await dbClient.delete(globals.TABLE_MESSAGES);
    // await dbClient.execute(tableMessages);
    int count = 0;
    for (var i = 0; i < input.length; i++) {
      var check = await dbClient.query(
        globals.TABLE_MESSAGES,
        where: "${globals.MESSAGES_ID} = ? ",
        whereArgs: [input[i].id],
      );
      if (check.isEmpty) {
        count += 1;
        await dbClient.insert(globals.TABLE_MESSAGES, input[i].toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        // print("MESSAGE UPDATE");
        await updateMessageLikes(input[i].id as int, input[i].likes as int);
        await updateMessageLastChange(input[i].id as int, input[i].lastChange as int);
      }
    }
    return count;
  }

  Future<List<dynamic>>? getMessages(String receiveAddr, String sentAddr) async {
    String? lastDate;
    var len = 0;
    final dbClient = await db;
    var res = await dbClient.rawQuery("SELECT * FROM messages WHERE (receiveAddr LIKE '%$receiveAddr%' AND sentAddr LIKE '%$sentAddr%') UNION ALL SELECT * FROM messages WHERE (receiveAddr LIKE '%$sentAddr%' AND sentAddr LIKE '%$receiveAddr%') ORDER BY lastMessage DESC" );
    // var res = await dbClient.query(globals.TABLE_MESSAGES,
    //     where: "(" + globals.MESSAGES_RECEIVE_ADDR + " = ? AND " + globals.MESSAGES_SENT_ADDR + " = ?) OR (" + globals.MESSAGES_RECEIVE_ADDR + " = ? AND " + globals.MESSAGES_SENT_ADDR + " = ?)",
    //     whereArgs: [receiveAddr, sentAddr, sentAddr, receiveAddr],
    //     orderBy: globals.MESSAGES_LAST_MESSAGE + " DESC");
    var l = List.generate(res.length, (i) {

      return Message(
        id: res[i]['id'] as int,
        receiveAddr: res[i]['sentAddr'].toString(),
        sentAddr: res[i]['sentAddr'].toString(),
        unread: res[i]['unread'] as int,
        lastMessage: res[i]['lastMessage'].toString(),
        text: utfEncode(res[i]['text'].toString()),
        idReply: res[i]['idReply'] as int,
        likes: res[i]['likes'] as int,
      );
    });
    List<dynamic> myList = <dynamic>[];
    len = l.length;
    var counter = 0;
    for (Message m in l) {
      counter++;
      var date = _getMeDate(m.lastMessage!);
      if (lastDate == null) {
        myList.add(m);
        lastDate = date;
      } else if (len == counter) {
        myList.add(m);
        myList.add(DateSeparator(lastMessage: lastDate));
      } else if (lastDate != date) {
        myList.add(DateSeparator(lastMessage: lastDate));
        myList.add(m);
        lastDate = date;
      } else {
        myList.add(m);
      }
    }
    return myList;
  }

  utfEncode(String s) {
      List<int> bytes = s.toString().codeUnits;
      return utf8.decode(bytes);

  }

  Future<int> getMessageGroupMaxID(String? receiveAddr, String? sentAddr) async {
    if (receiveAddr == null || sentAddr == null) return 0;
    final dbClient = await db;
    var res = await dbClient.query(
      globals.TABLE_MESSAGES,
      columns: ["MAX(lastChange) as lastChange"],
      where: "(${globals.MESSAGES_RECEIVE_ADDR} = ? AND ${globals.MESSAGES_SENT_ADDR} = ?) OR (${globals.MESSAGES_RECEIVE_ADDR} = ? AND ${globals.MESSAGES_SENT_ADDR} = ?)",
      whereArgs: [receiveAddr, sentAddr, sentAddr, receiveAddr],
    );

    if (res.first['lastChange'] == null) return 0;

    return res.first['lastChange'] as int;
  }

  Future<String> getReplyText(int id) async {
    final dbClient = await db;
    var res = await dbClient.query(
      globals.TABLE_MESSAGES,
      columns: [globals.MESSAGES_TEXT],
      where: "${globals.MESSAGES_ID} = $id",
    );
    return res.first[globals.MESSAGES_TEXT] as String;
  }

  String _getMeDate(String d) {
    var date = DateTime.parse(d).toLocal();
    var format = DateFormat.MMMMd(Platform.localeName);
    return format.format(date);
  }

  Future<void> updateMessageGroupRead(String receiveAddr, sentAddr) async {
    final dbClient = await db;
    Map<String, dynamic> row = {
      globals.MGROUP_UNREAD: 0,
    };
    await dbClient.update(globals.TABLE_MGROUP, row, where: "${globals.MGROUP_OG_SENT_ADDR}= ?", whereArgs: [sentAddr]);
  }

  Future<void> updateMessageLikes(int id, int value) async {
    final dbClient = await db;
    Map<String, dynamic> row = {
      globals.MESSAGES_LIKES: value,
    };
    await dbClient.update(globals.TABLE_MESSAGES, row, where: "${globals.MESSAGES_ID}= ?", whereArgs: [id]);
  }

  Future<void> updateMessageLastChange(int id, int value) async {
    final dbClient = await db;
    Map<String, dynamic> row = {
      globals.MESSAGES_ID: id,
      globals.MESSAGES_LAST_CHANGE: value,
    };
    await dbClient.update(globals.TABLE_MESSAGES, row, where: "${globals.MESSAGES_ID}=?", whereArgs: [id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageGroup>> searchMessages(String searchQuery) async {
    final d = await db;
    var res = await d.rawQuery("SELECT COALESCE(t2.name, t1.sentAddr) as sentAddr, t1.sentAddressOrignal, t1.unread, t1.lastReceivedMessage, t1.text FROM ${globals.TABLE_MGROUP} t1 LEFT JOIN ${globals.TABLE_ADDR} t2 ON t1.sentAddr = t2.addr WHERE t2.name LIKE '$searchQuery%' ORDER BY t1.lastReceivedMessage DESC");
    return List.generate(res.length, (i) {
      return MessageGroup(
          sentAddr: res[i]['sentAddr'].toString(),
          unread: res[i]['unread'] as int,
          lastReceivedMessage: res[i]['lastReceivedMessage'].toString(),
          text: res[i]['text'].toString(),
          sentAddressOrignal: res[i]['sentAddressOrignal'].toString());
    });
  }

  Future<int> addTransactions(List<TranSaction> list) async {
    final dbClient = await db;
    try {
      for (var l in list) {
          await dbClient.insert(globals.TABLE_TRANSACTION, l.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      return 1;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return 0;
    }
  }

  Future<List<TranSaction>> getTransactions({int count = 0}) async {
    final dbClient = await db;
    List<Map<String, Object?>> res;
    if (count == 0) {
      res = await dbClient.query(globals.TABLE_TRANSACTION, orderBy: "${globals.TRAN_DATE} DESC");
    } else {
      res = await dbClient.query(globals.TABLE_TRANSACTION, orderBy: "${globals.TRAN_DATE} DESC", limit: count);
    }
    return List.generate(res.length, (i) {
      return TranSaction(
        id: res[i]['id'] as int?,
        txid: res[i]['txid'].toString(),
        category: res[i]['category'].toString(),
        datetime: res[i]['datetime'].toString(),
        amount: res[i]['amount'].toString(),
        confirmation: res[i]['confirmation'] as int?,
        contactName: res[i]['contactName'].toString(),
      );
    });
  }

  Future<String> getLastTransactionDate() async {
    final dbClient = await db;
    var res = await dbClient.rawQuery('SELECT MAX(datetime) as date FROM ${globals.TABLE_TRANSACTION}');
    return res.last['date'].toString();
  }

  Future<int> insertUpdateAvatar(String id, int version) async {
    final dbClient = await db;
    try {
      var res = await dbClient.query(globals.TABLE_AVATARS, where: "id = ?", whereArgs: [id]);
      if (res.isNotEmpty) {
        if (res.first[globals.AV_VER] != version) {
          Map<String, dynamic> row = {
            globals.AV_VER: version,
          };
          await dbClient.update(globals.TABLE_AVATARS, row, where: "id = ? ", whereArgs: [id]);
          return 1;
        }
        return 0;
      } else {
        Map<String, dynamic> row = {
          globals.AV_VER: version,
          globals.AV_ID: id,
        };
        await dbClient.insert(globals.TABLE_AVATARS, row);
        return 1;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return 0;
    }
  }

//onCreate/onUpgrade
  void _onCreate(Database db, int version) async {
    for (var element in tablesSql) {
      db.execute(element);
    }
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 1:
        try {
          // await db.execute(tableMessageGroup);
          // await db.execute(tableMessages);
          // await db.execute(tableTransactions);
          // await db.execute(tableAvatars);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
        break;
    }
  }
}
