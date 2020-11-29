import Foundation
import HAP
import ICY
import Logging

fileprivate let logger = Logger(label: "my-home")

#if os(Linux)
    import Dispatch
#endif

guard let username = ProcessInfo.processInfo.environment["ICY_USERNAME"], let password = ProcessInfo.processInfo.environment["ICY_PASSWORD"] else {
    logger.error("Set ICY_USERNAME and ICY_PASSWORD environment variables")
    exit(1)
}

let thermostat = ICYThermostat(info: .init(name: "Thermostaat", serialNumber: "1"), username: username, password: password)

let device = HAP.Device(setupCode: "123-44-321", storage: FileStorage(filename: "configuration.json"), accessory: thermostat)
let server = try HAP.Server(device: device, listenPort: 0)

//let speaker = Accessory(info: Service.Info(name: "My Speaker", serialNumber: "2"), type: .speaker, services: [Service.TelevisionSpeaker(name: "My Speaker")])
//let device = HAP.Device(bridgeInfo: Service.Info(name: "My Bridge", serialNumber: "0"), storage: FileStorage(filename: "configuration.json"),

var keepRunning = true
func stop() {
    DispatchQueue.main.async {
        logger.info("Shutting down...")
        keepRunning = false
    }
}
signal(SIGINT) { _ in stop() }
signal(SIGTERM) { _ in stop() }

print()
print("Scan the following QR code using your iPhone to pair this device:")
print()
print(device.setupQRCode.asText)
print()

while keepRunning {
    RunLoop.current.run(mode: .default, before: Date.distantFuture)
}

try server.stop()
logger.info("Stopped")
