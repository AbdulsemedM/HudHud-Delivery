import Flutter
import UIKit
import GoogleMaps
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private let configChannelName = "hudhud_delivery/config"
  private let locationChannelName = "custom_location"
  private let locationManager = CLLocationManager()
  private var pendingLocationResult: FlutterResult?
  private var locationTimeoutWorkItem: DispatchWorkItem?
  private var authorizationTimeoutWorkItem: DispatchWorkItem?
  private var hasRetriedWithReducedAccuracy = false
  private var isUpdatingLocation = false

  private let cachedLocationMaxAgeSeconds: TimeInterval = 60
  private let locationRequestTimeoutSeconds: TimeInterval = 15
  private let authorizationTimeoutSeconds: TimeInterval = 30

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let apiKey = resolvedGoogleMapsApiKey()
    if !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }

    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let messenger = flutterBinaryMessenger() {
      setupChannels(binaryMessenger: messenger)
    }

    return didFinish
  }

  private func flutterBinaryMessenger() -> FlutterBinaryMessenger? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller.binaryMessenger
    }
    if let registrar = registrar(forPlugin: "RunnerAppChannels") {
      return registrar.messenger()
    }
    return nil
  }

  private func setupChannels(binaryMessenger: FlutterBinaryMessenger) {
    let configChannel = FlutterMethodChannel(
      name: configChannelName,
      binaryMessenger: binaryMessenger
    )
    configChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      if call.method == "getGoogleMapsApiKey" {
        result(self.resolvedGoogleMapsApiKey())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let locationChannel = FlutterMethodChannel(
      name: locationChannelName,
      binaryMessenger: binaryMessenger
    )
    locationChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "isLocationServiceEnabled":
        result(self.isLocationUsable())
      case "getCurrentLocation":
        self.handleGetCurrentLocation(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func resolvedGoogleMapsApiKey() -> String {
    let infoKey = (Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !infoKey.isEmpty {
      return infoKey
    }

    let envKey = (ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return envKey
  }

  /// Prefer authorization status over deprecated locationServicesEnabled().
  private func isLocationUsable() -> Bool {
    switch locationManager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      return true
    case .notDetermined:
      return CLLocationManager.locationServicesEnabled()
    case .restricted, .denied:
      return false
    @unknown default:
      return CLLocationManager.locationServicesEnabled()
    }
  }

  private func handleGetCurrentLocation(result: @escaping FlutterResult) {
    // Replace any in-flight request instead of rejecting with location_in_progress.
    if pendingLocationResult != nil {
      cancelActiveLocationRequest(clearPending: true)
    }

    pendingLocationResult = result
    hasRetriedWithReducedAccuracy = false
    locationManager.delegate = self
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.desiredAccuracy = kCLLocationAccuracyBest

    let status = locationManager.authorizationStatus
    switch status {
    case .notDetermined:
      scheduleAuthorizationTimeout()
      locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      beginLocationRequest()
    case .restricted, .denied:
      completeLocationResult(
        FlutterError(
          code: "location_permission_denied",
          message: "Location permission denied",
          details: nil
        )
      )
    @unknown default:
      completeLocationResult(
        FlutterError(
          code: "location_permission_unknown",
          message: "Unknown location permission state",
          details: nil
        )
      )
    }
  }

  private func beginLocationRequest() {
    authorizationTimeoutWorkItem?.cancel()
    authorizationTimeoutWorkItem = nil

    if let cached = recentValidLocation(from: locationManager.location) {
      deliverLocation(cached)
      return
    }

    scheduleLocationTimeout()
    startContinuousLocationUpdates()
  }

  private func recentValidLocation(from location: CLLocation?) -> CLLocation? {
    guard let location, isValidLocation(location) else { return nil }
    let age = abs(location.timestamp.timeIntervalSinceNow)
    guard age <= cachedLocationMaxAgeSeconds else { return nil }
    return location
  }

  private func isValidLocation(_ location: CLLocation) -> Bool {
    location.horizontalAccuracy >= 0
  }

  private func startContinuousLocationUpdates() {
    guard !isUpdatingLocation else { return }
    isUpdatingLocation = true
    locationManager.startUpdatingLocation()
  }

  private func stopContinuousLocationUpdates() {
    guard isUpdatingLocation else { return }
    isUpdatingLocation = false
    locationManager.stopUpdatingLocation()
  }

  private func cancelActiveLocationRequest(clearPending: Bool) {
    locationTimeoutWorkItem?.cancel()
    locationTimeoutWorkItem = nil
    authorizationTimeoutWorkItem?.cancel()
    authorizationTimeoutWorkItem = nil
    stopContinuousLocationUpdates()
    hasRetriedWithReducedAccuracy = false
    if clearPending {
      pendingLocationResult = nil
    }
  }

  private func scheduleLocationTimeout() {
    locationTimeoutWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self, self.pendingLocationResult != nil else { return }
      self.cancelActiveLocationRequest(clearPending: false)
      self.completeLocationResult(
        FlutterError(
          code: "location_timeout",
          message: "Timed out waiting for GPS fix",
          details: nil
        )
      )
    }
    locationTimeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + locationRequestTimeoutSeconds,
      execute: workItem
    )
  }

  private func scheduleAuthorizationTimeout() {
    authorizationTimeoutWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self, self.pendingLocationResult != nil else { return }
      self.cancelActiveLocationRequest(clearPending: false)
      self.completeLocationResult(
        FlutterError(
          code: "location_permission_denied",
          message: "Location permission was not granted",
          details: nil
        )
      )
    }
    authorizationTimeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + authorizationTimeoutSeconds,
      execute: workItem
    )
  }

  private func deliverLocation(_ location: CLLocation) {
    cancelActiveLocationRequest(clearPending: false)
    completeLocationResult([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy,
    ])
  }

  private func completeLocationResult(_ value: Any) {
    locationTimeoutWorkItem?.cancel()
    locationTimeoutWorkItem = nil
    authorizationTimeoutWorkItem?.cancel()
    authorizationTimeoutWorkItem = nil
    stopContinuousLocationUpdates()

    if let callback = pendingLocationResult {
      callback(value)
      pendingLocationResult = nil
    }
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    guard pendingLocationResult != nil else { return }

    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      beginLocationRequest()
    case .restricted, .denied:
      completeLocationResult(
        FlutterError(
          code: "location_permission_denied",
          message: "Location permission denied",
          details: nil
        )
      )
    case .notDetermined:
      break
    @unknown default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard pendingLocationResult != nil else { return }

    let validLocations = locations.filter { isValidLocation($0) }
    guard let location = validLocations.last else { return }

    deliverLocation(location)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard pendingLocationResult != nil else { return }

    let nsError = error as NSError
    if nsError.domain == kCLErrorDomain,
       nsError.code == CLError.Code.locationUnknown.rawValue,
       !hasRetriedWithReducedAccuracy {
      hasRetriedWithReducedAccuracy = true
      stopContinuousLocationUpdates()
      locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      scheduleLocationTimeout()
      startContinuousLocationUpdates()
      return
    }

    cancelActiveLocationRequest(clearPending: false)
    completeLocationResult(
      FlutterError(
        code: "location_error",
        message: error.localizedDescription,
        details: nil
      )
    )
  }
}
