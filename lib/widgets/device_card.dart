import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../providers/home_provider.dart';

class DeviceCard extends ConsumerWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isOffline = device.status != DeviceStatus.online;
    final active = device.isOn && !isOffline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  device.icon,
                  color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  size: 28,
                ),
                _ToggleSwitch(device: device, isOffline: isOffline),
              ],
            ),
            const Spacer(),
            Text(
              device.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              isOffline ? 'Offline' : device.statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOffline
                        ? cs.error
                        : active
                            ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                            : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSwitch extends ConsumerWidget {
  final Device device;
  final bool isOffline;

  const _ToggleSwitch({required this.device, required this.isOffline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (device.type == DeviceType.sensor) return const SizedBox.shrink();

    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: device.type == DeviceType.lock ? (device.isLocked ?? false) : device.isOn,
        onChanged: isOffline
            ? null
            : (_) => ref.read(devicesProvider.notifier).toggle(device.id),
      ),
    );
  }
}
