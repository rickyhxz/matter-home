import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../providers/home_provider.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';
import 'add_device_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final allDevices = ref.watch(devicesProvider);
    final activeCount = ref.watch(activeDeviceCountProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('My Home'),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),

          // Summary banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$activeCount devices active', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                          Text('${allDevices.length} total · ${rooms.length} rooms', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Icon(Icons.home_outlined, color: cs.onPrimaryContainer, size: 36),
                  ],
                ),
              ),
            ),
          ),

          // Rooms + devices
          ...rooms.map((room) {
            final devices = ref.watch(devicesByRoomProvider(room.id));
            if (devices.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            return _RoomSection(room: room, devices: devices);
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }
}

class _RoomSection extends ConsumerWidget {
  final dynamic room;
  final List<Device> devices;

  const _RoomSection({required this.room, required this.devices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(room.icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(room.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${devices.length} device${devices.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: devices.length,
              itemBuilder: (_, i) => DeviceCard(
                device: devices[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: devices[i].id)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
