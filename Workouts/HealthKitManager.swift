import HealthKit

class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    func addKeiserWorkout(distance: Double) {
        let endDate = Date.now
        let startDate = Calendar.current.date(
            byAdding: DateComponents(hour: -1),
            to: endDate,
            wrappingComponents: false
        )!
        let workout = HKWorkout(
            activityType: HKWorkoutActivityType.cycling,
            start: startDate,
            end: endDate,
            duration: 0, // compute from start and end data
            totalEnergyBurned: HKQuantity(
                unit: .kilocalorie(),
                doubleValue: 851.0
            ),
            totalDistance: HKQuantity(unit: .mile(), doubleValue: distance),
            metadata: nil
        )
        Task {
            do {
                try await store.save(workout)
                print("added workout")
            } catch {
                print("error adding workout: \(error)")
            }
        }
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
