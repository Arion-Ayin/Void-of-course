import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Native Ad Factory
    let factory = NativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "listTile",
      nativeAdFactory: factory
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    if !engineBridge.pluginRegistry.hasPlugin("FirebaseAnalyticsPlugin") {
      GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
    
    // Register Native Ad Factory for the background/implicit engine as well
    let factory = NativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "listTile",
      nativeAdFactory: factory
    )
  }
}

// Custom Native Ad Factory for iOS (matches Android's listTile layout)
class NativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable : Any]?) -> NativeAdView? {
    let nativeAdView = NativeAdView()
    
    // Create elements programmatically
    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFit
    iconView.clipsToBounds = true
    iconView.layer.cornerRadius = 4
    
    let headlineView = UILabel()
    headlineView.font = UIFont.systemFont(ofSize: 15, weight: .bold)
    headlineView.textColor = .label // Adapts to Dark Mode
    headlineView.numberOfLines = 1
    
    let bodyView = UILabel()
    bodyView.font = UIFont.systemFont(ofSize: 12)
    bodyView.textColor = .secondaryLabel // Adapts to Dark Mode
    bodyView.numberOfLines = 2
    
    let callToActionView = UIButton(type: .system)
    callToActionView.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    callToActionView.setTitleColor(.white, for: .normal)
    callToActionView.backgroundColor = UIColor.systemBlue
    callToActionView.layer.cornerRadius = 4
    callToActionView.isUserInteractionEnabled = false // Let NativeAdView handle clicks
    
    // Add subviews
    nativeAdView.addSubview(iconView)
    nativeAdView.addSubview(headlineView)
    nativeAdView.addSubview(bodyView)
    nativeAdView.addSubview(callToActionView)
    
    // Register views with NativeAdView
    nativeAdView.iconView = iconView
    nativeAdView.headlineView = headlineView
    nativeAdView.bodyView = bodyView
    nativeAdView.callToActionView = callToActionView
    
    // Bind content
    headlineView.text = nativeAd.headline
    bodyView.text = nativeAd.body
    
    if let icon = nativeAd.icon {
      iconView.image = icon.image
      iconView.isHidden = false
    } else {
      iconView.isHidden = true
    }
    
    if let cta = nativeAd.callToAction {
      callToActionView.setTitle(cta, for: .normal)
      callToActionView.isHidden = false
    } else {
      callToActionView.isHidden = true
    }
    
    // Layout constraints
    iconView.translatesAutoresizingMaskIntoConstraints = false
    headlineView.translatesAutoresizingMaskIntoConstraints = false
    bodyView.translatesAutoresizingMaskIntoConstraints = false
    callToActionView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      // Icon
      iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
      iconView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 48),
      iconView.heightAnchor.constraint(equalToConstant: 48),
      
      // Headline
      headlineView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
      headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
      headlineView.trailingAnchor.constraint(equalTo: callToActionView.leadingAnchor, constant: -8),
      
      // Body
      bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 4),
      bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
      bodyView.trailingAnchor.constraint(equalTo: callToActionView.leadingAnchor, constant: -8),
      bodyView.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -8),
      
      // Call To Action
      callToActionView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
      callToActionView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
      callToActionView.widthAnchor.constraint(equalToConstant: 80),
      callToActionView.heightAnchor.constraint(equalToConstant: 32)
    ])
    
    nativeAdView.nativeAd = nativeAd
    return nativeAdView
  }
}
