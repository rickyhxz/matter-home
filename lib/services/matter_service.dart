import 'package:flutter/services.dart';

/// Result of a Matter commissioning attempt.
sealed class CommissioningResult {}

class CommissioningSuccess extends CommissioningResult {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  CommissioningSuccess({required this.deviceId, required this.deviceName, required this.deviceType});
}

class CommissioningFailure extends CommissioningResult {
  final String message;
  final CommissioningError error;
  CommissioningFailure({required this.message, required this.error});
}

enum CommissioningError {
  notEntitled,      // Missing Apple Matter entitlement
  userCancelled,
  networkError,
  deviceNotFound,
  alreadyCommissioned,
  unsupportedPlatform,
  unknown,
}

/// Thin Flutter wrapper around the native Matter platform channel.
class MatterService {
  static const _channel = MethodChannel('com.rickyhh35.matter_home/matter');

  /// Opens the system Matter commissioning UI and waits for the result.
  /// On iOS 16+ with the Matter entitlement this shows Apple's native pairing sheet.
  static Future<CommissioningResult> commissionDevice({
    required String homeName,
    required String roomName,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'commissionDevice',
        {'homeName': homeName, 'roomName': roomName},
      );
      return CommissioningSuccess(
        deviceId: result?['deviceId'] as String? ?? 'unknown',
        deviceName: result?['deviceName'] as String? ?? 'New Device',
        deviceType: result?['deviceType'] as String? ?? 'light',
      );
    } on PlatformException catch (e) {
      return CommissioningFailure(
        message: e.message ?? 'Unknown error',
        error: _mapErrorCode(e.code),
      );
    }
  }

  static CommissioningError _mapErrorCode(String code) => switch (code) {
        'NOT_ENTITLED' => CommissioningError.notEntitled,
        'USER_CANCELLED' => CommissioningError.userCancelled,
        'NETWORK_ERROR' => CommissioningError.networkError,
        'DEVICE_NOT_FOUND' => CommissioningError.deviceNotFound,
        'ALREADY_COMMISSIONED' => CommissioningError.alreadyCommissioned,
        'UNSUPPORTED_PLATFORM' => CommissioningError.unsupportedPlatform,
        _ => CommissioningError.unknown,
      };
}
