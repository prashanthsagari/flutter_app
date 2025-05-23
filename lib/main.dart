import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'services/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const appId = '3VyDvQ4TPVroO2rErAIFbBNEdATxpTXpEgBYZYyp';
  const clientKey = 'qeu4YMyxw86S5wY7oq2h0izAVsXmWV45Xf3T58qQ';
  const serverUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(appId, serverUrl, clientKey: clientKey, autoSendSessionId: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

