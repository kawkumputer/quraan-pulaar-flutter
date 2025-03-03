import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/activation_controller.dart';

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
            const Text(
              'Kuuɓnugol',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'A jaɓɓaama e Quraan Pulaar!\n\nHuuɓnu jaaɓnirgal ngal ngam heɓde cimooje ɗee fof. So a huuɓnaani, ko cimooje tati gadane tan keɓataa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Doggol Kuuɓnugol',
                border: OutlineInputBorder(),
                hintText: 'Naatnu doggol maa',
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
                    child: const Text('Eto ƴeewndagol'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Goɗngol'),
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
                      isVerifying ? 'Woni ko e huuɓnude...' : 'Huuɓnu',
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
          ],
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _activationController.setVerificationError('Tiiɗno naatnu doggol Kuuɓnugol');
      return;
    }

    final success = await _activationController.verifyActivationCode(code);
    if (success) {
      Get.back(result: true);
    }
  }
}
