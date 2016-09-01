import Foundation
import ICY
import HAP
import func Evergreen.getLogger

let logger = getLogger("icy")

class ICYThermostat: HAP.Accessory.Thermostat {
    var session: ICY.Session? = nil
    var status: ICY.ThermostatStatus? = nil
    let timer = DispatchSource.makeTimerSource()

    init(info: Service.Info, username: String, password: String) {
        super.init(info: info)

        ICY.login(username: username, password: password) { result in
            do {
                self.session = try result.unpack()
                self.timer.resume()
            } catch {
                logger.error("Could not login", error: error)
            }
        }

        timer.scheduleRepeating(deadline: .now(), interval: 5)
        timer.setEventHandler(handler: {
            self.session?.getStatus { result in
                do {
                    self.status = try result.unpack()
                    self.updateFromPortal()
                } catch {
                    logger.error("Could not get status", error: error)
                    self.timer.cancel()
                }
            }
        })

        thermostat.targetTemperature.onValueChange.append({ newValue in
            guard var status = self.status, let newValue = newValue else { return }
            status.desiredTemperature = newValue
            self.updatePortal(status)
        })

        thermostat.targetHeatingCoolingState.onValueChange.append({ newValue in
            guard var status = self.status, let newValue = newValue else { return }
            switch newValue {
            case .heat, .auto: status.setting = .comfort
            case .cool: status.setting = .saving
            case .off: status.setting = .away
            }
            self.updatePortal(status)
        })
    }

    func updateFromPortal() {
        guard let status = status else { return }
        self.thermostat.currentTemperature.value = status.currentTemperature
        self.thermostat.targetTemperature.value = status.desiredTemperature

        switch status.setting {
        case .comfort: self.thermostat.targetHeatingCoolingState.value = .auto
        case .saving: self.thermostat.targetHeatingCoolingState.value = .cool
        default: self.thermostat.targetHeatingCoolingState.value = .off
        }

        self.thermostat.currentHeatingCoolingState.value = status.isHeating ? .heat : .off
    }

    func updatePortal(_ status: ICY.ThermostatStatus) {
        self.session?.setStatus(status) { result in
            do {
                try result.unpack()
                self.status = status
            } catch {
                logger.error("Could not update portal", error: error)
            }
        }
    }

    deinit {
        timer.cancel()
    }
}
