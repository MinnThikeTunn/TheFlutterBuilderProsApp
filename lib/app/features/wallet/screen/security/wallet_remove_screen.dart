import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletRemoveScreen extends BaseView<WalletController> {
  const WalletRemoveScreen({super.key});
  @override
  Widget buildView(BuildContext context) => Obx(
    () => PopScope(
      canPop: !controller.isChangingAccess.value,
      child: WalletPage(
        title: 'Remove Rewards Access',
        subtitle: 'Disable local access with device authentication.',
        children: <Widget>[
          WalletCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded, size: 58),
                const SizedBox(height: 14),
                Text(
                  'Disable Rewards access on this device?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'This blocks local Rewards reads and sending after restart. It does not close your account or move your Rewards. Protected signing material and transaction evidence remain on this device so access can be restored using device authentication. Pending transfers must be resolved first.',
                  textAlign: TextAlign.center,
                ),
                if (controller.accessError.value.isNotEmpty)
                  Text(controller.accessError.value),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.isChangingAccess.value
                      ? null
                      : controller.removeRewardsAccess,
                  icon: const Icon(Icons.phonelink_erase_outlined),
                  label: Text(
                    controller.isChangingAccess.value
                        ? 'Disabling access…'
                        : 'Authenticate and disable access',
                  ),
                ),
                OutlinedButton(
                  onPressed: controller.isChangingAccess.value
                      ? null
                      : Get.back,
                  child: const Text('Keep Rewards access'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
