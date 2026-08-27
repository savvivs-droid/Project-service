import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_gate.dart';

/// Ролик, который проигрывается один раз при каждом холодном старте
/// приложения (~4 сек, брендированный фургон + мастера, заканчивается
/// на логотипе FixMyGastro), прежде чем показать обычный AuthGate.
/// Без звука — автовоспроизведение со звуком блокируют браузеры (веб),
/// да и внезапный звук при каждом открытии приложения был бы навязчив.
/// Нажатие по экрану пропускает ролик.
class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key});

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  late final VideoPlayerController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/splash_intro.mp4')
      ..setVolume(0);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    }).catchError((_) {
      // Не смог загрузить/декодировать ролик — не блокируем вход в
      // приложение, просто пропускаем заставку.
      if (mounted) _goToApp();
    });
    _controller.addListener(_onTick);

    // Подстраховка: даже если воспроизведение зависнет, через
    // разумное время после длины самого ролика (~4с) всё равно
    // пускаем пользователя в приложение.
    Future.delayed(const Duration(seconds: 8), _goToApp);
  }

  void _onTick() {
    final value = _controller.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _goToApp();
    }
  }

  void _goToApp() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: GestureDetector(
        onTap: _goToApp,
        behavior: HitTestBehavior.opaque,
        child: _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
