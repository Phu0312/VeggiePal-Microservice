import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/common_widgets.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/ai_nutrition/data/chat_repository.dart';
import 'features/ai_nutrition/presentation/chat_controller.dart';
import 'features/auth/data/auth_models.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/home/data/home_repository.dart';
import 'features/menu_planner/data/health_sync.dart';
import 'features/menu_planner/data/menu_repository.dart';
import 'features/notifications/notification_controller.dart';
import 'features/places/data/places_repository.dart';
import 'features/profile/data/profile_repository.dart';
import 'navigation/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thiếu .env vẫn chạy được (dùng giá trị mặc định trong Endpoints).
  await dotenv.load(isOptional: true);
  // Khôi phục phiên đăng nhập đã lưu (token hết hạn thì bị bỏ) trước khi dựng giao diện.
  final store = SessionStore();
  runApp(VeggiePalApp(store: store, initialSession: await store.load()));
}

/// Dùng để hiện popup từ ngoài cây widget (vd: báo phiên đăng nhập hết hạn).
final navigatorKey = GlobalKey<NavigatorState>();

class VeggiePalApp extends StatelessWidget {
  final SessionStore? store;
  final AuthSession? initialSession;
  const VeggiePalApp({super.key, this.store, this.initialSession});

  void _onSessionExpired() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showErrorDialog(ctx, 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để tiếp tục.',
        title: 'Hết phiên đăng nhập');
  }

  @override
  Widget build(BuildContext context) {
    // Một ApiClient duy nhất dùng chung: AuthController ghi JWT vào đó,
    // mọi repository đọc lại nên request tự có/không có Bearer token theo đăng nhập.
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthRepository>(update: (_, api, _) => AuthRepository(api)),
        ProxyProvider<ApiClient, HomeRepository>(update: (_, api, _) => HomeRepository(api)),
        ProxyProvider<ApiClient, PlacesRepository>(update: (_, api, _) => PlacesRepository(api)),
        ProxyProvider<ApiClient, MenuRepository>(update: (_, api, _) => MenuRepository(api)),
        ProxyProvider<ApiClient, AdminRepository>(update: (_, api, _) => AdminRepository(api)),
        ProxyProvider<ApiClient, ProfileRepository>(update: (_, api, _) => ProfileRepository(api)),
        ProxyProvider<ApiClient, ChatRepository>(update: (_, api, _) => ChatRepository(api)),
        ChangeNotifierProvider<AuthController>(
            create: (c) => AuthController(
                c.read<ApiClient>(), c.read<AuthRepository>(), store ?? SessionStore(),
                initial: initialSession, onSessionExpired: _onSessionExpired)),
        ChangeNotifierProvider<ChatController>(
            create: (c) => ChatController(c.read<ChatRepository>())),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
        ChangeNotifierProvider<HealthSync>(create: (_) => HealthSync()),
        ChangeNotifierProxyProvider<AuthController, NotificationController>(
          create: (c) => NotificationController(c.read<HomeRepository>()),
          update: (_, auth, ctrl) => ctrl!..bindUser(auth.user?.id),
        ),
      ],
      child: Consumer2<ThemeController, AuthController>(
        builder: (_, theme, auth, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          // Admin vào app quản trị riêng; khách và thành viên dùng app người dùng.
          home: auth.isAdmin ? const AdminDashboardScreen() : const MainNavigationScreen(),
        ),
      ),
    );
  }
}
