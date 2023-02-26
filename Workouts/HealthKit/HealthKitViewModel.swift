import HealthKit

@MainActor
class HealthKitViewModel: ObservableObject {
    // These values are the sum over the past seven days.
    @Published private(set) var activeEnergyBurned: Double = 0
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var restingHeartRate: Double = 0
    @Published private(set) var steps: Double = 0

    // These values are the sum since the beginning of the year.
    @Published private(set) var distanceCycling: Double = 0
    @Published private(set) var distanceWalkingRunning: Double = 0


    init() {
        Task {
            let manager = HealthKitManager()
            do {
                try await manager.authorize(identifiers: [
                    .activeEnergyBurned,
                    .distanceCycling,
                    .distanceWalkingRunning,
                    .heartRate,
                    .restingHeartRate,
                    .stepCount,
                ])

                let endDate = Date.now
                let startDate = Calendar.current.date(
                    byAdding: DateComponents(day: -7),
                    to: endDate,
                    wrappingComponents: false
                )!

                activeEnergyBurned = try await manager.sum(
                    identifier: .activeEnergyBurned,
                    unit: .kilocalorie(),
                    startDate: startDate,
                    endDate: endDate
                )
                distanceCycling = try await manager.sum(
                    identifier: .distanceCycling,
                    unit: .mile(),
                    startDate: endDate.startOfYear,
                    endDate: endDate
                )
                distanceWalkingRunning = try await manager.sum(
                    identifier: .distanceWalkingRunning,
                    unit: .mile(),
                    startDate: endDate.startOfYear,
                    endDate: endDate
                )
                // TODO: Seems like this value is too high.
                // TODO: Can we exclude samples during exercise?
                heartRate = try await manager.average(
                    identifier: .heartRate,
                    unit: HKUnit(from: "count/min"),
                    startDate: startDate,
                    endDate: endDate
                )
                restingHeartRate = try await manager.average(
                    identifier: .restingHeartRate,
                    unit: HKUnit(from: "count/min"),
                    startDate: startDate,
                    endDate: endDate
                )
                steps = try await manager.sum(
                    identifier: .stepCount,
                    unit: .count(),
                    startDate: startDate,
                    endDate: endDate
                )
            } catch {
                print("error getting health data: \(error)")
            }
        }
    }
}