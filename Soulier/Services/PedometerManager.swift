import CoreMotion
import Foundation

@MainActor
final class PedometerManager {
    private let pedometer = CMPedometer()
    private var onStepsUpdate: (@MainActor (Int) -> Void)?

    private(set) var isTracking = false

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    func startUpdates(from date: Date, onSteps: @escaping @MainActor (Int) -> Void) {
        guard isAvailable else { return }

        stopUpdates()

        onStepsUpdate = onSteps
        isTracking = true

        pedometer.startUpdates(from: date) { [weak self] data, error in
            guard error == nil, let data else { return }
            let steps = data.numberOfSteps.intValue
            Task { @MainActor in
                guard let self, self.isTracking else { return }
                onSteps(steps)
            }
        }
    }

    func stopUpdates() {
        guard isTracking else { return }
        pedometer.stopUpdates()
        isTracking = false
        onStepsUpdate = nil
    }
}
