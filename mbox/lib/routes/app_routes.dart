import 'package:get/get.dart';
import '../screens/home/home_screen.dart';
import '../screens/vod/vod_detail_screen.dart';
import '../screens/vod/vod_player_screen.dart';
import '../screens/live/live_screen.dart';
import '../screens/live/live_player_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String vodDetail = '/vod/detail';
  static const String vodPlayer = '/vod/player';
  static const String live = '/live';
  static const String livePlayer = '/live/player';
  static const String search = '/search';
  static const String settings = '/settings';

  static List<GetPage> routes = [
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: vodDetail, page: () => const VodDetailScreen()),
    GetPage(name: vodPlayer, page: () => const VodPlayerScreen()),
    GetPage(name: live, page: () => const LiveScreen()),
    GetPage(name: livePlayer, page: () => const LivePlayerScreen()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
  ];
}
