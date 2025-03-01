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
            Obx(() {
              if (controller.isWebPlatform.value) {
                return const Center(
                  child: Text(
                    'This feature is only available in the mobile app.\n'
                    'Please download our mobile app to use this feature.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return Column(
                children: [
                  const Text(
                    'Enter your activation code',
                    style: TextStyle(fontSize: 20),
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
                  Obx(() => controller.isLoading.value
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

                            final success = await controller.verifyCode(codeController.text);
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
                  Obx(() => controller.error.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            controller.error.value,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : const SizedBox()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
