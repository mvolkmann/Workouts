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
        guard let activityType = activityMap[workoutType] else {
            throw "no activity type found for \(workoutType)"
        }

        let preferKM = UserDefaults.standard.bool(forKey: "preferKilometers")
        let unit: HKUnit = preferKM ? HKUnit.meter() : HKUnit.mile()
        let unitDistance = !distanceWorkouts.contains(workoutType) ?
            0 :
            (preferKM ? distance * 1000 : distance)
        let distanceQuantity = HKQuantity(
            unit: unit,
            doubleValue: unitDistance
        )

        let energyBurnedQuantity = HKQuantity(
            unit: .largeCalorie(),
            doubleValue: Double(calories)
        )

        let workout = HKWorkout(
            activityType: activityType,
            start: startTime,
            end: endTime,
            duration: 0, // compute from start and end data
            // See https://forums.swift.org/t/healthkit-hkworkout-totalenergyburn/63359
            // and https://developer.apple.com/forums/thread/725572.
            totalEnergyBurned: energyBurnedQuantity,
            totalDistance: distanceQuantity,
            metadata: nil
        )
        try await store.save(workout)

        let distanceType = HKObjectType.quantityType(
            forIdentifier: .distanceCycling
        )!
        let distanceSample = HKQuantitySample(
            type: distanceType,
            quantity: distanceQuantity,
            start: startTime,
            end: endTime
        )

        let energyBurnedType = HKObjectType.quantityType(
            forIdentifier: .activeEnergyBurned
        )!
        let energySample = HKQuantitySample(
            type: energyBurnedType,
            quantity: energyBurnedQuantity,
            start: startTime,
            end: endTime
        )

        // TODO: Why doesn't the Health app show a new entry under
        // TODO: "Cycling Distance" when the activityType is .cycling?
        // TODO: Probably have the same issue for all other activity types
        // TODO: that include a distance.
        // See https://developer.apple.com/forums/thread/725645.
        // TODO: Perhaps adding distanceSample here fixes the problem!
        try await store.addSamples([distanceSample, energySample], to: workout)
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
                end: endDate
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
        try await withCheckedThrowingContinuation { completion in
            let quantityType = HKQuantityType.quantityType(
                forIdentifier: identifier
            )!
            let predicate: NSPredicate? = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate
            )
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { (_: HKStatisticsQuery, result: HKStatistics?, error: Error?) in
                if let error {
                    completion.resume(throwing: error)
                } else {
                    let quantity: HKQuantity? = result?.sumQuantity()
                    let result = quantity?.doubleValue(for: unit)
                    completion.resume(returning: result ?? 0)
                }
            }
            store.execute(query)
        }
    }
}
