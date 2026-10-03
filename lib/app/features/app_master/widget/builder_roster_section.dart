import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

class BuilderRosterSection extends StatelessWidget {
  const BuilderRosterSection({required this.controller, super.key});
  final AppMasterController controller;
  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Builders and Rewards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: controller.isLoadingRoster.value
                  ? null
                  : controller.loadRoster,
              tooltip: 'Refresh Builder access',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (controller.isLoadingRoster.value) const LinearProgressIndicator(),
        if (controller.rosterError.value.isNotEmpty)
          WalletCard(child: Text(controller.rosterError.value)),
        if (!controller.isLoadingRoster.value &&
            controller.rosterError.value.isEmpty &&
            controller.rosterEntries.isEmpty)
          const WalletCard(
            child: Text('No Builders are listed for this App Master.'),
          ),
        for (final entry in controller.rosterEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WalletCard(
              child: ListTile(
                title: Text(entry.displayName),
                subtitle: Text(
                  '${entry.publicAccount ?? 'Account not linked'}\nUpdated ${entry.updatedAt.toLocal()}',
                ),
                isThreeLine: true,
                trailing: Text(switch (entry.state) {
                  BuilderAccessState.pending => 'Awaiting approval',
                  BuilderAccessState.active =>
                    '${entry.rewardsBalance ?? '—'} points',
                  BuilderAccessState.suspended =>
                    '${entry.rewardsBalance ?? '—'} points\nRestricted',
                }),
              ),
            ),
          ),
        if (controller.rosterPage.value?.nextCursor != null)
          OutlinedButton(
            onPressed: controller.isLoadingRoster.value
                ? null
                : () => controller.loadRoster(more: true),
            child: const Text('Load more Builders'),
          ),
      ],
    ),
  );
}
