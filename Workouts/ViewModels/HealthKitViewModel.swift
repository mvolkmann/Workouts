import HealthKit
import SwiftUI

@MainActor
final class HealthKitViewModel: ObservableObject {
    // This is a singleton class.
    static let shared = HealthKitViewModel()

    private init() {}

    // MARK: - Constants

    static let addZeros: Set<HKQuantityTypeIdentifier> = [
        .distanceCycling, .distanceWalkingRunning, .distanceWheelchair,
        .pushCount, .stepCount
    ]

    // MARK: - Properties

    @Published private(set) var activeEnergyBurned: [DatedValue] = []
    @Published private(set) var activeEnergyBurnedSum = 0.0
    @Published private(set) var appleExerciseTime: [DatedValue] = []
    @Published private(set) var appleStandTime: [DatedValue] = []
    // This is the same as "Resting Energy".
    @Published private(set) var basalEnergyBurned: [DatedValue] = []
    @Published private(set) var basalEnergyBurnedSum = 0.0
    @Published private(set) var bpmAverage = 0.0
    @Published private(set) var distanceCycling: [DatedValue] = []
    @Published private(set) var distanceCyclingSum = 0.0
    @Published private(set) var distanceSwimmingSum = 0.0
    @Published private(set) var distanceWalkingRunning: [DatedValue] = []
    @Published private(set) var distanceWalkingRunningSum = 0.0
    @Published private(set) var distanceWheelchair: [DatedValue] = []
    @Published private(set) var environmentalAudioExposure: [DatedValue] = []
    @Published private(set) var flightsClimbed: [DatedValue] = []
    @Published private(set) var headphoneAudioExposure: [DatedValue] = []
    @Published private(set) var heartRate: [DatedValue] = []
    @Published private(set) var heartRateAverage = 0.0
    @Published private(set) var pushCount: [DatedValue] = []
    @Published private(set) var respiratoryRate: [DatedValue] = []
    @Published private(set) var restingHeartRate: [DatedValue] = []
    @Published private(set) var restingHeartRateAverage = 0.0
    @Published private(set) var sleepDuration: [DatedValue] = []
    @Published private(set) var stairAscentSpeed: [DatedValue] = []
    @Published private(set) var stairDescentSpeed: [DatedValue] = []
    @Published private(set) var stepCount: [DatedValue] = []
    @Published private(set) var stepSum = 0.0
    @Published private(set) var vo2Max: [DatedValue] = []
    @Published private(set) var walkingAsymmetryPercentage: [DatedValue] = []
    @Published private(set) var walkingDoubleSupportPercentage: [DatedValue] =
        []
    @Published private(set) var walkingSpeed: [DatedValue] = []
    @Published private(set) var walkingStepLength: [DatedValue] = []

    func load() async throws {
        let store = HealthStore()

        let endDate = Date.now
        let startDate = Calendar.current.date(
            byAdding: DateComponents(day: -7),
            to: endDate
        )!

        activeEnergyBurnedSum = try await store.sum(
            identifier: .activeEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )
        basalEnergyBurnedSum = try await store.sum(
            identifier: .basalEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )
        distanceCyclingSum = try await store.sum(
            identifier: .distanceCycling,
            unit: .mile(),
            startDate: endDate.startOfYear,
            endDate: endDate
        )
        distanceSwimmingSum = try await store.sum(
            identifier: .distanceSwimming,
            unit: .mile(),
            startDate: endDate.startOfYear,
            endDate: endDate
        )
        distanceWalkingRunningSum = try await store.sum(
            identifier: .distanceWalkingRunning,
            unit: .mile(),
            startDate: endDate.startOfYear,
            endDate: endDate
        )
        let bpm = HKUnit(from: "count/min")
        heartRateAverage = try await store.average(
            identifier: .heartRate,
            unit: bpm,
            startDate: startDate,
            endDate: endDate
        )
        restingHeartRateAverage = try await store.average(
            identifier: .restingHeartRate,
            unit: bpm,
            startDate: startDate,
            endDate: endDate
        )
        stepSum = try await store.sum(
            identifier: .stepCount,
            unit: .count(),
            startDate: startDate,
            endDate: endDate
        )
    }
}
