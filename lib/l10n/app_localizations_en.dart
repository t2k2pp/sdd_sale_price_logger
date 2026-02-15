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

  @override
  String get searchHint => 'Search products or categories...';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get products => 'Products';

  @override
  String get latestPrice => 'Latest';

  @override
  String get lowestPrice => 'Lowest';

  @override
  String get volume => 'Volume';

  @override
  String get volumeUnit => 'Unit';

  @override
  String get shopMemo => 'Memo';

  @override
  String get shopEvents => 'Events';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get recurring => 'Recurring';

  @override
  String get oneTime => 'One-time';

  @override
  String get dayOfWeek => 'Day of Week';

  @override
  String get dayOfMonth => 'Day of Month';

  @override
  String get priceCalculator => 'Price Calculator';

  @override
  String get calculatePrice => 'Calculate';

  @override
  String get viewHistory => 'View History';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventDescription => 'Description';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get shopDetail => 'Shop Detail';

  @override
  String get editShop => 'Edit Shop';

  @override
  String get deleteShop => 'Delete Shop';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get noEvents => 'No events yet.';

  @override
  String volumeLabel(String volume, String unit) {
    return '$volume $unit';
  }

  @override
  String calculatedPrice(String price) {
    return '≈ ¥$price';
  }

  @override
  String get inputQuantity => 'Enter quantity';

  @override
  String get gram => 'g';

  @override
  String get milliliter => 'ml';

  @override
  String get liter => 'L';

  @override
  String get piece => 'pcs';

  @override
  String get kilogram => 'kg';

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get noShopsFound => 'No shops yet.';

  @override
  String get at => 'at';
}
