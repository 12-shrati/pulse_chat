import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_chat/features/auth/presentation/screens/login_screen.dart';
import 'package:pulse_chat/features/auth/presentation/screens/register_screen.dart';
import 'package:pulse_chat/features/chat/presentation/screens/chat_screen.dart';
import 'package:pulse_chat/features/group/presentation/screens/group_chat_screen.dart';
import 'package:pulse_chat/features/group/presentation/screens/group_list_screen.dart';
import 'package:pulse_chat/features/home/presentation/screens/home_screen.dart';
import 'package:pulse_chat/features/splash/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final name = state.extra as String? ?? '';
          return ChatScreen(contactName: name);
        },
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupListScreen(),
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.extra as String? ?? '';
          return GroupChatScreen(groupId: groupId, groupName: groupName);
        },
      ),
    ],
  );
});
