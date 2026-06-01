import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../presentation/features/auth/splash/splash_screen.dart';
import '../../presentation/features/auth/login/login_screen.dart';
import '../../presentation/features/auth/register/register_screen.dart';
import '../../presentation/features/auth/forgot_password/forgot_password_screen.dart';
import '../../presentation/features/onboarding/goal_selection_screen.dart';
import '../../presentation/features/onboarding/level_selection_screen.dart';
import '../../presentation/features/onboarding/placement_test_screen.dart';
import '../../presentation/features/onboarding/placement_result_screen.dart';
import '../../presentation/features/onboarding/daily_target_screen.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/features/stream/stream_screen.dart';
import '../../presentation/features/stream/word_of_day_detail_screen.dart';
import '../../presentation/features/stream/culture_trivia_detail_screen.dart';
import '../../presentation/features/talk/talk_screen.dart';
import '../../presentation/features/talk/chat_room_screen.dart';
import '../../presentation/features/talk/voice_call_screen.dart';
import '../../presentation/features/talk/video_call_screen.dart';
import '../../presentation/features/leaderboard/leaderboard_screen.dart';
import '../../presentation/features/profile/profile_screen.dart';
import '../../presentation/features/profile/achievements_screen.dart';
import '../../presentation/features/profile/settings_screen.dart';
import '../../presentation/features/profile/friend_profile_screen.dart';
import '../../presentation/features/learn/quiz/quiz_screen.dart';
import '../../presentation/features/learn/lesson_complete/lesson_complete_screen.dart';
import '../../presentation/features/learn/daily_quest/daily_quest_modal.dart';
import '../../presentation/common_widgets/bottom_nav_bar.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPath = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation.startsWith('/onboarding');

      if (!isLoggedIn && !isOnAuthPath && !isOnOnboarding) {
        return '/auth/login';
      }

      if (isLoggedIn && isOnAuthPath && state.matchedLocation != '/splash') {
        final uid = authState.valueOrNull!.uid;
        try {
          final ds = ref.read(firestoreDataSourceProvider);
          final user = await ds.getUser(uid);
          if (user != null && !user.onboardingCompleted) {
            return '/onboarding/goals';
          }
          return '/home';
        } catch (_) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (context, state) => const GoalSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/level',
        builder: (context, state) => const LevelSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/placement-test',
        builder: (context, state) => const PlacementTestScreen(),
      ),
      GoRoute(
        path: '/onboarding/placement-result',
        builder: (context, state) => const PlacementResultScreen(),
      ),
      GoRoute(
        path: '/onboarding/daily-target',
        builder: (context, state) => const DailyTargetScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'lesson/:unitId/:lessonId',
                pageBuilder: (context, state) => MaterialPage(
                  fullscreenDialog: true,
                  child: QuizScreen(
                    unitId: state.pathParameters['unitId']!,
                    lessonId: state.pathParameters['lessonId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'lesson-complete',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return LessonCompleteScreen(
                    earnedXp: extra?['earnedXp'] as int? ?? 0,
                    stars: extra?['stars'] as int? ?? 1,
                    correctCount: extra?['correctCount'] as int? ?? 0,
                    totalCount: extra?['totalCount'] as int? ?? 0,
                  );
                },
              ),
              GoRoute(
                path: 'daily-quest',
                builder: (context, state) => const DailyQuestModal(),
              ),
            ],
          ),
          GoRoute(
            path: '/stream',
            builder: (context, state) => const StreamScreen(),
            routes: [
              GoRoute(
                path: 'word-of-day/:wordId',
                builder: (context, state) => WordOfDayDetailScreen(
                  wordId: state.pathParameters['wordId']!,
                ),
              ),
              GoRoute(
                path: 'culture-trivia/:triviaId',
                builder: (context, state) => CultureTriviaDetailScreen(
                  triviaId: state.pathParameters['triviaId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/talk',
            builder: (context, state) => const TalkScreen(),
            routes: [
              GoRoute(
                path: 'chat/:partnerId',
                builder: (context, state) => ChatRoomScreen(
                  partnerId: state.pathParameters['partnerId']!,
                ),
              ),
              GoRoute(
                path: 'voice-call/:callId',
                pageBuilder: (context, state) => MaterialPage(
                  fullscreenDialog: true,
                  child: VoiceCallScreen(callId: state.pathParameters['callId']!),
                ),
              ),
              GoRoute(
                path: 'video-call/:callId',
                pageBuilder: (context, state) => MaterialPage(
                  fullscreenDialog: true,
                  child: VideoCallScreen(callId: state.pathParameters['callId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'friend/:userId',
                builder: (context, state) => FriendProfileScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
              GoRoute(
                path: 'achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});