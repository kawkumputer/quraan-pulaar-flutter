import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/activation_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/strings.dart';

class ActivationDialog extends StatelessWidget {
  final bool isFirstLaunch;
  final _codeController = TextEditingController();
  final _activationController = Get.find<ActivationController>();

  ActivationDialog({
    Key? key,
    this.isFirstLaunch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.activationTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.activationWelcome,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: S.activationCode,
                border: OutlineInputBorder(),
                hintText: S.activationCodeHint,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isFirstLaunch) ...[
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(S.tryFree),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(S.notNow),
                  ),
                ],
                Obx(() {
                  final isVerifying = _activationController.isVerifying;
                  return ElevatedButton(
                    onPressed: isVerifying ? null : _activate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      isVerifying ? S.pleaseWait : S.activate,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
              ],
            ),
            Obx(() {
              final error = _activationController.verificationError;
              if (error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Get.back();  // Close the dialog first
                Get.toNamed(AppRoutes.about);  // Then navigate to about screen
              },
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: S.noCodeContact),
                    TextSpan(
                      text: S.contact,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _activationController.setVerificationError(S.enterCode);
      return;
    }

    final success = await _activationController.verifyActivationCode(code);
    if (success) {
      Get.back(result: true);
    }
  }
}
