import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'utils/device_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统 UI 样式
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // 设置首选方向
  final isTV = await DeviceUtils.isTV();
  await SystemChrome.setPreferredOrientations(
    isTV 
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
  );
  
  // 初始化应用配置
  await AppConfig.init();
  
  runApp(const MBoxApp());
}
