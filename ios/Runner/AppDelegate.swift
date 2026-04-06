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

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let apiKey = resolvedGoogleMapsApiKey()
    if !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }

    if let registrar = self.registrar(forPlugin: "RunnerAppChannels") {
      setupChannels(binaryMessenger: registrar.messenger())
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
        result(CLLocationManager.locationServicesEnabled())
      case "getCurrentLocation":
        self.handleGetCurrentLocation(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func resolvedGoogleMapsApiKey() -> String {
    let infoKey = (Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !infoKey.isEmpty {
      return infoKey
    }

    let envKey = (ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return envKey
  }

  private func handleGetCurrentLocation(result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result(FlutterError(code: "location_disabled", message: "Location services are disabled", details: nil))
      return
    }

    if pendingLocationResult != nil {
      result(FlutterError(code: "location_in_progress", message: "Location request is already in progress", details: nil))
      return
    }

    pendingLocationResult = result
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest

    let status = locationManager.authorizationStatus
    switch status {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.requestLocation()
    case .restricted, .denied:
      completeLocationResult(
        FlutterError(code: "location_permission_denied", message: "Location permission denied", details: nil)
      )
    @unknown default:
      completeLocationResult(
        FlutterError(code: "location_permission_unknown", message: "Unknown location permission state", details: nil)
      )
    }
  }

  private func completeLocationResult(_ value: Any) {
    if let callback = pendingLocationResult {
      callback(value)
      pendingLocationResult = nil
    }
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      if pendingLocationResult != nil {
        locationManager.requestLocation()
      }
    case .restricted, .denied:
      completeLocationResult(
        FlutterError(code: "location_permission_denied", message: "Location permission denied", details: nil)
      )
    default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      completeLocationResult(
        FlutterError(code: "location_unavailable", message: "Unable to get current location", details: nil)
      )
      return
    }

    completeLocationResult([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    completeLocationResult(
      FlutterError(code: "location_error", message: error.localizedDescription, details: nil)
    )
  }
}
