import HealthKit

struct Metric: Hashable, Identifiable {
    let name: String
    let identifier: HKQuantityTypeIdentifier
    let unit: HKUnit
    let option: HKStatisticsOptions
    let frequency: Frequency
    let lowerIsBetter: Bool
    let decimalPlaces: Int

    var id = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class Metrics {
    static let shared = Metrics()

    var map: [HKQuantityTypeIdentifier: Metric] = [:]

    var sorted: [Metric] {
        map.values.sorted { $0.name < $1.name }
    }

    // This class is a singleton.
    // swiftlint:disable function_body_length
    private init() {
        addMetricSum(
            name: "Active Energy Burned",
            identifier: .activeEnergyBurned,
            unit: .largeCalorie(),
            frequency: .hour
        )
        addMetricSum(
            name: "Exercise Time",
            identifier: .appleExerciseTime,
            unit: .minute(),
            decimalPlaces: 0
        )
        addMetricSum(
            name: "Stand Time",
            identifier: .appleStandTime,
            unit: .minute(),
            decimalPlaces: 0
        )
        addMetricSum(
            name: "Resting Energy Burned",
            identifier: .basalEnergyBurned,
            unit: .largeCalorie(),
            frequency: .hour
        )
        addMetricSum(
            name: "Distance Cycling",
            identifier: .distanceCycling,
            unit: .mile()
        )
        addMetricSum(
            name: "Distance Walking & Running",
            identifier: .distanceWalkingRunning,
            unit: .mile()
        )
        /*
          addMetricSum(
              name: "Distance Wheelchair",
              identifier: .distanceWheelchair,
              unit: .mile()
          )
         */
        addMetricAverage(
            name: "Environmental Audio Exposure",
            identifier: .environmentalAudioExposure,
            unit: HKUnit(from: "dBASPL"),
            lowerIsBetter: true
        )
        addMetricSum(
            name: "Flights Climbed",
            identifier: .flightsClimbed,
            unit: .count()
        )
        addMetricAverage(
            name: "Headphone Audio Exposure",
            identifier: .headphoneAudioExposure,
            unit: HKUnit(from: "dBASPL"),
            lowerIsBetter: true
        )
        addMetricAverage(
            name: "Heart Rate",
            identifier: .heartRate,
            unit: HKUnit(from: "count/min"),
            frequency: .minute,
            lowerIsBetter: true,
            decimalPlaces: 0
        )
        /*
           addMetricSum(
               name: "Wheelchair Push Count",
               identifier: .pushCount,
               unit: .count(),
               frequency: .hour
           )
         */
        addMetricAverage(
            name: "Resting Heart Rate",
            identifier: .restingHeartRate,
            unit: HKUnit(from: "count/min"),
            lowerIsBetter: true,
            decimalPlaces: 0
        )
        addMetricAverage(
            name: "Stair Ascent Speed",
            identifier: .stairAscentSpeed,
            unit: HKUnit(from: "ft/s")
        )
        addMetricAverage(
            name: "Stair Descent Speed",
            identifier: .stairDescentSpeed,
            unit: HKUnit(from: "ft/s")
        )
        addMetricSum(
            name: "Step Count",
            identifier: .stepCount,
            unit: .count(),
            frequency: .hour
        )

        let mL = HKUnit.literUnit(with: .milli)
        let kgMin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
        // This is reported as "Cardio Fitness" in the Apple Health app.
        addMetricAverage(
            name: "VO2 Max",
            identifier: .vo2Max,
            unit: mL.unitDivided(by: kgMin)
        )

        addMetricAverage(
            name: "Walking Asymmetry %",
            identifier: .walkingAsymmetryPercentage,
            unit: .percent(),
            lowerIsBetter: true
        )
        addMetricAverage(
            name: "Walking Double Support %",
            identifier: .walkingDoubleSupportPercentage,
            unit: .percent(),
            lowerIsBetter: true
        )
        addMetricAverage(
            name: "Walking Speed",
            identifier: .walkingSpeed,
            unit: HKUnit(from: "m/s"), // meters per second
            frequency: .hour
        )
        addMetricAverage(
            name: "Walking Step Length",
            identifier: .walkingStepLength,
            unit: .inch()
        )
    }

    private func addMetricAverage(
        name: String,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        frequency: Frequency = .day,
        lowerIsBetter: Bool = false,
        decimalPlaces: Int = 2
    ) {
        map[identifier] = Metric(
            name: name,
            identifier: identifier,
            unit: unit,
            option: .discreteAverage,
            frequency: frequency,
            lowerIsBetter: lowerIsBetter,
            decimalPlaces: decimalPlaces
        )
    }

    private func addMetricSum(
        name: String,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        frequency: Frequency = .day,
        lowerIsBetter: Bool = false,
        decimalPlaces: Int = 2
    ) {
        map[identifier] = Metric(
            name: name,
            identifier: identifier,
            unit: unit,
            option: .cumulativeSum,
            frequency: frequency,
            lowerIsBetter: lowerIsBetter,
            decimalPlaces: decimalPlaces
        )
    }

    func metric(named: String) -> Metric? {
        sorted.first { $0.name == named }
    }
}
