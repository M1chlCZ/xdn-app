// ignore_for_file: constant_identifier_names

library digitalnote.globals;

bool isLoggedIn = false;
const String SERVER_URL = 'http://194.60.201.213:3000';
const String DAO_URL = 'http://194.60.201.213:6800/dao/v1';
const String API_URL = 'http://194.60.201.213:6800/api/v1';
const String USERNAME = "username";
const String ID = "idUser";
const String ADR = "adr";
const String NICKNAME = "nickname";
const String LOCALE = "locale";
const String LEVEL = "level";
const String UDID = "udid";
const String TOKEN = "jwt";
const String TOKEN_DAO = "jwtDao";
const String PIN = "pin";
const String ADMINPRIV = "admin";
const String FIRETOKEN = "firetoken";
const String COUNTDOWN = "countdownTime";
const String LOCALE_APP = 'locale_app';
const String AUTH_TYPE = 'auth_type';

const String DB_NAME = "databazia";

const String TABLE_ADDR = 'addrbook';
const String ADDR_ID = 'id';
const String ADDR_NAME = 'name';
const String ADDR_ADDR = "addr";

const String TABLE_MGROUP = 'messageGroup';
const String MGROUP_SENT_ADDR = 'sentAddr';
const String MGROUP_UNREAD = 'unread';
const String MGROUP_LAST_MESSAGE = 'lastReceivedMessage';
const String MGROUP_TEXT = 'text';
const String MGROUP_OG_SENT_ADDR = 'sentAddressOrignal';

const String TABLE_MESSAGES = "messages";
const String MESSAGES_ID = 'id';
const String MESSAGES_ID_REPLY = 'idReply';
const String MESSAGES_RECEIVE_ADDR = 'receiveAddr';
const String MESSAGES_SENT_ADDR = 'sentAddr';
const String MESSAGES_UNREAD = 'unread';
const String MESSAGES_LAST_MESSAGE = 'lastMessage';
const String MESSAGES_TEXT = 'text';
const String MESSAGES_LIKES = 'likes';
const String MESSAGES_LAST_CHANGE = 'lastChange';

const String TABLE_TRANSACTION = "transactions";
const String TRAN_ID = 'id';
const String TRAN_TXID = 'txid';
const String TRAN_AMOUNT = 'amount';
const String TRAN_CONFIRMATION = 'confirmation';
const String TRAN_CATEGORY = 'category';
const String TRAN_ADDR = 'address';
const String TRAN_ACC = 'account';
const String TRAN_DATE = 'datetime';
const String TRAN_CONTACT = 'contactName';

const String TABLE_AVATARS = "avatars";
const String AV_ID = "id";
const String AV_VER = "aversion";

const String APP_NOT = 'showMessages';

const List<String> LANGUAGES = ['English', 'Bosnian', 'Croatian', 'Czech', 'Dutch', 'Finnish', 'German', 'Hindi', 'Japanese', 'Ukrainian', 'Serbian Latin', 'Serbian Цyриллиц', 'Spanish', 'Panjabi'];
const List<String> LANGUAGES_CODES = ['en', 'bs_BA', 'hr_HR', 'cs_CZ', 'nl_NL', 'fi_FI', 'de_DE', 'hi_IN', 'ja_JP', 'uk_UA', 'sr_Latn_RS', 'sr_Cyrl_RS', 'es_ES', 'pa_IN'];

bool reloadData = false;