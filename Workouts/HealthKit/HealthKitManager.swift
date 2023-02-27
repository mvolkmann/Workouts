import HealthKit

class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    func addWorkout(
        workoutType: String,
        startTime: Date,
        endTime: Date,
        distance: Double,
        calories: Int
    ) async throws {
        let energyBurned = HKQuantity(
            // unit: .kilocalorie(),
            unit: .largeCalorie(),
            doubleValue: Double(calories)
        )

        let preferKM = UserDefaults.standard.bool(forKey: "preferKilometers")
        let unit: HKUnit = preferKM ? HKUnit.meter() : HKUnit.mile()
        let unitDistance = !distanceWorkouts.contains(workoutType) ?
            0 :
            (preferKM ? distance * 1000 : distance)

        guard let activityType = activityMap[workoutType] else {
            throw "no activity type found for \(workoutType)"
        }

        let workout = HKWorkout(
            activityType: activityType,
            start: startTime,
            end: endTime,
            duration: 0, // compute from start and end data
            // See https://forums.swift.org/t/healthkit-hkworkout-totalenergyburn/63359
            // and https://developer.apple.com/forums/thread/725572.
            totalEnergyBurned: energyBurned,
            totalDistance: HKQuantity(unit: unit, doubleValue: unitDistance),
            metadata: nil
        )
        try await store.save(workout)

        let energyBurnedType = HKObjectType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned
        )!
        let sample = HKQuantitySample(
            type: energyBurnedType,
            quantity: energyBurned,
            start: startTime,
            end: endTime
        )

        try await store.addSamples([sample], to: workout)
    }

    func authorize(identifiers: [HKQuantityTypeIdentifier]) async throws {
        let readSet: Set<HKSampleType> = Set(
            identifiers.map { .quantityType(forIdentifier: $0)! }
        )
        let writeSet: Set<HKSampleType> = [
            .quantityType(
                forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned
            )!,
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
        try await withCheckedThrowingContinuation { completion in
            let quantityType = HKQuantityType.quantityType(
                forIdentifier: identifier
            )!
            let predicate: NSPredicate? = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                // This option means the values must occur at date where
                // stateDate <= date < endDate.
                options: HKQueryOptions.strictEndDate
            )
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { (_: HKStatisticsQuery, result: HKStatistics?, error: Error?) in
                if let error {
                    completion.resume(throwing: error)
                } else {
                    let quantity: HKQuantity? = result?.averageQuantity()
                    let result = quantity?.doubleValue(for: unit)
                    completion.resume(returning: result ?? 0)
                }
            }
            store.execute(query)
        }
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
