import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bs'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('hi'),
    Locale('hr'),
    Locale('ja'),
    Locale('nl'),
    Locale('pa'),
    Locale('ru'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
    Locale('uk'),
    Locale('sr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DigitalNote'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DigitalNote'**
  String get appTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'DigitalNote APP'**
  String get description;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @user_email.
  ///
  /// In en, this message translates to:
  /// **'Username / E-mail'**
  String get user_email;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @conf_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get conf_password;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @first_last_name.
  ///
  /// In en, this message translates to:
  /// **'First and Last Name'**
  String get first_last_name;

  /// No description provided for @login_can_use.
  ///
  /// In en, this message translates to:
  /// **'You can use'**
  String get login_can_use;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @notice_warn.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice_warn;

  /// No description provided for @fields_cant_empty.
  ///
  /// In en, this message translates to:
  /// **'Fields cannot be empty!'**
  String get fields_cant_empty;

  /// No description provided for @error_occur.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred'**
  String get error_occur;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get sign_up;

  /// No description provided for @log_in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get log_in;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @wendy_first.
  ///
  /// In en, this message translates to:
  /// **'Thanks for using '**
  String get wendy_first;

  /// No description provided for @wendy_second.
  ///
  /// In en, this message translates to:
  /// **'You can use same login on'**
  String get wendy_second;

  /// No description provided for @wendy_third.
  ///
  /// In en, this message translates to:
  /// **'A platform for artists, investors, curators'**
  String get wendy_third;

  /// No description provided for @wendy_fourth.
  ///
  /// In en, this message translates to:
  /// **'and the forever curious'**
  String get wendy_fourth;

  /// No description provided for @wendy_fifth.
  ///
  /// In en, this message translates to:
  /// **'Like you'**
  String get wendy_fifth;

  /// No description provided for @username_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Username'**
  String get username_invalid;

  /// No description provided for @username_invalid_message.
  ///
  /// In en, this message translates to:
  /// **'The username should be at least 4 characters long'**
  String get username_invalid_message;

  /// No description provided for @password_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Password'**
  String get password_invalid;

  /// No description provided for @password_invalid_message.
  ///
  /// In en, this message translates to:
  /// **'The password should be at least 4 characters long'**
  String get password_invalid_message;

  /// No description provided for @email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid e-mail'**
  String get email_invalid;

  /// No description provided for @email_invalid_message.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid e-mail address'**
  String get email_invalid_message;

  /// No description provided for @name_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid name'**
  String get name_invalid;

  /// No description provided for @name_invalid_message.
  ///
  /// In en, this message translates to:
  /// **'Please enter name which is longer than 6 characters'**
  String get name_invalid_message;

  /// No description provided for @password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get password_mismatch;

  /// No description provided for @password_mismatch_message.
  ///
  /// In en, this message translates to:
  /// **'Please enter same password to password and password confirmation box'**
  String get password_mismatch_message;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amount_empty.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be empty!'**
  String get amount_empty;

  /// No description provided for @konj_addr_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid XDN address'**
  String get konj_addr_invalid;

  /// No description provided for @succ.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get succ;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @immature.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get immature;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @send_to.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get send_to;

  /// No description provided for @send_wait.
  ///
  /// In en, this message translates to:
  /// **'Sending transaction, please wait'**
  String get send_wait;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @new_name.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get new_name;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @reg_succ_message.
  ///
  /// In en, this message translates to:
  /// **'Now you can log in'**
  String get reg_succ_message;

  /// No description provided for @usr_exists_err.
  ///
  /// In en, this message translates to:
  /// **'That username is already registered'**
  String get usr_exists_err;

  /// No description provided for @usr_exists_err_message.
  ///
  /// In en, this message translates to:
  /// **'Please try to sign up using another username or log in if you already have an account'**
  String get usr_exists_err_message;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @contact_add.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get contact_add;

  /// No description provided for @search_contact.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get search_contact;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @camera_perm.
  ///
  /// In en, this message translates to:
  /// **'Please grant this app permissions for Camera'**
  String get camera_perm;

  /// No description provided for @storage_perm.
  ///
  /// In en, this message translates to:
  /// **'Please grant this app permissions for Storage'**
  String get storage_perm;

  /// No description provided for @contact_added.
  ///
  /// In en, this message translates to:
  /// **'Contact added'**
  String get contact_added;

  /// No description provided for @contact_del.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this contact?'**
  String get contact_del;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @message_new.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get message_new;

  /// No description provided for @message_search.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get message_search;

  /// No description provided for @message_recipient_missing.
  ///
  /// In en, this message translates to:
  /// **'Missing recipient'**
  String get message_recipient_missing;

  /// No description provided for @message_missing.
  ///
  /// In en, this message translates to:
  /// **'Missing message'**
  String get message_missing;

  /// No description provided for @message_choose_recipient.
  ///
  /// In en, this message translates to:
  /// **'Choose recipient'**
  String get message_choose_recipient;

  /// No description provided for @message_not_warning.
  ///
  /// In en, this message translates to:
  /// **'Please turn on notification for proper sending/receiving of messages'**
  String get message_not_warning;

  /// No description provided for @message_tipped.
  ///
  /// In en, this message translates to:
  /// **'tipped'**
  String get message_tipped;

  /// No description provided for @message_reply_to.
  ///
  /// In en, this message translates to:
  /// **'Reply to'**
  String get message_reply_to;

  /// No description provided for @message_copy.
  ///
  /// In en, this message translates to:
  /// **'Content of the message has been copied to clipboard'**
  String get message_copy;

  /// No description provided for @pin_enter.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get pin_enter;

  /// No description provided for @pin_message.
  ///
  /// In en, this message translates to:
  /// **'This app is PIN protected, you must enter code to continue. You can disable PIN in the settings of the app'**
  String get pin_message;

  /// No description provided for @set_pin_removed.
  ///
  /// In en, this message translates to:
  /// **'PIN has been removed'**
  String get set_pin_removed;

  /// No description provided for @set_pin_not_match.
  ///
  /// In en, this message translates to:
  /// **'PIN does not match passcode set in this app, please try again'**
  String get set_pin_not_match;

  /// No description provided for @set_download.
  ///
  /// In en, this message translates to:
  /// **'File has been downloaded to you Download directory'**
  String get set_download;

  /// No description provided for @set_csv_no_app.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an app to open xlsx files'**
  String get set_csv_no_app;

  /// No description provided for @set_headline.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get set_headline;

  /// No description provided for @set_pin.
  ///
  /// In en, this message translates to:
  /// **'Set up a pin'**
  String get set_pin;

  /// No description provided for @set_pin_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get set_pin_confirm;

  /// No description provided for @set_remove_pin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get set_remove_pin;

  /// No description provided for @set_nickname.
  ///
  /// In en, this message translates to:
  /// **'Change Nickname'**
  String get set_nickname;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @set_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get set_password;

  /// No description provided for @set_priv_key.
  ///
  /// In en, this message translates to:
  /// **'Get Wallet Private Key'**
  String get set_priv_key;

  /// No description provided for @set_csv.
  ///
  /// In en, this message translates to:
  /// **'Download TX xlsx'**
  String get set_csv;

  /// No description provided for @set_about.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get set_about;

  /// No description provided for @set_log_out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get set_log_out;

  /// No description provided for @set_pass_error.
  ///
  /// In en, this message translates to:
  /// **'You entered incorrect password'**
  String get set_pass_error;

  /// No description provided for @set_priv_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to retrieve private key'**
  String get set_priv_error;

  /// No description provided for @st_locked_coins.
  ///
  /// In en, this message translates to:
  /// **'Locked Coins'**
  String get st_locked_coins;

  /// No description provided for @st_coins_staked.
  ///
  /// In en, this message translates to:
  /// **'Coins staked'**
  String get st_coins_staked;

  /// No description provided for @st_insufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get st_insufficient;

  /// No description provided for @st_in_fees.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough to make the transaction with current network fess'**
  String get st_in_fees;

  /// No description provided for @st_cannot_stake.
  ///
  /// In en, this message translates to:
  /// **'Your coins cannot be staked right now'**
  String get st_cannot_stake;

  /// No description provided for @st_not_balance.
  ///
  /// In en, this message translates to:
  /// **'Not Enough account balance, try lower number'**
  String get st_not_balance;

  /// No description provided for @st_24h_timeout.
  ///
  /// In en, this message translates to:
  /// **'Your coins are still locked, please wait at least 24 hours after your last stake deposit'**
  String get st_24h_timeout;

  /// No description provided for @st_headline.
  ///
  /// In en, this message translates to:
  /// **'Staking'**
  String get st_headline;

  /// No description provided for @st_coins_today.
  ///
  /// In en, this message translates to:
  /// **'Coins earned today'**
  String get st_coins_today;

  /// No description provided for @st_coins_week.
  ///
  /// In en, this message translates to:
  /// **'Coins earned this month'**
  String get st_coins_week;

  /// No description provided for @st_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get st_live;

  /// No description provided for @st_reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get st_reward;

  /// No description provided for @st_total_coins.
  ///
  /// In en, this message translates to:
  /// **'Total coins in pool'**
  String get st_total_coins;

  /// No description provided for @st_contribution.
  ///
  /// In en, this message translates to:
  /// **'Your contribution in the pool'**
  String get st_contribution;

  /// No description provided for @st_estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated reward per day'**
  String get st_estimated;

  /// No description provided for @st_24h_lock.
  ///
  /// In en, this message translates to:
  /// **'Your coins will be locked for 24 hours after last deposit'**
  String get st_24h_lock;

  /// No description provided for @st_enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to stake'**
  String get st_enter_amount;

  /// No description provided for @st_time_until_unlock.
  ///
  /// In en, this message translates to:
  /// **'Time until your coins will be unlocked'**
  String get st_time_until_unlock;

  /// No description provided for @st_contains.
  ///
  /// In en, this message translates to:
  /// **'Staking amount contains both staked coins and reward'**
  String get st_contains;

  /// No description provided for @st_withdraw_reward.
  ///
  /// In en, this message translates to:
  /// **'Withdraw reward from staking'**
  String get st_withdraw_reward;

  /// No description provided for @st_withdraw_all.
  ///
  /// In en, this message translates to:
  /// **'Withdraw all coins from staking'**
  String get st_withdraw_all;

  /// No description provided for @wl_refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing data'**
  String get wl_refreshing;

  /// No description provided for @wl_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get wl_balance;

  /// No description provided for @dl_remove_pin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get dl_remove_pin;

  /// No description provided for @dl_enter_pin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get dl_enter_pin;

  /// No description provided for @dl_send_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to send the transaction?'**
  String get dl_send_confirm;

  /// No description provided for @dl_delete_contact.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this contact?'**
  String get dl_delete_contact;

  /// No description provided for @dl_log_out.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to log out of the app?'**
  String get dl_log_out;

  /// No description provided for @dl_not_enough_coins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get dl_not_enough_coins;

  /// No description provided for @dl_wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get dl_wait;

  /// No description provided for @dl_credentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get dl_credentials;

  /// No description provided for @dl_edit_name.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get dl_edit_name;

  /// No description provided for @dl_new_contact.
  ///
  /// In en, this message translates to:
  /// **'Add new contact'**
  String get dl_new_contact;

  /// No description provided for @dl_user_exist.
  ///
  /// In en, this message translates to:
  /// **'Users is already in Contact list'**
  String get dl_user_exist;

  /// No description provided for @dl_save_contact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get dl_save_contact;

  /// No description provided for @dl_enter_current_pass.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get dl_enter_current_pass;

  /// No description provided for @dl_enter_pass.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get dl_enter_pass;

  /// No description provided for @dl_new_enter_pass.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get dl_new_enter_pass;

  /// No description provided for @dl_conf_new_pass.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get dl_conf_new_pass;

  /// No description provided for @dl_pass_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get dl_pass_mismatch;

  /// No description provided for @dl_tx_detail.
  ///
  /// In en, this message translates to:
  /// **'Transaction detail'**
  String get dl_tx_detail;

  /// No description provided for @dl_explorer.
  ///
  /// In en, this message translates to:
  /// **'Open in explorer'**
  String get dl_explorer;

  /// No description provided for @dl_tx_copy.
  ///
  /// In en, this message translates to:
  /// **'TX id has been copied to clipboard'**
  String get dl_tx_copy;

  /// No description provided for @dl_konj_addr.
  ///
  /// In en, this message translates to:
  /// **'Your XDN address'**
  String get dl_konj_addr;

  /// No description provided for @dl_share.
  ///
  /// In en, this message translates to:
  /// **'tap to copy, long press to share'**
  String get dl_share;

  /// No description provided for @dl_qr_copy.
  ///
  /// In en, this message translates to:
  /// **'QR code copied to clipboard'**
  String get dl_qr_copy;

  /// No description provided for @dl_konj_priv.
  ///
  /// In en, this message translates to:
  /// **'Your XDN wallet priv key'**
  String get dl_konj_priv;

  /// No description provided for @dl_priv_copy.
  ///
  /// In en, this message translates to:
  /// **'Priv key copied to clipboard'**
  String get dl_priv_copy;

  /// No description provided for @dl_select_action.
  ///
  /// In en, this message translates to:
  /// **'Select action'**
  String get dl_select_action;

  /// No description provided for @dl_send_message.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get dl_send_message;

  /// No description provided for @dl_send_konj.
  ///
  /// In en, this message translates to:
  /// **'Send XDN to'**
  String get dl_send_konj;

  /// No description provided for @menu_wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get menu_wallet;

  /// No description provided for @rec_tx.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get rec_tx;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @register_button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_button;

  /// No description provided for @e_mail.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get e_mail;

  /// No description provided for @forgot_pass.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_pass;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get sentTo;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @txid.
  ///
  /// In en, this message translates to:
  /// **'TX id:'**
  String get txid;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get all;

  /// No description provided for @onew.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get onew;

  /// No description provided for @oned.
  ///
  /// In en, this message translates to:
  /// **'1D'**
  String get oned;

  /// No description provided for @twelveh.
  ///
  /// In en, this message translates to:
  /// **'12H'**
  String get twelveh;

  /// No description provided for @no_tx.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get no_tx;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @txdet.
  ///
  /// In en, this message translates to:
  /// **'Transaction Detail'**
  String get txdet;

  /// No description provided for @txcopy.
  ///
  /// In en, this message translates to:
  /// **'TX id copied to clipboard'**
  String get txcopy;

  /// No description provided for @confirmations.
  ///
  /// In en, this message translates to:
  /// **'confirmations'**
  String get confirmations;

  /// No description provided for @history_popup.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history_popup;

  /// No description provided for @settings_popup.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings_popup;

  /// No description provided for @about_popup.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about_popup;

  /// No description provided for @choose_coin.
  ///
  /// In en, this message translates to:
  /// **'Choose coin'**
  String get choose_coin;

  /// No description provided for @or_scan_qr.
  ///
  /// In en, this message translates to:
  /// **'or receive via QR-code'**
  String get or_scan_qr;

  /// No description provided for @or_send_scan_qr.
  ///
  /// In en, this message translates to:
  /// **'or send via QR-code'**
  String get or_send_scan_qr;

  /// No description provided for @graph_no_data.
  ///
  /// In en, this message translates to:
  /// **'Sorry, we couldn\'t get the data for the graph'**
  String get graph_no_data;

  /// No description provided for @settings_screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_screen;

  /// No description provided for @settings_main.
  ///
  /// In en, this message translates to:
  /// **'Main Settings'**
  String get settings_main;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get settings_privacy;

  /// No description provided for @password_forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get password_forgot;

  /// No description provided for @user_not_exists.
  ///
  /// In en, this message translates to:
  /// **'User does not exists'**
  String get user_not_exists;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get change_language;

  /// No description provided for @delete_acc.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_acc;

  /// No description provided for @voting.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get voting;

  /// No description provided for @connect_wallet.
  ///
  /// In en, this message translates to:
  /// **'Connect BSC wallet'**
  String get connect_wallet;

  /// No description provided for @wallet_connected.
  ///
  /// In en, this message translates to:
  /// **'Wallet connected'**
  String get wallet_connected;

  /// No description provided for @amount_to_reach.
  ///
  /// In en, this message translates to:
  /// **'Amount to reach'**
  String get amount_to_reach;

  /// No description provided for @amount_reached.
  ///
  /// In en, this message translates to:
  /// **'Amount reached'**
  String get amount_reached;

  /// No description provided for @date_ending.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get date_ending;

  /// No description provided for @bnb_balance.
  ///
  /// In en, this message translates to:
  /// **'BNB balance'**
  String get bnb_balance;

  /// No description provided for @gas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get gas;

  /// No description provided for @st_less.
  ///
  /// In en, this message translates to:
  /// **'Show less details'**
  String get st_less;

  /// No description provided for @st_more.
  ///
  /// In en, this message translates to:
  /// **'Show more details'**
  String get st_more;

  /// No description provided for @vot_succ.
  ///
  /// In en, this message translates to:
  /// **'Vote submitted'**
  String get vot_succ;

  /// No description provided for @vot_fail.
  ///
  /// In en, this message translates to:
  /// **'Voting failed'**
  String get vot_fail;

  /// No description provided for @no_contest.
  ///
  /// In en, this message translates to:
  /// **'No voting event available'**
  String get no_contest;

  /// No description provided for @amount_of_votes.
  ///
  /// In en, this message translates to:
  /// **'Amount of votes in category'**
  String get amount_of_votes;

  /// No description provided for @amount_of_votes_user.
  ///
  /// In en, this message translates to:
  /// **'Amount of votes you have'**
  String get amount_of_votes_user;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @remove_2fa.
  ///
  /// In en, this message translates to:
  /// **'Remove 2FA'**
  String get remove_2fa;

  /// No description provided for @set_2fa.
  ///
  /// In en, this message translates to:
  /// **'Set 2FA'**
  String get set_2fa;

  /// No description provided for @blockchain_info.
  ///
  /// In en, this message translates to:
  /// **'Blockchain info'**
  String get blockchain_info;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get good_morning;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get good_evening;

  /// No description provided for @good_night.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get good_night;

  /// No description provided for @good_day.
  ///
  /// In en, this message translates to:
  /// **'Good day'**
  String get good_day;

  /// No description provided for @funding_target.
  ///
  /// In en, this message translates to:
  /// **'Funding target'**
  String get funding_target;

  /// No description provided for @error_connect_wallet.
  ///
  /// In en, this message translates to:
  /// **'Please connect your wallet'**
  String get error_connect_wallet;

  /// No description provided for @fully_funded.
  ///
  /// In en, this message translates to:
  /// **'Fully funded'**
  String get fully_funded;

  /// No description provided for @social_accounts.
  ///
  /// In en, this message translates to:
  /// **'XDN TIP Bot'**
  String get social_accounts;

  /// No description provided for @join_discord.
  ///
  /// In en, this message translates to:
  /// **'Open Bot link'**
  String get join_discord;

  /// No description provided for @send_discord.
  ///
  /// In en, this message translates to:
  /// **'Send DM to bot with text below'**
  String get send_discord;

  /// No description provided for @socials_info.
  ///
  /// In en, this message translates to:
  /// **'Linking your account to XDN TIP Bot will enable to send and receive tips on social media'**
  String get socials_info;

  /// No description provided for @socials_info_add.
  ///
  /// In en, this message translates to:
  /// **'RocketBot.pro & Merge need to be linked to web'**
  String get socials_info_add;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink {number}'**
  String unlink(Object number);

  /// No description provided for @socials_popup.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get socials_popup;

  /// No description provided for @mn_your_mns.
  ///
  /// In en, this message translates to:
  /// **'Your masternodes'**
  String get mn_your_mns;

  /// No description provided for @all_mn.
  ///
  /// In en, this message translates to:
  /// **'Number of active {number} MNs'**
  String all_mn(Object number);

  /// No description provided for @mn_day_reward.
  ///
  /// In en, this message translates to:
  /// **'Daily reward of 1 active MN'**
  String get mn_day_reward;

  /// No description provided for @mn_average_payrate.
  ///
  /// In en, this message translates to:
  /// **'MN average payrate'**
  String get mn_average_payrate;

  /// No description provided for @mn_average_start.
  ///
  /// In en, this message translates to:
  /// **'Average time to start MN'**
  String get mn_average_start;

  /// No description provided for @mn_time_to_start.
  ///
  /// In en, this message translates to:
  /// **'Average time to get 1st reward'**
  String get mn_time_to_start;

  /// No description provided for @mn_lock.
  ///
  /// In en, this message translates to:
  /// **'Coins will be locked for 1 week'**
  String get mn_lock;

  /// No description provided for @mn_start.
  ///
  /// In en, this message translates to:
  /// **'Swipe to start MN'**
  String get mn_start;

  /// No description provided for @mn_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage your MNs'**
  String get mn_manage;

  /// No description provided for @mn_reward.
  ///
  /// In en, this message translates to:
  /// **'Available reward'**
  String get mn_reward;

  /// No description provided for @mn_collateral.
  ///
  /// In en, this message translates to:
  /// **'Cost of 1 MN'**
  String get mn_collateral;

  /// No description provided for @mn_uncofirmed.
  ///
  /// In en, this message translates to:
  /// **'Pending Masternodes'**
  String get mn_uncofirmed;

  /// No description provided for @mn_roi.
  ///
  /// In en, this message translates to:
  /// **'Annual ROI'**
  String get mn_roi;

  /// No description provided for @mn_free.
  ///
  /// In en, this message translates to:
  /// **'Available MN nodes to start'**
  String get mn_free;

  /// No description provided for @settings_socials.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get settings_socials;

  /// No description provided for @mn_withdraw_box.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to withdraw MN #{number}?'**
  String mn_withdraw_box(Object number);

  /// No description provided for @mn_coins_month.
  ///
  /// In en, this message translates to:
  /// **'Coins earned this month'**
  String get mn_coins_month;

  /// No description provided for @mn_coins_year.
  ///
  /// In en, this message translates to:
  /// **'Coins earned this year'**
  String get mn_coins_year;

  /// No description provided for @mn_withdraw_reward.
  ///
  /// In en, this message translates to:
  /// **'Withdraw reward'**
  String get mn_withdraw_reward;

  /// No description provided for @st_adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust staking balance'**
  String get st_adjust;

  /// No description provided for @st_amount.
  ///
  /// In en, this message translates to:
  /// **'Subtract amount'**
  String get st_amount;

  /// No description provided for @set_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get set_privacy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bs',
        'cs',
        'de',
        'en',
        'es',
        'fi',
        'hi',
        'hr',
        'ja',
        'nl',
        'pa',
        'ru',
        'sr',
        'uk'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsSrCyrl();
          case 'Latn':
            return AppLocalizationsSrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'pa':
      return AppLocalizationsPa();
    case 'ru':
      return AppLocalizationsRu();
    case 'sr':
      return AppLocalizationsSr();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
