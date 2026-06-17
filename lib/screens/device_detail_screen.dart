import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../providers/home_provider.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(devicesProvider).firstWhere((d) => d.id == deviceId);
    final cs = Theme.of(context).colorScheme;
    final isOffline = device.status != DeviceStatus.online;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(devicesProvider.notifier).removeDevice(device.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeroCard(device: device, cs: cs, isOffline: isOffline, ref: ref),
          const SizedBox(height: 24),
          _InfoSection(device: device, cs: cs),
          if (device.type == DeviceType.light && !isOffline) ...[
            const SizedBox(height: 24),
            _BrightnessSection(device: device, ref: ref, cs: cs),
          ],
          if (device.type == DeviceType.thermostat && !isOffline) ...[
            const SizedBox(height: 24),
            _TemperatureSection(device: device, ref: ref, cs: cs),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Device device;
  final ColorScheme cs;
  final bool isOffline;
  final WidgetRef ref;

  const _HeroCard({required this.device, required this.cs, required this.isOffline, required this.ref});

  @override
  Widget build(BuildContext context) {
    final active = device.isOn && !isOffline;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(device.icon, size: 56, color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.typeLabel, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  device.statusLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(device.brand, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (device.type != DeviceType.sensor)
            Switch(
              value: device.type == DeviceType.lock ? (device.isLocked ?? false) : device.isOn,
              onChanged: isOffline ? null : (_) => ref.read(devicesProvider.notifier).toggle(device.id),
            ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Device device;
  final ColorScheme cs;

  const _InfoSection({required this.device, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _InfoRow(label: 'Brand', value: device.brand),
        _InfoRow(label: 'Type', value: device.typeLabel),
        _InfoRow(label: 'Status', value: device.status == DeviceStatus.online ? 'Online' : 'Offline'),
        _InfoRow(label: 'Device ID', value: device.id),
        _InfoRow(label: 'Protocol', value: 'Matter 1.2'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BrightnessSection extends StatelessWidget {
  final Device device;
  final WidgetRef ref;
  final ColorScheme cs;

  const _BrightnessSection({required this.device, required this.ref, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brightness', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.brightness_low),
            Expanded(
              child: Slider(
                value: device.brightness ?? 1.0,
                onChanged: device.isOn
                    ? (v) => ref.read(devicesProvider.notifier).setBrightness(device.id, v)
                    : null,
              ),
            ),
            const Icon(Icons.brightness_high),
          ],
        ),
        Center(
          child: Text(
            '${((device.brightness ?? 1.0) * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _TemperatureSection extends StatelessWidget {
  final Device device;
  final WidgetRef ref;
  final ColorScheme cs;

  const _TemperatureSection({required this.device, required this.ref, required this.cs});

  @override
  Widget build(BuildContext context) {
    final temp = device.temperature ?? 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Temperature', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('16°C'),
            Expanded(
              child: Slider(
                value: temp,
                min: 16,
                max: 30,
                divisions: 28,
                label: '${temp.toStringAsFixed(1)}°C',
                onChanged: (v) => ref.read(devicesProvider.notifier).setTemperature(device.id, v),
              ),
            ),
            const Text('30°C'),
          ],
        ),
        Center(
          child: Text(
            '${temp.toStringAsFixed(1)}°C',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
