// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'DigitalNote';

  @override
  String get appTitle => 'DigitalNote';

  @override
  String get description => 'DigitalNote アプリ';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get save => '保存';

  @override
  String get delete => '消去';

  @override
  String get user_email => 'ユーザー名/Ｅメール';

  @override
  String get username => 'ユーザー名';

  @override
  String get name => '名前';

  @override
  String get password => 'パスワード';

  @override
  String get conf_password => 'パスワード確認';

  @override
  String get email => 'Ｅメール';

  @override
  String get first_last_name => '名前(ファーストネーム・ラストネーム)';

  @override
  String get login_can_use => 'その名前をご利用いただけます';

  @override
  String get login => 'ログイン';

  @override
  String get warning => '警告';

  @override
  String get error => 'エラー';

  @override
  String get invalid => '無効';

  @override
  String get notice_warn => 'お知らせ';

  @override
  String get fields_cant_empty => 'フィールドを埋めてください';

  @override
  String get error_occur => 'エラー';

  @override
  String get sign_up => '登録';

  @override
  String get log_in => 'ログイン';

  @override
  String get registration => '登録';

  @override
  String get wendy_first => 'ご利用ありがとうございます';

  @override
  String get wendy_second => '同じ登録情報をお使いできます';

  @override
  String get wendy_third => 'アーティスト、投資家、キュレーターのためのプラットフォーム';

  @override
  String get wendy_fourth => 'そして好奇心旺盛な人たち';

  @override
  String get wendy_fifth => 'あなたのように';

  @override
  String get username_invalid => '無効なユーザー名です';

  @override
  String get username_invalid_message => 'ユーザー名は4文字以上でお願いします';

  @override
  String get password_invalid => '無効なパスワードです';

  @override
  String get password_invalid_message => 'パスワードは4文字以上でなければなりません';

  @override
  String get email_invalid => '無効なＥメールです';

  @override
  String get email_invalid_message => '正しいメールアドレスを入力してください';

  @override
  String get name_invalid => 'この名前は無効です';

  @override
  String get name_invalid_message => '6文字以上でお願いします';

  @override
  String get password_mismatch => 'パスワードが一致しません';

  @override
  String get password_mismatch_message => 'パスワードが同一であることを確認してください';

  @override
  String get amount => '数量';

  @override
  String get amount_empty => '数を入力してください';

  @override
  String get konj_addr_invalid => '無効なアドレスです';

  @override
  String get succ => '成功しました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get alert => '警告';

  @override
  String get close => '閉じる';

  @override
  String get to => '送金先';

  @override
  String get available => '使用可能な量';

  @override
  String get immature => '熟成中';

  @override
  String get receive => '受け取り';

  @override
  String get send => '送金';

  @override
  String get send_to => '送金先';

  @override
  String get send_wait => '処理中';

  @override
  String get tip => 'チップ';

  @override
  String get rename => '名前の変更';

  @override
  String get new_name => '新しい名前';

  @override
  String get date => '日付';

  @override
  String get reg_succ_message => 'ログイン成功';

  @override
  String get usr_exists_err => 'そのユーザー名は使われています';

  @override
  String get usr_exists_err_message => '登録には他のユーザー名を使用するかすでに登録済みの可能性があります';

  @override
  String get contact => '連絡を取る';

  @override
  String get contacts => '連絡先';

  @override
  String get contact_add => '連絡先を追加';

  @override
  String get search_contact => '連絡先を検索';

  @override
  String get share => 'シェアする';

  @override
  String get address => 'アドレス';

  @override
  String get camera_perm => 'アプリにカメラの撮影を許可してください';

  @override
  String get storage_perm => 'アプリにストレージへのアクセスを許可してください';

  @override
  String get contact_added => '連絡先が追加されました';

  @override
  String get contact_del => '本当にこの連絡先を消去しても構いませんか';

  @override
  String get messages => 'メッセージ';

  @override
  String get message_new => '新着メッセージ';

  @override
  String get message_search => 'メッセージ検索';

  @override
  String get message_recipient_missing => '送信先が存在しません';

  @override
  String get message_missing => 'メッセージが存在しません';

  @override
  String get message_choose_recipient => '送信先を選択してください';

  @override
  String get message_not_warning => 'メッセージの送受信を適切に行うため、通知をオンにしてください';

  @override
  String get message_tipped => 'チップを送りました';

  @override
  String get message_reply_to => '返信先';

  @override
  String get message_copy => 'クリップボードにメッセージの内容をコピーしました';

  @override
  String get pin_enter => 'PINを入力してください';

  @override
  String get pin_message =>
      'このアプリはPINで保護されており、続行するにはコードを入力する必要があります。また、アプリの設定によりPINを無効化することができます。';

  @override
  String get set_pin_removed => 'PINが消去されました';

  @override
  String get set_pin_not_match => 'PINが設定されたパスコードと異なります。もう一度やり直してください。';

  @override
  String get set_download => 'ファイルがダウンロードされました';

  @override
  String get set_csv_no_app => 'CSVファイルを開くためのアプリが存在しません';

  @override
  String get set_headline => '設定';

  @override
  String get set_pin => '設定するPIN';

  @override
  String get set_pin_confirm => 'PINの確認';

  @override
  String get set_remove_pin => 'PINの消去';

  @override
  String get set_nickname => 'ニックネームの変更';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get set_password => 'パスワードの変更';

  @override
  String get set_priv_key => 'ウォレットの秘密鍵を取得する';

  @override
  String get set_csv => 'トランザクションをCSVでダウンロード';

  @override
  String get set_about => 'このアプリについて';

  @override
  String get set_log_out => 'ログアウト';

  @override
  String get set_pass_error => 'パスワードが正しくありません';

  @override
  String get set_priv_error => '秘密鍵の取得ができません';

  @override
  String get st_locked_coins => 'ロックされたコイン';

  @override
  String get st_coins_staked => 'ステークされたコイン';

  @override
  String get st_insufficient => '十分な量の資金がありません';

  @override
  String get st_in_fees => '現在のネットワーク手数料を支払うための必要な資金が足りません';

  @override
  String get st_cannot_stake => '今はステークできません';

  @override
  String get st_not_balance => '十分なコインがないです。少ない量で再度試してみてください。';

  @override
  String get st_24h_timeout => 'コインは現在ロックされています。最後のステークから少なくとも24時間待ってください。';

  @override
  String get st_headline => 'ステーキング';

  @override
  String get st_coins_today => '本日獲得したコイン';

  @override
  String get st_coins_week => '今月獲得したコイン';

  @override
  String get st_live => 'ライブ';

  @override
  String get st_reward => '報酬';

  @override
  String get st_total_coins => 'プール内のコイン総量';

  @override
  String get st_contribution => 'プール総量に対するあなたの貢献度';

  @override
  String get st_estimated => '1日に得られる期待報酬';

  @override
  String get st_24h_lock => 'コインは最後の入金から24時間ロックされます';

  @override
  String get st_enter_amount => 'ステークのための金額を入力してください';

  @override
  String get st_time_until_unlock => 'コインがアンロックされるまでの時間';

  @override
  String get st_contains => '賭け金には、賭け金と報酬の両方が含まれます。';

  @override
  String get st_withdraw_reward => 'ステーキングから報酬を出金する';

  @override
  String get st_withdraw_all => 'ステーキングからすべてのコインを出金する';

  @override
  String get wl_refreshing => 'データのリフレッシュ';

  @override
  String get wl_balance => '残高';

  @override
  String get dl_remove_pin => 'PINを取り除く';

  @override
  String get dl_enter_pin => 'PINの入力';

  @override
  String get dl_send_confirm => 'トランザクションを実行してもよいですか';

  @override
  String get dl_delete_contact => '本当にこのコンタクトを消去しますか';

  @override
  String get dl_log_out => 'ログアウトしてもよろしいですか';

  @override
  String get dl_not_enough_coins => 'コインが十分にありません';

  @override
  String get dl_wait => 'お待ちください';

  @override
  String get dl_credentials => '認証情報を入力してください';

  @override
  String get dl_edit_name => '名前の編集';

  @override
  String get dl_new_contact => '新しいコンタクトの追加';

  @override
  String get dl_user_exist => 'このユーザーはすでに登録されています';

  @override
  String get dl_save_contact => '登録リストに保存する';

  @override
  String get dl_enter_current_pass => '現在のパスワードを入力してください';

  @override
  String get dl_enter_pass => 'パスワードの入力';

  @override
  String get dl_new_enter_pass => '新しいパスワードの入力';

  @override
  String get dl_conf_new_pass => '新しいパスワードの確認';

  @override
  String get dl_pass_mismatch => 'パスワードが一致しません';

  @override
  String get dl_tx_detail => 'トランザクションの詳細';

  @override
  String get dl_explorer => 'エクスプローラーで開く';

  @override
  String get dl_tx_copy => 'トランザクションIDがクリップボードにコピーされました';

  @override
  String get dl_konj_addr => 'あなたのKONJアドレス';

  @override
  String get dl_share => 'タップしてコピーし、長押しで共有します';

  @override
  String get dl_qr_copy => 'QRコードがクリップボードにコピーされました';

  @override
  String get dl_konj_priv => 'KONJウォレットのプライベートキー';

  @override
  String get dl_priv_copy => 'プライベートキーがクリップボードにコピーされました';

  @override
  String get dl_select_action => 'アクションの選択';

  @override
  String get dl_send_message => 'メッセージを送信';

  @override
  String get dl_send_konj => 'KONJの送信先';

  @override
  String get menu_wallet => 'ウォレット';

  @override
  String get rec_tx => '最近のトランザクション';

  @override
  String get register => '登録';

  @override
  String get register_button => '登録する';

  @override
  String get e_mail => 'Eメール';

  @override
  String get forgot_pass => 'パスワードを忘れましたか？';

  @override
  String get or => 'もしくは';

  @override
  String get sign_in => 'サインイン';

  @override
  String get portfolio => 'ポートフォリオ';

  @override
  String get about => '関連';

  @override
  String get sentTo => '送信先';

  @override
  String get sent => '送信';

  @override
  String get deposit => '入金';

  @override
  String get txid => 'トランザクションID';

  @override
  String get all => '全額';

  @override
  String get onew => '1週間';

  @override
  String get oned => '1日';

  @override
  String get twelveh => '12時間';

  @override
  String get no_tx => 'トランザクションは存在しません';

  @override
  String get copy => 'コピー';

  @override
  String get explorer => 'エクスプローラー';

  @override
  String get txdet => 'トランザクション詳細';

  @override
  String get txcopy => 'トランザクションIDをクリップボードにコピーしました';

  @override
  String get confirmations => '確認';

  @override
  String get history_popup => '履歴';

  @override
  String get settings_popup => '設定';

  @override
  String get about_popup => '関連';

  @override
  String get choose_coin => 'コインを選択';

  @override
  String get or_scan_qr => 'あるいはQRコインより受け取る';

  @override
  String get or_send_scan_qr => 'もしくはQRコインを使って送る';

  @override
  String get graph_no_data => '申し訳ございません、グラフのデータを取得できませんでした。';

  @override
  String get settings_screen => '設定';

  @override
  String get settings_main => 'メイン設定';

  @override
  String get settings_privacy => 'プライバシー設定';

  @override
  String get password_forgot => 'パスワードを忘れてしまった';

  @override
  String get user_not_exists => 'ユーザーは存在しません';

  @override
  String get change_language => '言語の選択';

  @override
  String get delete_acc => 'アカウントの削除';

  @override
  String get voting => '投票';

  @override
  String get connect_wallet => 'ウォレットに接続';

  @override
  String get wallet_connected => 'ウォレットに接続しました';

  @override
  String get amount_to_reach => '目標金額';

  @override
  String get amount_reached => '達成金額';

  @override
  String get date_ending => '終了日';

  @override
  String get bnb_balance => 'BNB残高';

  @override
  String get gas => 'Gas';

  @override
  String get st_less => '表示を減らす';

  @override
  String get st_more => '表示を増やす';

  @override
  String get vot_succ => '投票に成功しました';

  @override
  String get vot_fail => '投票に失敗しました';

  @override
  String get no_contest => '現在、コンテストはありません';

  @override
  String get amount_of_votes => '投票数';

  @override
  String get amount_of_votes_user => '投票数';

  @override
  String get security => 'セキュリティ';

  @override
  String get remove_2fa => '2FAを削除';

  @override
  String get set_2fa => '2FAを設定';

  @override
  String get blockchain_info => 'ブロックチェーン情報';

  @override
  String get good_morning => 'おはようございます';

  @override
  String get good_afternoon => 'こんにちは';

  @override
  String get good_evening => 'こんばんは';

  @override
  String get good_night => 'おやすみなさい';

  @override
  String get good_day => 'こんにちは';

  @override
  String get funding_target => '目標金額';

  @override
  String get error_connect_wallet => 'ウォレットに接続できませんでした';

  @override
  String get fully_funded => '完全に資金調達されました';

  @override
  String get social_accounts => 'XDN TIP Bot';

  @override
  String get join_discord => 'Discordに参加';

  @override
  String get send_discord => 'DiscordにDMを送信';

  @override
  String get socials_info => 'アカウントをXDN TIP Botにリンクすると、ソーシャルメディアでチップを送受信できます';

  @override
  String get socials_info_add => 'RocketBot.pro & Mergeはウェブにリンクする必要があります';

  @override
  String unlink(Object number) {
    return 'アカウントをリンク解除 $number';
  }

  @override
  String get socials_popup => 'ソーシャルメディア';

  @override
  String get mn_your_mns => 'あなたのマスターノード';

  @override
  String all_mn(Object number) {
    return 'アクティブな $number MNの数';
  }

  @override
  String get mn_day_reward => '1つのアクティブなMNの日報酬';

  @override
  String get mn_average_payrate => 'MNの平均報酬';

  @override
  String get mn_average_start => 'MNの平均起動時間';

  @override
  String get mn_time_to_start => 'MNの1つの報酬を得るまでの平均時間';

  @override
  String get mn_lock => 'コインは1週間ロックされます';

  @override
  String get mn_start => 'MNを起動';

  @override
  String get mn_manage => 'MNを管理';

  @override
  String get mn_reward => '報酬';

  @override
  String get mn_collateral => 'MNのコスト';

  @override
  String get mn_uncofirmed => '未確認のマスターノード';

  @override
  String get mn_roi => '年間ROI';

  @override
  String get mn_free => '利用可能なMNノード';

  @override
  String get settings_socials => 'ソーシャルメディア';

  @override
  String mn_withdraw_box(Object number) {
    return 'MN #$numberを引き出しますか？';
  }

  @override
  String get mn_coins_month => '今月の収益';

  @override
  String get mn_coins_year => '今年の収益';

  @override
  String get mn_withdraw_reward => '報酬を引き出す';

  @override
  String get st_adjust => 'Adjust staking balance';

  @override
  String get st_amount => 'Subtract amount';

  @override
  String get set_privacy => 'Privacy';
}
