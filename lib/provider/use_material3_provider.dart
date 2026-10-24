import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/material3_notifier.dart';

/// Material 3 の利用状態を管理する Provider
final useMaterial3Provider = NotifierProvider<Material3Notifier, bool>(
  Material3Notifier.new,
);
