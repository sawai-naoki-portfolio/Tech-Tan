import 'package:flutter/cupertino.dart';

/// ---------------------------------------------------------------------------
/// BuildContext の拡張: 各種サイズ（パディング、アイコン、フォントサイズ等）を返す
/// ---------------------------------------------------------------------------
extension ResponsiveSizes on BuildContext {
  /// 現在の画面サイズ（幅×高さ）を返す
  Size get screenSize => MediaQuery.of(this).size;

  // 以下、画面サイズに応じた相対的なパディング値
  double get paddingExtraSmall => screenSize.width * 0.01;

  double get paddingSmall => screenSize.width * 0.02;

  double get paddingMedium => screenSize.width * 0.04;

  double get paddingLarge => screenSize.width * 0.06;

  double get paddingExtraLarge => screenSize.width * 0.08;

  // ボタンサイズ
  double get buttonHeight => screenSize.height * 0.07;

  double get buttonWidth => screenSize.width * 0.8;

  // アイコンサイズ
  double get iconSizeSmall => screenSize.width * 0.05;

  double get iconSizeMedium => screenSize.width * 0.07;

  double get iconSizeLarge => screenSize.width * 0.09;

  // テキストフィールド高さ
  double get textFieldHeight => screenSize.height * 0.06;

  // フォントサイズ
  double get fontSizeExtraSmall => screenSize.width * 0.03;

  double get fontSizeSmall => screenSize.width * 0.035;

  double get fontSizeMedium => screenSize.width * 0.04;

  double get fontSizeLarge => screenSize.width * 0.045;

  double get fontSizeExtraLarge => screenSize.width * 0.05;

  // SizedBox 用のスペースウィジェット（垂直方向）
  SizedBox get verticalSpaceExtraSmall =>
      SizedBox(height: screenSize.height * 0.01);

  SizedBox get verticalSpaceSmall => SizedBox(height: screenSize.height * 0.02);

  SizedBox get verticalSpaceMedium =>
      SizedBox(height: screenSize.height * 0.03);

  SizedBox get verticalSpaceLarge => SizedBox(height: screenSize.height * 0.05);

  // SizedBox 用のスペースウィジェット（水平方向）
  SizedBox get horizontalSpaceExtraSmall =>
      SizedBox(width: screenSize.width * 0.01);

  SizedBox get horizontalSpaceSmall => SizedBox(width: screenSize.width * 0.02);

  SizedBox get horizontalSpaceMedium =>
      SizedBox(width: screenSize.width * 0.03);

  SizedBox get horizontalSpaceLarge => SizedBox(width: screenSize.width * 0.05);

  // Divider 用のサイズ・太さ
  double get dividerHeightExtraSmall => screenSize.height * 0.01;

  double get dividerHeightSmall => screenSize.height * 0.015;

  double get dividerHeightMedium => screenSize.height * 0.02;

  double get dividerHeightLarge => screenSize.height * 0.025;

  double get dividerThickness => screenSize.width * 0.003;
}
