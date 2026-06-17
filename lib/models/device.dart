import 'package:flutter/material.dart';

enum DeviceType { light, switch_, thermostat, lock, sensor, outlet }

enum DeviceStatus { online, offline, unreachable }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String roomId;
  final String brand;
  DeviceStatus status;
  bool isOn;
  double? brightness; // 0.0–1.0 for lights
  double? temperature; // celsius for thermostats
  bool? isLocked; // for locks

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.roomId,
    required this.brand,
    this.status = DeviceStatus.online,
    this.isOn = false,
    this.brightness,
    this.temperature,
    this.isLocked,
  });

  Device copyWith({
    String? name,
    DeviceStatus? status,
    bool? isOn,
    double? brightness,
    double? temperature,
    bool? isLocked,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      type: type,
      roomId: roomId,
      brand: brand,
      status: status ?? this.status,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      temperature: temperature ?? this.temperature,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  IconData get icon => switch (type) {
        DeviceType.light => Icons.lightbulb_outline,
        DeviceType.switch_ => Icons.toggle_on_outlined,
        DeviceType.thermostat => Icons.thermostat_outlined,
        DeviceType.lock => Icons.lock_outline,
        DeviceType.sensor => Icons.sensors,
        DeviceType.outlet => Icons.electrical_services_outlined,
      };

  String get typeLabel => switch (type) {
        DeviceType.light => 'Light',
        DeviceType.switch_ => 'Switch',
        DeviceType.thermostat => 'Thermostat',
        DeviceType.lock => 'Lock',
        DeviceType.sensor => 'Sensor',
        DeviceType.outlet => 'Outlet',
      };

  String get statusLabel {
    if (status == DeviceStatus.offline) return 'Offline';
    if (status == DeviceStatus.unreachable) return 'Unreachable';
    if (type == DeviceType.lock) return isLocked == true ? 'Locked' : 'Unlocked';
    if (type == DeviceType.thermostat) return '${temperature?.toStringAsFixed(1)}°C';
    return isOn ? 'On' : 'Off';
  }
}
