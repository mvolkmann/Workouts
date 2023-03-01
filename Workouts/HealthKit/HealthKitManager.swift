import HealthKit

class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    private let distanceMap: [String: HKQuantityTypeIdentifier] = [
        "Cycling": .distanceCycling,
        "Hiking": .distanceWalkingRunning,
        "Running": .distanceWalkingRunning,
        "Swimming": .distanceSwimming,
        "Walking": .distanceWalkingRunning
    ]

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

        let energyBurnedType =
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyBurnedQuantity = HKQuantity(
            unit: .largeCalorie(),
            doubleValue: Double(calories)
        )
        let energySample = HKQuantitySample(
            type: energyBurnedType,
            quantity: energyBurnedQuantity,
            start: startTime,
            end: endTime
        )
        var samples: [HKSample] = [energySample]

        var distanceQuantity: HKQuantity?

        if distanceWorkouts.contains(workoutType),
           let identifier = distanceMap[workoutType] {
            let distanceType =
                HKObjectType.quantityType(forIdentifier: identifier)!
            let preferKM =
                UserDefaults.standard.bool(forKey: "preferKilometers")
            let unit: HKUnit = preferKM ? HKUnit.meter() : HKUnit.mile()
            let unitDistance = !distanceWorkouts.contains(workoutType) ?
                0 :
                (preferKM ? distance * 1000 : distance)
            distanceQuantity = HKQuantity(
                unit: unit,
                doubleValue: unitDistance
            )

            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity!,
                start: startTime,
                end: endTime
            )
            samples.append(distanceSample)
        }

        // See https://developer.apple.com/forums/thread/725572
        // I couldn't get this approach to work,
        // so I'm creating an HKWorkout instead.
        /*
         let configuration = HKWorkoutConfiguration()
         configuration.activityType = activityType
         let workoutBuilder = HKWorkoutBuilder(
             healthStore: store,
             configuration: configuration,
             device: nil
         )
         try await workoutBuilder.beginCollection(at: startTime)
         try await workoutBuilder.addSamples(samples)
         try await workoutBuilder.endCollection(at: endTime)
         try await workoutBuilder.finishWorkout()
         */

        let workout = HKWorkout(
            activityType: activityType,
            start: startTime,
            end: endTime,
            duration: 0, // computed from start and end data
            totalEnergyBurned: energyBurnedQuantity,
            totalDistance: distanceQuantity,
            metadata: nil
        )
        try await store.save(workout)
        try await store.addSamples(samples, to: workout)
    }

    func authorize(
        read: [HKQuantityTypeIdentifier],
        write: [HKQuantityTypeIdentifier]
    ) async throws {
        let readSet: Set<HKSampleType> = Set(
            read.map { .quantityType(forIdentifier: $0)! }
        )

        var writeSet: Set<HKSampleType> = Set(
            write.map { .quantityType(forIdentifier: $0)! }
        )
        writeSet.insert(HKWorkoutType.workoutType())

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
        return try await withCheckedThrowingContinuation { completion in
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
