# CPEExperience
An enhanced 'extras' experience around user owned content, built for iOS in accordance with a variety of [MovieLabs Specifications & Standards](http://movielabs.com/md/manifest/index.html). This reference library is built to allow implementators to accelerate their Cross-Platform Extras iOS implementation.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate CPEExperience into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CPEExperience', '~> 4.1'
end
```

Then, run the following command:

```bash
$ pod install
```

### Setup
#### Notifications
Add the following notifications that will surface `AppDelegate` method calls to the CPEExperience library:
```swift
func applicationWillEnterForeground(_ application: UIApplication) {
    NotificationCenter.default.post(name: .applicationWillEnterForeground, object: nil)
}

func applicationWillResignActive(_ application: UIApplication) {
    NotificationCenter.default.post(name: .applicationWillResignActive, object: nil)
}
```

#### Delegates
Implement the `ExperienceDelegate` interface on any of your base applications' classes and add the required methods:
```swift
// Connection status
func connectionStatusChanged(status: ConnectionStatus)

// Experience status
func experienceWillOpen()
func experienceWillClose()
func experienceWillEnterDebugMode()

// Preview mode callbacks
func previewModeShouldLaunchBuy()

// Video Player callbacks
func interstitialShouldPlayMultipleTimes() -> Bool
func playbackAsset(withURL url: URL, title: String?, imageURL: URL?, forMode mode: VideoPlayerMode, completion: @escaping (PlaybackAsset) -> Void)
func didFinishPlayingAsset(_ playbackAsset: PlaybackAsset, mode: VideoPlayerMode)

// Sharing callbacks
func urlForSharedContent(id: String, type: SharedContentType, completion: @escaping (_ url: URL?) -> Void)

// Talent callbacks
func didTapFilmography(forTitle title: String, fromViewController viewController: UIViewController)

// Analytics
func logAnalyticsEvent(_ event: AnalyticsEvent, action: AnalyticsAction, itemId: String?, itemName: String?)
```
See the [`InputViewController`](https://github.com/warnerbros/cpe-manifest-ios-experience/blob/master/Example/CPEExperienceExample/InputViewController.swift) class in the example project for an example of this implementation.

#### Chromecast
If you will be supporting Google Chromecast playback from the video player, please add the following initialization call to your base application, preferrably in the `AppDelegate`'s `application:didFinishLaunchingWithOptions:` method, replacing the parameter with your Chromecast application ID:
```swift
CastManager.sharedInstance.start(withReceiverAppID: "x")
```

## Example Project Usage

Open `Example/CPEExperienceExampleWorkspace.xcworkspace` in Xcode to build and run the sample project, which contains a reference to the required calls and delegate hooks to integrate the Cross-Platform Extras Experience into your video platform.
