import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/room.dart';

const _uuid = Uuid();

// ── Seed data ──────────────────────────────────────────────────────────────

final _seedRooms = [
  const Room(id: 'living', name: 'Living Room', icon: Icons.weekend_outlined),
  const Room(id: 'bedroom', name: 'Bedroom', icon: Icons.bed_outlined),
  const Room(id: 'kitchen', name: 'Kitchen', icon: Icons.kitchen_outlined),
  const Room(id: 'bathroom', name: 'Bathroom', icon: Icons.bathroom_outlined),
];

final _seedDevices = [
  Device(id: 'd1', name: 'Ceiling Light', type: DeviceType.light, roomId: 'living', brand: 'Philips Hue', isOn: true, brightness: 0.8),
  Device(id: 'd2', name: 'Floor Lamp', type: DeviceType.light, roomId: 'living', brand: 'IKEA', isOn: false, brightness: 0.5),
  Device(id: 'd3', name: 'Smart TV', type: DeviceType.switch_, roomId: 'living', brand: 'Samsung', isOn: true),
  Device(id: 'd4', name: 'Front Door', type: DeviceType.lock, roomId: 'living', brand: 'August', isLocked: true),
  Device(id: 'd5', name: 'Bedside Lamp', type: DeviceType.light, roomId: 'bedroom', brand: 'Philips Hue', isOn: true, brightness: 0.3),
  Device(id: 'd6', name: 'Thermostat', type: DeviceType.thermostat, roomId: 'bedroom', brand: 'Nest', isOn: true, temperature: 22.5),
  Device(id: 'd7', name: 'AC Outlet', type: DeviceType.outlet, roomId: 'bedroom', brand: 'Eve', isOn: false),
  Device(id: 'd8', name: 'Motion Sensor', type: DeviceType.sensor, roomId: 'kitchen', brand: 'Aqara', status: DeviceStatus.online),
  Device(id: 'd9', name: 'Under-cabinet Light', type: DeviceType.light, roomId: 'kitchen', brand: 'IKEA', isOn: true, brightness: 1.0),
];

// ── Rooms provider ─────────────────────────────────────────────────────────

class RoomsNotifier extends StateNotifier<List<Room>> {
  RoomsNotifier() : super(_seedRooms);

  void addRoom(String name, IconData icon) {
    state = [...state, Room(id: _uuid.v4(), name: name, icon: icon)];
  }

  void removeRoom(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final roomsProvider = StateNotifierProvider<RoomsNotifier, List<Room>>(
  (_) => RoomsNotifier(),
);

// ── Devices provider ───────────────────────────────────────────────────────

class DevicesNotifier extends StateNotifier<List<Device>> {
  DevicesNotifier() : super(_seedDevices);

  void toggle(String id) {
    state = state.map((d) {
      if (d.id != id) return d;
      if (d.type == DeviceType.lock) return d.copyWith(isLocked: !(d.isLocked ?? true));
      return d.copyWith(isOn: !d.isOn);
    }).toList();
  }

  void setBrightness(String id, double value) {
    state = state.map((d) => d.id == id ? d.copyWith(brightness: value) : d).toList();
  }

  void setTemperature(String id, double value) {
    state = state.map((d) => d.id == id ? d.copyWith(temperature: value) : d).toList();
  }

  void addDevice(Device device) {
    state = [...state, device];
  }

  void removeDevice(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final devicesProvider = StateNotifierProvider<DevicesNotifier, List<Device>>(
  (_) => DevicesNotifier(),
);

// ── Derived providers ──────────────────────────────────────────────────────

final devicesByRoomProvider = Provider.family<List<Device>, String>((ref, roomId) {
  return ref.watch(devicesProvider).where((d) => d.roomId == roomId).toList();
});

final activeDeviceCountProvider = Provider<int>((ref) {
  return ref.watch(devicesProvider).where((d) => d.isOn && d.status == DeviceStatus.online).length;
});
