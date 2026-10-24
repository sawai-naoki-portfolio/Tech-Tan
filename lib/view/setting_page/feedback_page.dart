import '../../utility/responsive_sizes.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  // Google Form の公開URLをここに設定してください。
  final String feedbackUrl = 'https://forms.gle/uF48zD3zLPVNuyU1A';

  Future<void> _launchFeedbackForm(BuildContext context) async {
    final Uri url = Uri.parse(feedbackUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("フィードバックフォームを開けませんでした")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("フィードバック"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.paddingSmall),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: EdgeInsets.all(context.paddingSmall),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ご意見・ご要望",
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "アプリに関するご意見や改善点、その他何でもお知らせください。\nフィードバックは今後の改善に役立てさせていただきます。",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _launchFeedbackForm(context),
                    icon: const Icon(Icons.send),
                    label: const Text("フィードバックを送る"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
