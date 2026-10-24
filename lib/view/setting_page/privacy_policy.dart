import '../../utility/responsive_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  late Future<String> _policyFuture;

  @override
  void initState() {
    super.initState();
    // assets/privacypolicy.txt からテキストを読み込む
    _policyFuture = rootBundle.loadString('assets/privacypolicy.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("プライバシーポリシー"),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("プライバシーポリシーの読み込みに失敗しました"));
          } else {
            return SingleChildScrollView(
              padding: EdgeInsets.all(context.paddingSmall),
              child: Text(
                snapshot.data!,
                style: TextStyle(fontSize: context.fontSizeMedium),
              ),
            );
          }
        },
      ),
    );
  }
}
