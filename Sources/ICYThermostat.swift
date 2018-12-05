import Foundation
import ICY
import HAP
import func Evergreen.getLogger

#if os(Linux)
    import Dispatch
#endif

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

        timer.scheduleRepeating(deadline: .now(), interval: 20)
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

        thermostat.targetTemperature.onSetValue = { newValue in
            guard var status = self.status, let newValue = newValue else { return }
            if status.setting != .fixed {
                status.setting = .comfort
                status.desiredTemperature = newValue
                self.updatePortal(status)
            }
        }

        thermostat.targetHeatingCoolingState.onSetValue = { newValue in
            guard var status = self.status, let newValue = newValue else { return }
            switch newValue {
            case .off: status.setting = .fixed
            case .cool: status.setting = .saving
            case .heat, .auto: status.setting = .comfort
            }
            self.updatePortal(status)
            self.thermostat.targetTemperature.value = status.desiredTemperature
        }
    }

    func updateFromPortal() {
        guard let status = status else { return }
        self.thermostat.currentTemperature.value = status.currentTemperature
        self.thermostat.targetTemperature.value = status.desiredTemperature

        switch status.setting {
        case .fixed: self.thermostat.targetHeatingCoolingState.value = .off
        default: self.thermostat.targetHeatingCoolingState.value = .auto
        }
        
        switch (status.isHeating, status.setting) {
        case (true, _): self.thermostat.currentHeatingCoolingState.value = .heat
        case (_, .comfort): self.thermostat.currentHeatingCoolingState.value = .cool
        default: self.thermostat.currentHeatingCoolingState.value = .off
        }
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
