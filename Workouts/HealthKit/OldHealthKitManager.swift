/*
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

         try await store.requestAuthorization(
             toShare: writeSet,
             read: readSet
         )
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

     private func categoryType(
         _ typeId: HKCategoryTypeIdentifier
     ) -> HKCategoryType {
         HKCategoryType.categoryType(forIdentifier: typeId)!
     }

     private func characteristicType(
         _ typeId: HKCharacteristicTypeIdentifier
     ) -> HKCharacteristicType {
         HKCharacteristicType.characteristicType(forIdentifier: typeId)!
     }

     private func dateRangePredicate(
         startDate: Date,
         endDate: Date?
     ) -> NSPredicate {
         HKQuery.predicateForSamples(
             withStart: startDate,
             end: endDate,
             options: .strictStartDate
         )
     }

     func getData(
         identifier: HKQuantityTypeIdentifier,
         startDate: Date? = nil,
         endDate: Date? = nil,
         frequency: Frequency? = nil,
         quantityFunction: (HKStatistics) -> HKQuantity?
     ) async throws -> [DatedValue] {
         guard let metric = Metrics.shared.map[identifier] else {
             throw "metric \(identifier.rawValue) not found"
         }

         let frequencyToUse = frequency ?? metric.frequency

         let interval =
             frequencyToUse == .minute ? DateComponents(minute: 1) :
             frequencyToUse == .hour ? DateComponents(hour: 1) :
             frequencyToUse == .day ? DateComponents(day: 1) :
             frequencyToUse == .week ? DateComponents(day: 7) :
             DateComponents(day: 1)

         let collection = try await queryQuantityCollection(
             typeId: metric.identifier,
             options: metric.option,
             startDate: startDate,
             endDate: endDate,
             interval: interval
         )

         var datedValues = collection.map { data -> DatedValue in
             let date = data.startDate
             let quantity = quantityFunction(data)
             let value = quantity?.doubleValue(for: metric.unit) ?? 0
             return DatedValue(
                 date: frequencyToUse == .day ? date.ymd : date.ymdh,
                 ms: date.milliseconds,
                 unit: metric.unit.unitString,
                 value: value
             )
         }

         if !datedValues.isEmpty,
            HealthKitViewModel.addZeros.contains(identifier) {
             for index in 0 ..< datedValues.count - 1 {
                 let current = datedValues[index]
                 let next = datedValues[index + 1]
                 let currentDate = Date.from(ms: current.ms)
                 let nextDate = Date.from(ms: next.ms)

                 if frequency == .hour {
                     let missing = currentDate.hoursBetween(date: nextDate) - 1
                     if missing > 0 {
                         for delta in 1 ... missing {
                             let date = currentDate.hoursAfter(delta)
                             let datedValue = DatedValue(
                                 date: date.ymdh,
                                 ms: date.milliseconds,
                                 unit: current.unit,
                                 value: 0.0
                             )
                             datedValues.insert(datedValue, at: index + delta)
                         }
                     }
                 } else if frequency == .day {
                     let missing = currentDate.daysBetween(date: nextDate) - 1
                     if missing > 0 {
                         for delta in 1 ... missing {
                             let date = currentDate.daysAfter(delta)
                             let datedValue = DatedValue(
                                 date: date.ymd,
                                 ms: date.milliseconds,
                                 unit: current.unit,
                                 value: 0.0
                             )
                             datedValues.insert(datedValue, at: index + delta)
                         }
                     }
                 }
             }
         }

         return datedValues
     }

     private func quantityType(
         _ typeId: HKQuantityTypeIdentifier
     ) -> HKQuantityType {
         HKQuantityType.quantityType(forIdentifier: typeId)!
     }

     func queryQuantityCollection(
         typeId: HKQuantityTypeIdentifier,
         options: HKStatisticsOptions,
         startDate: Date? = nil,
         endDate: Date? = nil,
         interval: DateComponents? = nil
     ) async throws -> [HKStatistics] {
         // Default end date is today.
         let end = endDate ?? Date()

         // Default start date is seven days before the end date.
         let start = startDate ?? end.daysBefore(7)

         // Default interval is one day.
         let intervalComponents = interval ?? DateComponents(day: 1)

         let query = HKStatisticsCollectionQuery(
             quantityType: quantityType(typeId),
             quantitySamplePredicate: dateRangePredicate(
                 startDate: start,
                 endDate: end
             ),
             options: options,
             anchorDate: Date.mondayAt12AM(), // defined in DateExtensions.swift
             intervalComponents: intervalComponents
         )
         return try await withCheckedThrowingContinuation { continuation in
             query.initialResultsHandler = { _, collection, error in
                 if let error = error {
                     Log.error(error)
                     if error.localizedDescription ==
                         "Authorization not determined" {
                         Task { await self.requestPermission() }
                     } else {
                         Log.error(error)
                     }
                     continuation.resume(throwing: error)
                 } else if let collection = collection {
                     let statistics = collection.statistics()
                     if statistics.count == 0 {
                         Task { await self.requestPermission() }
                     }
                     continuation.resume(returning: statistics)
                 } else {
                     Log.error("no data found")
                     continuation.resume(returning: [HKStatistics]())
                 }
             }
             store.execute(query)
         }
     }

     // swiftlint:disable function_body_length
     func requestAuthorization() async throws {
         // This throws if authorization could not be requested.
         // Not throwing is not an indication that the user
         // granted all the requested permissions.
         try await store.requestAuthorization(
             // The app can update these.
             toShare: [],
             // The app can read these.
             read: [
                 .activitySummaryType(),
                 .workoutType(),

                 // It seems there is both appleStandHour and appleStandHours.
                 // Are these just two names for the same thing?
                 categoryType(.appleStandHour),
                 categoryType(.handwashingEvent),
                 categoryType(.sleepAnalysis),
                 categoryType(.toothbrushingEvent),

                 characteristicType(.activityMoveMode),
                 characteristicType(.biologicalSex),
                 characteristicType(.bloodType),
                 characteristicType(.dateOfBirth),
                 characteristicType(.fitzpatrickSkinType),
                 characteristicType(.wheelchairUse),

                 quantityType(.activeEnergyBurned),
                 quantityType(.appleExerciseTime),
                 quantityType(.appleStandTime),
                 quantityType(.appleWalkingSteadiness),
                 quantityType(.basalEnergyBurned),

                 // This data must be supplied by a device like a Withings scale.
                 quantityType(.bodyFatPercentage),
                 quantityType(.bodyMass),
                 quantityType(.bodyMassIndex),
                 quantityType(.leanBodyMass),

                 quantityType(.distanceCycling),
                 // quantityType(.distanceDownhillSnowSports),
                 // quantityType(.distanceSwimming),
                 quantityType(.distanceWalkingRunning),

                 // Not getting data due to not using wheelchair
                 // and not enabling wheelchair mode.
                 quantityType(.distanceWheelchair),

                 // Not getting data.  Maybe Apple Watch can't measure this.
                 quantityType(.electrodermalActivity),

                 quantityType(.environmentalAudioExposure),

                 quantityType(.flightsClimbed),
                 quantityType(.headphoneAudioExposure),
                 quantityType(.heartRate),

                 // Values are in milliseconds.
                 // Normal values are between 20 and 200 ms.
                 quantityType(.heartRateVariabilitySDNN),

                 // Requires manual data entry in Health app.
                 quantityType(.height),

                 categoryType(.highHeartRateEvent),
                 categoryType(.irregularHeartRhythmEvent),
                 categoryType(.lowHeartRateEvent),

                 // Not getting data for this.
                 // What is required to get this data?
                 quantityType(.nikeFuel),

                 // I verified this with one fall on 4/3/22 that was
                 // triggered by catching a ball that was thrown hard.
                 quantityType(.numberOfTimesFallen),

                 // Values are between 0 and 1.
                 // Values between 0.95 and 1.0 are normal.
                 quantityType(.oxygenSaturation),

                 // Not getting data due to not using wheelchair
                 // and not enabling wheelchair mode.
                 quantityType(.pushCount),

                 // This is breaths per day.
                 quantityType(.respiratoryRate),

                 // This only provides one number per day.
                 quantityType(.restingHeartRate),

                 // One result per week is computed.
                 // The maximum value is 500m.
                 quantityType(.sixMinuteWalkTestDistance),

                 quantityType(.stairAscentSpeed),
                 quantityType(.stairDescentSpeed),
                 quantityType(.stepCount),

                 // I don't get any data because I haven't been swimming.
                 quantityType(.swimmingStrokeCount),

                 // It seems we cannot get uvExposure from a watch or phone.
                 quantityType(.uvExposure),

                 // In the Health app, this appears under "Cardio Fitness".
                 quantityType(.vo2Max),

                 // Requires manual data entry.
                 quantityType(.waistCircumference),

                 quantityType(.walkingAsymmetryPercentage),
                 quantityType(.walkingDoubleSupportPercentage),
                 quantityType(.walkingHeartRateAverage),
                 quantityType(.walkingSpeed),
                 quantityType(.walkingStepLength)
             ]
         )
     }

     func requestPermission() async {
         do {
             // Request permission from the user to access HealthKit data.
             // If they have already granted permission,
             // they will not be prompted again.
             Log.info("starting")
             try await requestAuthorization()
             Log.info("finished")
         } catch {
             Log.error(error)
         }
     }

     func statistics(
         identifier: HKQuantityTypeIdentifier,
         interval: DateComponents,
         unit: HKUnit,
         options: HKStatisticsOptions,
         startDate: Date,
         endDate: Date
     ) async throws -> [HKStatistics] {
         try await withCheckedThrowingContinuation { completion in
             let quantityType = HKQuantityType.quantityType(
                 forIdentifier: identifier
             )!
             let predicate: NSPredicate? = HKQuery.predicateForSamples(
                 withStart: startDate,
                 end: endDate
             )
             /*
              let query = HKSampleQuery(
                  sampleType: quantityType,
                  predicate: predicate,
                  limit: Int(HKObjectQueryNoLimit),
                  sortDescriptors: nil
              ) { (
                  _: HKSampleQuery,
                  results: [HKSample]?,
                  error: Error?
              ) in
                  if let error {
                      if error.localizedDescription
                          .starts(with: "No data available") {
                          completion.resume(returning: [])
                      } else {
                          completion.resume(throwing: error)
                      }
                  } else {
                      guard let samples = results as? [HKQuantitySample] else {
                          completion
                              .resume(throwing: "samples have unexpected type")
                          return
                      }
                      completion.resume(returning: samples)
                  }
              }
              */
             let query = HKStatisticsCollectionQuery(
                 quantityType: quantityType,
                 quantitySamplePredicate: predicate,
                 options: options,
                 anchorDate: startDate,
                 intervalComponents: interval
             )
             query.initialResultsHandler = { _, results, error in
                 if let error {
                     completion.resume(throwing: error)
                     return
                 }

                 if let results {
                     print("\(#fileID) \(#function) results =", results)
                     let stats = results.statistics()
                     print("\(#fileID) \(#function) stats =", stats)
                     completion.resume(returning: stats)
                 } else {
                     completion.resume(
                         throwing: "HealthKitManager.samples: no results"
                     )
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
                     if error.localizedDescription
                         .starts(with: "No data available") {
                         completion.resume(returning: 0)
                     } else {
                         completion.resume(throwing: error)
                     }
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
 */
