import 'package:get/get.dart';
import '../screens/main/main_screen.dart';
import '../screens/vod/vod_detail_screen.dart';
import '../screens/vod/vod_player_screen.dart';
import '../screens/live/live_screen.dart';
import '../screens/live/live_player_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String vodDetail = '/vod/detail';
  static const String vodPlayer = '/vod/player';
  static const String live = '/live';
  static const String livePlayer = '/live/player';

  static List<GetPage> routes = [
    GetPage(name: home, page: () => const MainScreen()),
    GetPage(
      name: vodDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return VodDetailScreen(
          vod: args?['vod'] as dynamic,
          siteId: args?['siteId'] as String? ?? '1',
        );
      },
    ),
    GetPage(name: vodPlayer, page: () => const VodPlayerScreen()),
    GetPage(name: live, page: () => const LiveScreen()),
    GetPage(name: livePlayer, page: () => const LivePlayerScreen()),
  ];
}
