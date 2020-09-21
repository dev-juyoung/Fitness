import Flutter
import UIKit
import HealthKit

public class SwiftFitnessPlugin: NSObject, FlutterPlugin {
    private let TAG = "[Plugins] Fitness"
    private static let CHANNEL = "plugins.juyoung.dev/fitness"
    
    // method names
    enum Method: String {
        case hasPermission
        case requestPermission
        case revokePermission
        case read
    }
    
    // argument keys
    private let ARG_DATE_FROM = "date_from"
    private let ARG_DATE_TO = "date_to"
    private let ARG_BUCKET_BY_TIME = "bucket_by_time"
    private let ARG_TIME_UNIT = "time_unit"
    
    // errors
    private let UNAUTHORIZED = "You cannot data read. user has not been authenticated."
    private let MISSING_REQUIRED_ARGUMENTS = "Missing Required Arguments."
    private let REQUEST_CANCELED = "Request Canceled"
    
    private let healthStore : HKHealthStore = HKHealthStore()
    private let dataType: HKSampleType = HKSampleType.quantityType(forIdentifier: .stepCount)!
    private let dataUnit: HKUnit = HKUnit.count()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: registrar.messenger())
        let instance = SwiftFitnessPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: TAG, message: "Not supported", details: nil))
            return
        }
        
        let method = Method.init(rawValue: call.method)
        switch method {
        case .hasPermission:
            hasPermission(call: call, result: result)
        case .requestPermission:
            requestPermission(call: call, result: result)
        case .revokePermission:
            revokePermission(call: call, result: result)
        case .read:
            read(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func hasPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 12.0, *) {
            healthStore.getRequestStatusForAuthorization(toShare: [], read: Set(arrayLiteral: dataType)) { status, error in
                guard error == nil else {
                    result(FlutterError(code: self.TAG, message: error.debugDescription, details: nil))
                    return
                }
                
                guard status == HKAuthorizationRequestStatus.unnecessary else {
                    result(false)
                    return
                }
                
                result(true)
            }
        } else {
            let authorized = healthStore.authorizationStatus(for: dataType) != HKAuthorizationStatus.notDetermined
            result(authorized)
        }
    }
    
    private func requestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        isAuthorized { success, error in
            guard success else {
                result(false)
                return
            }
            
            result(true)
        }
    }
    
    /**
     Not supported by HealthKit.
     */
    private func revokePermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(true)
    }
    
    private func read(call: FlutterMethodCall, result: @escaping FlutterResult) {
        isAuthorized { success, error in
            guard success else {
                result(error)
                return
            }
            
            self.query(call: call, result: result)
        }
    }
    
    private func query(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? Dictionary<String, Any>,
            let dateFromEpoch = arguments[ARG_DATE_FROM] as? NSNumber,
            let dateToEpoch = arguments[ARG_DATE_TO] as? NSNumber,
            let bucketByTime = arguments[self.ARG_BUCKET_BY_TIME] as? Int,
            let timeUnit = arguments[self.ARG_TIME_UNIT] as? String else {
                result(FlutterError(code: TAG, message: MISSING_REQUIRED_ARGUMENTS, details: nil))
                return
        }
        
        let dateFrom = Date(timeIntervalSince1970: dateFromEpoch.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: dateToEpoch.doubleValue / 1000)
        let interval = bucketByTime.interval(for: timeUnit)
        
        getPredicate(dateFrom: dateFrom, dateTo: dateTo) { predicate in
            let query = HKStatisticsCollectionQuery(quantityType: self.dataType as! HKQuantityType,
                                                    quantitySamplePredicate: predicate,
                                                    options: [.cumulativeSum],
                                                    anchorDate: dateFrom,
                                                    intervalComponents: interval)
            
            query.initialResultsHandler = { _, collectionOrNil, error in
                guard let collection = collectionOrNil else {
                    result([])
                    return
                }
                
                var samples: [(value: Double, startDate: Date, endDate: Date)] = []
                
                collection.enumerateStatistics(from: dateFrom, to: dateTo) { statistics, stop in
                    
                    if let quantity = statistics.sumQuantity() {
                        samples.append((quantity.doubleValue(for: self.dataUnit), statistics.startDate, statistics.endDate))
                    }
                }
                
                result(samples.map { sample -> NSDictionary in
                    [
                        "value": Int(sample.value),
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source": "HealthKit"
                    ]
                })
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func getPredicate(dateFrom: Date, dateTo: Date, completion: @escaping (NSPredicate) -> Void) {
        var sources: Set<HKSource> = Set()
        let predicate = HKQuery.predicateForSamples(withStart: dateFrom, end: dateTo, options: .strictStartDate)
        
        let query = HKSourceQuery(sampleType: dataType, samplePredicate: nil) { _, sourcesOrNil, error in
            guard let results = sourcesOrNil, error == nil else {
                completion(predicate)
                return
            }
            
            for source in results {
                if source.bundleIdentifier.hasPrefix("com.apple.health") {
                    sources.insert(source)
                }
            }
            
            completion(NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, HKQuery.predicateForObjects(from: sources)]))
        }
        
        healthStore.execute(query)
    }
    
    private func isAuthorized(completion: @escaping (Bool, FlutterError?) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: Set(arrayLiteral: dataType)) { success, error in
            guard success else {
                completion(false, FlutterError(code: self.TAG, message: error.debugDescription, details: nil))
                return
            }
            
            completion(true, nil)
        }
    }
}

extension Int {
    func interval(for unit: String) -> DateComponents {
        var components = DateComponents()
        
        switch (unit) {
        case "minutes":
            components.minute = self
        case "hours":
            components.hour = self
        case "days":
            components.day = self
        default:
            components.day = self
        }
        
        return components
    }
}
