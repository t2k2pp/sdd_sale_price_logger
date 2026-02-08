// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '底値ロガー';

  @override
  String get homeTitle => '底値ロガー';

  @override
  String get recentProducts => '最近の商品';

  @override
  String get noProductsYet => '商品がまだありません。';

  @override
  String get noPriceHistory => '価格履歴がまだありません。';

  @override
  String get addPrice => '価格を追加';

  @override
  String get settings => '設定';

  @override
  String get categories => 'カテゴリ';

  @override
  String get shops => '店舗';

  @override
  String get addCategory => 'カテゴリ追加';

  @override
  String get addShop => '店舗追加';

  @override
  String get name => '名前';

  @override
  String get cancel => 'キャンセル';

  @override
  String get add => '追加';

  @override
  String get save => '保存';

  @override
  String get productName => '商品名';

  @override
  String get category => 'カテゴリ';

  @override
  String get shop => '店舗';

  @override
  String get price => '価格';

  @override
  String get date => '日付';

  @override
  String get photo => '写真';

  @override
  String get newProduct => '新規商品';

  @override
  String get history => '履歴';

  @override
  String get bestPrice => '最安値';

  @override
  String get taxIncluded => '税込';

  @override
  String get taxExcluded => '税抜';

  @override
  String get taxRate => '税率';

  @override
  String get taxIncludedLabel => '税込';

  @override
  String get taxExcludedLabel => '税抜';

  @override
  String get emoji => '絵文字 (任意)';

  @override
  String error(String message) {
    return 'エラー: $message';
  }

  @override
  String get searchHint => '商品やカテゴリを検索...';

  @override
  String get noProductsFound => '商品が見つかりません。';
}
