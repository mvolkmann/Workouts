import HealthKit

@MainActor
class HealthKitViewModel: ObservableObject {
    // These values are the sum over the past seven days.
    @Published private(set) var activeEnergyBurned: Double = 0
    @Published private(set) var basalEnergyBurned: Double = 0
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var restingHeartRate: Double = 0
    @Published private(set) var steps: Double = 0

    // These values are the sum since the beginning of the year.
    @Published private(set) var distanceCycling: Double = 0
    @Published private(set) var distanceWalkingRunning: Double = 0

    func load() async {
        print("\(#fileID) \(#function) entered")
        let manager = HealthKitManager()
        do {
            print("HealthKitViewModel.load: calling authorize")
            try await manager.authorize(
                read: [
                    .activeEnergyBurned,
                    .basalEnergyBurned,
                    .distanceCycling,
                    .distanceSwimming,
                    .distanceWalkingRunning,
                    .heartRate,
                    .restingHeartRate,
                    .stepCount,
                ],
                write: [
                    .activeEnergyBurned,
                    .distanceCycling,
                    .distanceSwimming,
                    .distanceWalkingRunning,
                ]
            )
            print("HealthKitViewModel.load: authorized")

            let endDate = Date.now
            let startDate = Calendar.current.date(
                byAdding: DateComponents(day: -7),
                to: endDate,
                wrappingComponents: false
            )!

            print("HealthKitViewModel.load: getting activeEnergyBurned")
            activeEnergyBurned = try await manager.sum(
                identifier: .activeEnergyBurned,
                unit: .largeCalorie(),
                startDate: startDate,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting basalEnergyBurned")
            basalEnergyBurned = try await manager.sum(
                identifier: .basalEnergyBurned,
                unit: .largeCalorie(),
                startDate: startDate,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting distanceCycling")
            distanceCycling = try await manager.sum(
                identifier: .distanceCycling,
                unit: .mile(),
                startDate: endDate.startOfYear,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting distanceWalkingRunning")
            distanceWalkingRunning = try await manager.sum(
                identifier: .distanceWalkingRunning,
                unit: .mile(),
                startDate: endDate.startOfYear,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting heartRate")
            let bpm = HKUnit(from: "count/min")
            heartRate = try await manager.average(
                identifier: .heartRate,
                unit: bpm,
                startDate: startDate,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting restingHeartRate")
            restingHeartRate = try await manager.average(
                identifier: .restingHeartRate,
                unit: bpm,
                startDate: startDate,
                endDate: endDate
            )
            print("HealthKitViewModel.load: getting stepCount")
            steps = try await manager.sum(
                identifier: .stepCount,
                unit: .count(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            Log.error("error getting health data: \(error)")
        }
    }
}
