import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_design/core/firestore_chat_service.dart';
import 'package:card_design/core/network.dart';
import 'package:card_design/core/push_notification_service.dart';
import 'package:card_design/viewmodel/login_viewmodel.dart';
import 'package:card_design/viewmodel/register_viewmodel.dart';

import 'package:card_design/viewmodel/create_post_viewmodel.dart';
import 'package:card_design/viewmodel/chat_viewmodel.dart';
import 'package:card_design/viewmodel/notification_viewmodel.dart';
import 'package:card_design/viewmodel/post_viewmodel.dart';
import 'package:card_design/viewmodel/profile_viewmodel.dart';
import 'package:card_design/viewmodel/story_viewmodel.dart';

import 'package:card_design/view/home_view.dart';
import 'package:card_design/view/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirestoreChatService.init();
  await PushNotificationService.init();

  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => CreatePostViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => PostViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => StoryViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<LoginViewModel>().isLoggedIn;

    return MaterialApp(
      title: 'ZieSocial',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0095F6),
          secondary: Color(0xFF0095F6),
          surface: Colors.black,
        ),
      ),
      home: isLoggedIn ? const HomeView() : const LoginView(),
    );
  }
}