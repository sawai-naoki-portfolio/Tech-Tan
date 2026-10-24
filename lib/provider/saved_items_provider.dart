import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/saved_items_notifier.dart';

final savedItemsProvider =
    NotifierProvider<SavedItemsNotifier, List<String>>(
  SavedItemsNotifier.new,
);
