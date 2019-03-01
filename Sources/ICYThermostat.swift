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
    let defaultInterval: TimeInterval = 20
    let maxBackoffInterval: TimeInterval = 640 // 20*2^5
    var currentInterval: TimeInterval = 20

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

        timer.schedule(deadline: .now(), repeating: 30)
        timer.setEventHandler(handler: {
            self.session?.getStatus { result in
                do {
                    self.status = try result.unpack()
                    self.updateFromPortal()
                    self.rescheduleTimer(wasLastCallSuccessful: true)
                } catch {
                    logger.error("Could not get status", error: error)
                    self.rescheduleTimer(wasLastCallSuccessful: false)
                }
            }
        })
    }

    override func characteristic<T>(_ characteristic: GenericCharacteristic<T>,
                           ofService service: Service,
                           didChangeValue newValue: T?) {
        if characteristic === thermostat.targetTemperature {
            didChangeTargetTemperature(newValue: Double(newValue as! Float))
        } else if characteristic === thermostat.targetHeatingCoolingState {
            didChangeTargetHeatingCoolingState(newValue: newValue as! Enums.TargetHeatingCoolingState)
        }
        super.characteristic(characteristic, ofService: service, didChangeValue: newValue)
    }

    func didChangeTargetTemperature(newValue: Double?) {
        guard var status = self.status, let newValue = newValue else { return }
        if status.setting != .fixed {
            status.setting = .comfort
            status.desiredTemperature = round(newValue * 2) / 2 // round to 0.5°C
            self.updatePortal(status)
        }
    }

    func didChangeTargetHeatingCoolingState(newValue: Enums.TargetHeatingCoolingState) {
        guard var status = self.status else { return }
        switch newValue {
        case .off: status.setting = .fixed
        case .cool: status.setting = .saving
        case .heat, .auto: status.setting = .comfort
        }
        self.updatePortal(status)
        self.thermostat.targetTemperature.value = Float(status.desiredTemperature)
    }

    func rescheduleTimer(wasLastCallSuccessful success: Bool) {
        if success {
            if currentInterval == defaultInterval {
                return
            }
            currentInterval = defaultInterval
            logger.info("Last call was successful, back to default interval of \(self.currentInterval) seconds")
        } else {
            currentInterval = min(currentInterval * 2, maxBackoffInterval)
            logger.info("Last call was unsuccessful, backing off next call to \(self.currentInterval) seconds")
        }
        self.timer.schedule(deadline: .now() + .seconds(Int(currentInterval)), repeating: currentInterval)
    }

    func updateFromPortal() {
        guard let status = status else { return }

        logger.debug("Update from portal: (last seen: \(status.lastSeen), current: \(status.currentTemperature), desired: \(status.desiredTemperature), configuration: \(status.configuration))")

        self.thermostat.currentTemperature.value = Float(status.currentTemperature)
        self.thermostat.targetTemperature.value = Float(status.desiredTemperature)

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
