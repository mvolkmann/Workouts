/*
 import HealthKit
 import SwiftUI

 @MainActor
 class HealthKitViewModel: ObservableObject {
     @EnvironmentObject private var errorVM: ErrorViewModel

     // These values are the sum over the past seven days.
     @Published private(set) var activeEnergyBurned: Double = 0
     @Published private(set) var basalEnergyBurned: Double = 0
     @Published private(set) var heartRate: Double = 0
     @Published private(set) var restingHeartRate: Double = 0
     @Published private(set) var steps: Double = 0

     // These values are the sum since the beginning of the year.
     @Published private(set) var distanceCycling: Double = 0
     @Published private(set) var distanceSwimming: Double = 0
     @Published private(set) var distanceWalkingRunning: Double = 0

     static let addZeros: Set<HKQuantityTypeIdentifier> = [
         .distanceCycling, .distanceWalkingRunning, .distanceWheelchair,
         .numberOfTimesFallen, .pushCount, .stepCount
     ]

     func load() async {
         let manager = HealthKitManager()
         do {
             try await manager.authorize(
                 read: [
                     .activeEnergyBurned,
                     .basalEnergyBurned, // resting energy
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

             let endDate = Date.now
             let startDate = Calendar.current.date(
                 byAdding: DateComponents(day: -7),
                 to: endDate,
                 wrappingComponents: false
             )!

             activeEnergyBurned = try await manager.sum(
                 identifier: .activeEnergyBurned,
                 unit: .largeCalorie(),
                 startDate: startDate,
                 endDate: endDate
             )
             basalEnergyBurned = try await manager.sum(
                 identifier: .basalEnergyBurned,
                 unit: .largeCalorie(),
                 startDate: startDate,
                 endDate: endDate
             )
             distanceCycling = try await manager.sum(
                 identifier: .distanceCycling,
                 unit: .mile(),
                 startDate: endDate.startOfYear,
                 endDate: endDate
             )
             distanceSwimming = try await manager.sum(
                 identifier: .distanceSwimming,
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
             let bpm = HKUnit(from: "count/min")
             heartRate = try await manager.average(
                 identifier: .heartRate,
                 unit: bpm,
                 startDate: startDate,
                 endDate: endDate
             )
             restingHeartRate = try await manager.average(
                 identifier: .restingHeartRate,
                 unit: bpm,
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
             errorVM.alert(
                 error: error,
                 message: "Error getting health data."
             )
         }
     }
 }
 */
