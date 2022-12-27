import HealthKit

@MainActor
class HealthKitViewModel: ObservableObject {
    @Published private(set) var activeEnergyBurned: Double = 0
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var restingHeartRate: Double = 0
    @Published private(set) var steps: Double = 0

    init() {
        Task {
            let manager = HealthKitManager()
            do {
                try await manager.authorize(identifiers: [
                    .activeEnergyBurned,
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
