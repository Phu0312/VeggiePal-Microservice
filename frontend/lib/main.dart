import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/ai_nutrition/data/chat_repository.dart';
import 'features/ai_nutrition/presentation/chat_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/home/data/home_repository.dart';
import 'features/menu_planner/data/menu_repository.dart';
import 'features/places/data/places_repository.dart';
import 'navigation/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thiếu .env vẫn chạy được (dùng giá trị mặc định trong Endpoints).
  await dotenv.load(isOptional: true);
  runApp(const VeggiePalApp());
}

class VeggiePalApp extends StatelessWidget {
  const VeggiePalApp({super.key});

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
        ProxyProvider<ApiClient, ChatRepository>(update: (_, api, _) => ChatRepository(api)),
        ChangeNotifierProvider<AuthController>(
            create: (c) => AuthController(c.read<ApiClient>(), c.read<AuthRepository>())),
        ChangeNotifierProvider<ChatController>(
            create: (c) => ChatController(c.read<ChatRepository>())),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
