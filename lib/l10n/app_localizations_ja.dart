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

  @override
  String get products => '商品';

  @override
  String get latestPrice => '最新';

  @override
  String get lowestPrice => '最安';

  @override
  String get volume => '内容量';

  @override
  String get volumeUnit => '単位';

  @override
  String get shopMemo => 'メモ';

  @override
  String get shopEvents => 'イベント';

  @override
  String get addEvent => 'イベント追加';

  @override
  String get editEvent => 'イベント編集';

  @override
  String get recurring => '定期';

  @override
  String get oneTime => '単発';

  @override
  String get dayOfWeek => '曜日';

  @override
  String get dayOfMonth => '日付';

  @override
  String get priceCalculator => '価格換算';

  @override
  String get calculatePrice => '計算';

  @override
  String get viewHistory => '履歴を見る';

  @override
  String get selectImageSource => '画像の取得元を選択';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get eventTitle => 'イベント名';

  @override
  String get eventDescription => '説明';

  @override
  String get unitPrice => '単価';

  @override
  String get monday => '月曜日';

  @override
  String get tuesday => '火曜日';

  @override
  String get wednesday => '水曜日';

  @override
  String get thursday => '木曜日';

  @override
  String get friday => '金曜日';

  @override
  String get saturday => '土曜日';

  @override
  String get sunday => '日曜日';

  @override
  String get shopDetail => '店舗詳細';

  @override
  String get editShop => '店舗編集';

  @override
  String get deleteShop => '店舗削除';

  @override
  String get deleteEvent => 'イベント削除';

  @override
  String get noEvents => 'イベントはまだありません。';

  @override
  String volumeLabel(String volume, String unit) {
    return '$volume $unit';
  }

  @override
  String calculatedPrice(String price) {
    return '≈ ¥$price';
  }

  @override
  String get inputQuantity => '数量を入力';

  @override
  String get gram => 'g';

  @override
  String get milliliter => 'ml';

  @override
  String get liter => 'L';

  @override
  String get piece => '個';

  @override
  String get kilogram => 'kg';

  @override
  String get deleteConfirm => '削除';

  @override
  String get editProduct => '商品編集';

  @override
  String get categoryManagement => 'カテゴリ管理';

  @override
  String get noShopsFound => '店舗がまだありません。';

  @override
  String get at => '：';
}
