import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/messenger.dart';
import '../../core/controllers/activation_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/strings.dart';

class ActivationScreen extends GetView<ActivationController> {
  const ActivationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.activationTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  S.activationScreenText,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: S.activationCode,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Obx(() => controller.isVerifying
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          print('Attempting to verify code: ${codeController.text}');
                          if (codeController.text.isEmpty) {
                            showMessage(S.enterCode, error: true);
                            return;
                          }

                          final success = await controller.verifyActivationCode(codeController.text);
                          print('Verification result: $success');
                          if (success) {
                            Get.back();
                            showMessage(S.activationSuccess);
                          }
                        },
                        child: Text(S.activate),
                      )),
                Obx(() {
                  final error = controller.verificationError;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.about),
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
          ],
        ),
      ),
    );
  }
}
