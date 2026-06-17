import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../providers/home_provider.dart';
import '../services/matter_service.dart';

const _uuid = Uuid();

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  int _step = 0;
  DeviceType? _selectedType;
  String? _selectedRoomId;
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  bool _commissioning = false;
  bool _commissioned = false;
  String? _commissioningError;
  String? _commissionedDeviceName;
  String? _commissionedDeviceType;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _startCommissioning() async {
    final rooms = ref.read(roomsProvider);
    final room = rooms.firstWhere((r) => r.id == _selectedRoomId!, orElse: () => rooms.first);

    setState(() {
      _commissioning = true;
      _commissioningError = null;
    });

    final result = await MatterService.commissionDevice(
      homeName: 'Matter Home',
      roomName: room.name,
    );

    if (!mounted) return;

    switch (result) {
      case CommissioningSuccess(:final deviceName, :final deviceType):
        setState(() {
          _commissioning = false;
          _commissioned = true;
          _commissionedDeviceName = deviceName;
          _commissionedDeviceType = deviceType;
        });
      case CommissioningFailure(:final message, :final error):
        setState(() {
          _commissioning = false;
          _commissioningError = error == CommissioningError.notEntitled
              ? 'Matter entitlement not yet approved by Apple.\nRequest it at developer.apple.com/contact/request/matter-framework-access'
              : error == CommissioningError.userCancelled
                  ? 'Pairing cancelled.'
                  : error == CommissioningError.unsupportedPlatform
                      ? 'Real Matter commissioning requires iOS 16.1+ on a physical device.'
                      : message;
        });
    }
  }

  void _finish() {
    if (_selectedType == null || _selectedRoomId == null) return;

    // Prefer name/type returned by native commissioning; fall back to user input.
    final resolvedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_commissionedDeviceName ?? _selectedType!.typeLabel);

    final resolvedType = _resolveType(_commissionedDeviceType) ?? _selectedType!;

    final device = Device(
      id: _uuid.v4(),
      name: resolvedName,
      type: resolvedType,
      roomId: _selectedRoomId!,
      brand: _brandController.text.trim().isEmpty ? 'Matter' : _brandController.text.trim(),
      brightness: resolvedType == DeviceType.light ? 1.0 : null,
      temperature: resolvedType == DeviceType.thermostat ? 22.0 : null,
      isLocked: resolvedType == DeviceType.lock ? true : null,
    );
    ref.read(devicesProvider.notifier).addDevice(device);
    Navigator.pop(context);
  }

  DeviceType? _resolveType(String? raw) => switch (raw) {
        'light' => DeviceType.light,
        'switch' => DeviceType.switch_,
        'thermostat' => DeviceType.thermostat,
        'lock' => DeviceType.lock,
        'sensor' => DeviceType.sensor,
        'outlet' => DeviceType.outlet,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: _step > 0 && !_commissioned
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(step: _step, total: 4),
            const SizedBox(height: 32),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_step) {
                  0 => _SelectTypeStep(
                      key: const ValueKey(0),
                      selected: _selectedType,
                      onSelect: (t) => setState(() => _selectedType = t),
                    ),
                  1 => _SelectRoomStep(
                      key: const ValueKey(1),
                      rooms: rooms,
                      selected: _selectedRoomId,
                      onSelect: (id) => setState(() => _selectedRoomId = id),
                    ),
                  2 => _NameStep(
                      key: const ValueKey(2),
                      nameController: _nameController,
                      brandController: _brandController,
                    ),
                  3 => _CommissionStep(
                      key: const ValueKey(3),
                      commissioning: _commissioning,
                      commissioned: _commissioned,
                      error: _commissioningError,
                      onStart: _startCommissioning,
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            const SizedBox(height: 24),
            _BottomBar(
              step: _step,
              canProceed: switch (_step) {
                0 => _selectedType != null,
                1 => _selectedRoomId != null,
                2 => true,
                3 => _commissioned,
                _ => false,
              },
              onNext: _step < 3 ? _next : _finish,
              isLast: _step == 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Steps ──────────────────────────────────────────────────────────────────

class _SelectTypeStep extends StatelessWidget {
  final DeviceType? selected;
  final ValueChanged<DeviceType> onSelect;

  const _SelectTypeStep({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What type of device?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Works with any Matter-certified device.', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: DeviceType.values.map((type) {
              final active = selected == type;
              return GestureDetector(
                onTap: () => onSelect(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: active ? Border.all(color: cs.primary, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: active ? cs.primary : cs.onSurfaceVariant, size: 32),
                      const SizedBox(height: 8),
                      Text(type.typeLabel, style: TextStyle(fontSize: 12, color: active ? cs.primary : cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SelectRoomStep extends StatelessWidget {
  final List<Room> rooms;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SelectRoomStep({super.key, required this.rooms, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which room?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (ctx, i2) => const SizedBox(height: 8),
            itemBuilder: (_, i) { // ignore: avoid_shadowing_type_parameters
              final room = rooms[i];
              final active = selected == room.id;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: active ? cs.primaryContainer : cs.surfaceContainerHighest,
                leading: Icon(room.icon, color: active ? cs.primary : cs.onSurfaceVariant),
                title: Text(room.name),
                trailing: active ? Icon(Icons.check_circle, color: cs.primary) : null,
                onTap: () => onSelect(room.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController brandController;

  const _NameStep({super.key, required this.nameController, required this.brandController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name your device', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Optional — you can always rename it later.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Device name',
            hintText: 'e.g. Bedroom Ceiling Light',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: brandController,
          decoration: InputDecoration(
            labelText: 'Brand',
            hintText: 'e.g. Philips Hue',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}

class _CommissionStep extends StatelessWidget {
  final bool commissioning;
  final bool commissioned;
  final String? error;
  final VoidCallback onStart;

  const _CommissionStep({super.key, required this.commissioning, required this.commissioned, this.error, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (commissioned) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: cs.primary, size: 72),
            const SizedBox(height: 16),
            Text('Device paired!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your device is ready to use.', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (commissioning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('Pairing via Matter…', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Apple\'s pairing sheet is open — follow the on-screen steps.', style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pair your device', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Put your device in pairing mode, then tap the button below. Matter works across all brands — no brand-specific app needed.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.qr_code_scanner, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('Scan QR code or enter PIN', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(error!, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: onStart,
            child: Text(error != null ? 'Try again' : 'Start pairing'),
          ),
        ),
      ],
    );
  }
}

// ── UI helpers ─────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  final int total;

  const _StepIndicator({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final bool canProceed;
  final VoidCallback onNext;
  final bool isLast;

  const _BottomBar({required this.step, required this.canProceed, required this.onNext, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: canProceed ? onNext : null,
        child: Text(isLast ? 'Add to home' : 'Continue'),
      ),
    );
  }
}

// Extension to get typeLabel on DeviceType (mirrors Device.typeLabel)
extension on DeviceType {
  String get typeLabel => switch (this) {
        DeviceType.light => 'Light',
        DeviceType.switch_ => 'Switch',
        DeviceType.thermostat => 'Thermostat',
        DeviceType.lock => 'Lock',
        DeviceType.sensor => 'Sensor',
        DeviceType.outlet => 'Outlet',
      };

  IconData get icon => switch (this) {
        DeviceType.light => Icons.lightbulb_outline,
        DeviceType.switch_ => Icons.toggle_on_outlined,
        DeviceType.thermostat => Icons.thermostat_outlined,
        DeviceType.lock => Icons.lock_outline,
        DeviceType.sensor => Icons.sensors,
        DeviceType.outlet => Icons.electrical_services_outlined,
      };
}
