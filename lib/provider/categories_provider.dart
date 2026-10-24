import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/categories_notifier.dart';
import '../utility/category.dart';

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<Category>>(
    CategoriesNotifier.new);
