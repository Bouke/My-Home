import Foundation
import ICY
import HAP
import func Evergreen.getLogger


getLogger("hap").logLevel = .warning
getLogger("http").logLevel = .info

guard let username = ProcessInfo.processInfo.environment["ICY_USERNAME"], let password = ProcessInfo.processInfo.environment["ICY_PASSWORD"] else {
    print("Set ICY_USERNAME and ICY_PASSWORD environment variables")
    exit(1)
}

let thermostat = ICYThermostat(info: .init(name: "Thermostat"), username: username, password: password)
let device = HAP.Device(name: "Thermostat", pin: "123-44-321", storage: try FileStorage(path: "db"), accessories: [thermostat])
let server = HAP.Server(device: device, port: 8000)
server.publish()
server.listen()
