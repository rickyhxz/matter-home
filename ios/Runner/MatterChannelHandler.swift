import Flutter
import UIKit
import MatterSupport

/// Handles the Flutter ↔ native Matter platform channel.
/// Requires the com.apple.developer.matter.allow-setup-payload entitlement.
class MatterChannelHandler: NSObject {

    static let channelName = "com.rickyhh35.matter_home/matter"

    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: MatterChannelHandler.channelName, binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "commissionDevice":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            let homeName = args["homeName"] as? String ?? "My Home"
            let roomName = args["roomName"] as? String ?? "Room"
            commissionDevice(homeName: homeName, roomName: roomName, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func commissionDevice(homeName: String, roomName: String, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(
                code: "UNSUPPORTED_PLATFORM",
                message: "Matter commissioning requires iOS 16.1 or later.",
                details: nil
            ))
            return
        }

        Task {
            do {
                let topology = MatterAddDeviceRequest.Topology(
                    ecosystemName: homeName,
                    homes: [MatterAddDeviceRequest.Topology.Home(displayName: homeName)]
                )
                let request = MatterAddDeviceRequest(topology: topology)
                try await request.perform()

                // perform() succeeds silently — Apple's sheet handled commissioning.
                // The device is now in the local Matter fabric. We return a success signal;
                // real device discovery would follow via MTRDeviceController.
                await MainActor.run {
                    result([
                        "deviceId": UUID().uuidString,
                        "deviceName": "\(roomName) Device",
                        "deviceType": "light"
                    ])
                }
            } catch let error as NSError {
                await MainActor.run {
                    result(self.mapError(error))
                }
            }
        }
    }

    private func mapError(_ error: NSError) -> FlutterError {
        // MatterSupport error codes
        switch error.code {
        case 1: // MTRCommissioningError.userCancelled (not a public API constant yet)
            return FlutterError(code: "USER_CANCELLED", message: "User cancelled pairing.", details: nil)
        case 4: // Network / BLE failure
            return FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil)
        default:
            // Entitlement missing surfaces as NSCocoaErrorDomain / permission denied
            if error.domain == NSCocoaErrorDomain && error.code == 4097 {
                return FlutterError(
                    code: "NOT_ENTITLED",
                    message: "The Matter entitlement is missing. Request it at developer.apple.com/contact/request/matter-framework-access",
                    details: nil
                )
            }
            return FlutterError(code: "UNKNOWN", message: error.localizedDescription, details: String(error.code))
        }
    }
}
