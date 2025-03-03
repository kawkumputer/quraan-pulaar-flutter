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
        title: const Text('Kuuɓnugol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text(
                  'Naatnu doggol kuuɓnugol ngam heɓde cimooje ɗee fof.\n'
                  'So a huuɓnaani, cimooje tati gadane tan keɓataa.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Doggol Kuuɓnugol',
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
                              'Juumre',
                              'Tiiɗno naatnu doggol Kuuɓnugol',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          final success = await controller.verifyActivationCode(codeController.text);
                          print('Verification result: $success');
                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'Jaajaama',
                              'Kaɓirgal ngal kuɓnaama no moƴƴiri',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        child: const Text('Huuɓnu'),
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
