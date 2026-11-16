import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_lock_service.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  void _checkBiometric() async {
    final lockService = ref.read(appLockServiceProvider);
    final canAuth = await lockService.canCheckBiometrics();
    if (mounted) {
      setState(() => _canBiometric = canAuth);
      if (canAuth) {
        _triggerBiometric();
      }
    }
  }

  void _triggerBiometric() async {
    final lockService = ref.read(appLockServiceProvider);
    final success = await lockService.authenticateWithBiometrics();
    if (success && mounted) {
      ref.read(isAppLockedProvider.notifier).state = false;
      widget.onUnlocked();
    }
  }

  void _handleKeyPress(String key) async {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _enteredPin += key;
      _errorMessage = null;
    });

    if (_enteredPin.length == 6) {
      final lockService = ref.read(appLockServiceProvider);
      final isValid = await lockService.verifyPin(_enteredPin);
      if (isValid) {
        if (mounted) {
          ref.read(isAppLockedProvider.notifier).state = false;
          widget.onUnlocked();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'PIN salah. Silakan coba lagi.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.lock_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Personal OS Terkunci',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan 6 digit PIN untuk membuka',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const Spacer(),

              // Numeric Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _canBiometric
                            ? IconButton(
                                iconSize: 32,
                                icon: Icon(Icons.fingerprint_rounded,
                                    color: theme.colorScheme.primary),
                                onPressed: _triggerBiometric,
                              )
                            : const SizedBox(width: 64, height: 64),
                        _buildButton('0'),
                        IconButton(
                          iconSize: 28,
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: _handleBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map(_buildButton).toList(),
    );
  }

  Widget _buildButton(String text) {
    return SizedBox(
      width: 68,
      height: 68,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => _handleKeyPress(text),
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
