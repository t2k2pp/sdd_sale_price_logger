// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sales Price Logger';

  @override
  String get homeTitle => 'Sales Price Logger';

  @override
  String get recentProducts => 'Recent Products';

  @override
  String get noProductsYet => 'No products yet.';

  @override
  String get noPriceHistory => 'No price history yet.';

  @override
  String get addPrice => 'Add Price';

  @override
  String get settings => 'Settings';

  @override
  String get categories => 'Categories';

  @override
  String get shops => 'Shops';

  @override
  String get addCategory => 'Add Category';

  @override
  String get addShop => 'Add Shop';

  @override
  String get name => 'Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get productName => 'Product Name';

  @override
  String get category => 'Category';

  @override
  String get shop => 'Shop';

  @override
  String get price => 'Price';

  @override
  String get date => 'Date';

  @override
  String get photo => 'Photo';

  @override
  String get newProduct => 'New Product';

  @override
  String get history => 'History';

  @override
  String get bestPrice => 'Best Price';

  @override
  String get taxIncluded => 'Tax Included';

  @override
  String get taxExcluded => 'Tax Excluded';

  @override
  String get taxRate => 'Tax Rate';

  @override
  String get taxIncludedLabel => 'Tax In';

  @override
  String get taxExcludedLabel => 'Tax Ex';

  @override
  String get emoji => 'Emoji (Optional)';

  @override
  String error(String message) {
    return 'Error: $message';
  }
}
