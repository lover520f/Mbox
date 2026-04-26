import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../provider/app_provider.dart';
import '../provider/config_provider.dart';
import 'home/leanback_home_screen.dart';
import 'home/mobile_home_screen.dart';
import '../../utils/device_utils.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTV = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceType();
  }

  Future<void> _checkDeviceType() async {
    _isTV = await DeviceUtils.isTV();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据设备类型加载不同的 UI
    if (_isTV) {
      return const LeanbackHomeScreen();
    } else {
      return const MobileHomeScreen();
    }
  }
}
