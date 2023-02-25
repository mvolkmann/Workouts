import HealthKit

class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    func addCyclingWorkout(
        startTime: Date,
        endTime: Date,
        distance: Double,
        calories: Int
    ) async throws {
        let workout = HKWorkout(
            activityType: HKWorkoutActivityType.cycling,
            start: startTime,
            end: endTime,
            duration: 0, // compute from start and end data
            // TODO: MOVE calories not updating in activity ring!
            // See https://forums.swift.org/t/healthkit-hkworkout-totalenergyburn/63359.
            totalEnergyBurned: HKQuantity(
                // unit: .kilocalorie(),
                unit: .largeCalorie(),
                doubleValue: Double(calories)
            ),
            totalDistance: HKQuantity(unit: .mile(), doubleValue: distance),
            metadata: nil
        )
        try await store.save(workout)
    }

    func authorize(identifiers: [HKQuantityTypeIdentifier]) async throws {
        let readSet: Set<HKSampleType> = Set(
            identifiers.map { .quantityType(forIdentifier: $0)! }
        )
        let writeSet: Set<HKSampleType> = [
            .quantityType(
                forIdentifier: HKQuantityTypeIdentifier.distanceCycling
            )!,
            HKWorkoutType.workoutType()
        ]
        try await store.requestAuthorization(toShare: writeSet, read: readSet)
    }

    func average(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        let quantityType = HKSampleType.quantityType(forIdentifier: identifier)!
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: datePredicate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: []
        )
        let samples = try await descriptor.result(for: store)
        let sum = samples.reduce(0) { $0 + $1.quantity.doubleValue(for: unit) }
        return sum / Double(samples.count)
    }

    func sum(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        let quantityType = HKSampleType.quantityType(forIdentifier: identifier)!
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: datePredicate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: []
        )
        let samples = try await descriptor.result(for: store)
        return samples.reduce(0) { $0 + $1.quantity.doubleValue(for: unit) }
    }
}
