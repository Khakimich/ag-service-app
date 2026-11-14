import '../features/booking/screens/quick_booking_screen.dart'; // AG_QUICKBOOK1
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/max_connect_screen.dart';
import '../features/booking/screens/anniversary_welcome_screen.dart';
import '../features/booking/screens/about_service_screen.dart';
import '../features/booking/screens/booking_confirmation_screen.dart';
import '../features/booking/screens/car_selection_screen.dart';
import '../features/booking/screens/booking_success_screen.dart';
import '../features/booking/screens/datetime_selection_screen.dart';
import '../features/booking/screens/home_screen.dart';
import '../features/booking/screens/news_screen.dart';
import '../features/booking/screens/news_detail_screen.dart';
import '../features/booking/screens/my_bookings_screen.dart';
import '../features/booking/screens/repair_status_screen.dart';
import '../features/booking/screens/profile_screen.dart';
import '../features/booking/screens/security_screen.dart';
import '../features/booking/screens/personal_data_screen.dart';
import '../features/booking/screens/max_connection_screen.dart';
import '../features/booking/screens/reschedule_screen.dart';
import '../features/booking/screens/service_detail_screen.dart';
import '../features/booking/screens/services_list_screen.dart';
import '../features/booking/screens/specialist_selection_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/chats_screen.dart';
import '../features/my_cars/screens/my_cars_screen.dart';
import '../features/recommendations/screens/recommendations_screen.dart';
import '../features/booking/screens/notifications_screen.dart';
import '../features/booking/screens/referral_screen.dart';
import '../models/booking_with_details.dart';
import '../models/ag_news_item.dart';
import '../models/chat_conversation.dart';
import 'main_shell.dart';
import '../features/park/park_join_screen.dart'; // AG_PARK1
import '../features/services_hub/services_hub.dart'; // AG_SVCHUB1

GoRouter createAppRouter(AuthProvider authProvider) => GoRouter(
  initialLocation: '/',
  refreshListenable: authProvider,
  redirect: (context, state) {
    final path = state.uri.path;

    final requiresAuth =
        path == '/booking/start' ||
        path == '/booking/specialist' ||
        path == '/booking/datetime' ||
        path == '/booking/car' ||
        path == '/booking/confirm' ||
        path == '/booking/success' ||
        path == '/booking/reschedule' ||
        path == '/recommendations' ||
        path == '/evacuator' || // AG_SVCHUB1: заявка уходит в чат — нужен вход
        path == '/body-repair';

    if (requiresAuth && !authProvider.isLoggedIn) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (_, __) => const AnniversaryWelcomeScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/services',
          builder: (context, state) {
            final search = state.uri.queryParameters['search'];
            return ServicesListScreen(initialSearch: search);
          },
          routes: [
            GoRoute(
              path: ':id',
              builder:
                  (_, state) => ServiceDetailScreen(
                    serviceId: state.pathParameters['id']!,
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/bookings',
          builder: (_, __) => const MyBookingsScreen(),
        ),
        GoRoute(
          path: '/repair',
          builder: (_, __) => const RepairStatusScreen(),
        ),
        GoRoute(
          path: '/recommendations',
          builder: (_, __) => const RecommendationsScreen(),
        ),
        GoRoute(
          path: '/news',
          builder: (_, __) => const NewsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder:
                  (_, state) =>
                      state.extra is AgNewsItem ? NewsDetailScreen(item: state.extra as AgNewsItem) : const NewsScreen(), // AG_FIX3
            ),
          ],
        ),
        GoRoute(path: '/about', builder: (_, __) => const AboutServiceScreen()),
        GoRoute(path: '/park', builder: (_, __) => const ParkJoinScreen()), // AG_PARK1
        GoRoute(path: '/evacuator', builder: (_, __) => const EvacuatorScreen()), // AG_SVCHUB1
        GoRoute(path: '/body-repair', builder: (_, __) => const BodyRepairScreen()), // AG_SVCHUB1
        GoRoute(path: '/chats', builder: (_, __) => const ChatsScreen()),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'personal',
              builder: (_, __) => const PersonalDataScreen(),
            ),
            GoRoute(
              path: 'security',
              builder: (_, __) => const SecurityScreen(),
            ),
            GoRoute(path: 'my-cars', builder: (_, __) => const MyCarsScreen()),
            GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(
              path: 'referrals',
              builder: (_, __) => const ReferralScreen(),
            ),
            GoRoute(
              path: 'max',
              builder: (_, __) => const MaxConnectionScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/max', builder: (_, __) => const MaxConnectScreen()),
    GoRoute(
      path: '/chats/:id',
      builder:
          (_, state) => ChatScreen(
            conversationId: state.pathParameters['id']!,
            conversation: state.extra is ChatConversation ? state.extra as ChatConversation : null, // AG_FIX3
          ),
    ),
    GoRoute(
      path: '/booking/start', // AG_QUICKBOOK1
      builder: (_, __) => const QuickBookingScreen(),
    ),
    GoRoute(
      path: '/booking/specialist',
      builder: (_, __) => const SpecialistSelectionScreen(),
    ),
    GoRoute(
      path: '/booking/datetime',
      builder: (_, __) => const DateTimeSelectionScreen(),
    ),
    GoRoute(
      path: '/booking/car',
      builder: (_, __) => const CarSelectionScreen(),
    ),
    GoRoute(
      path: '/booking/confirm',
      builder: (_, __) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: '/booking/success',
      builder: (_, __) => const BookingSuccessScreen(),
    ),
    GoRoute(
      path: '/booking/reschedule',
      builder:
          (_, state) =>
              state.extra is BookingWithDetails ? RescheduleScreen(booking: state.extra as BookingWithDetails) : const MyBookingsScreen(), // AG_FIX3
    ),
  ],
);
