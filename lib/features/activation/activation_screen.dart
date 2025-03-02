import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/activation_controller.dart';

class ActivationScreen extends GetView<ActivationController> {
  const ActivationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text(
                  'Enter your activation code to access all surahs.\n'
                  'Without activation, only the first three surahs will be available.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Activation Code',
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
                            Get.snackbar(
                              'Error',
                              'Please enter an activation code',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          final success = await controller.verifyActivationCode(codeController.text);
                          print('Verification result: $success');
                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'Success',
                              'Device activated successfully',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        child: const Text('Activate'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
