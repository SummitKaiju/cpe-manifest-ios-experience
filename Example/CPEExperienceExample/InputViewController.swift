//
//  InputViewController.swift
//

import UIKit
import AVKit
import MediaPlayer
import CPEData
import CPEExperience
import MBProgressHUD
import GoogleMaps

struct Config {

    private struct Constants {
        struct ConfigKey {
            static let TheTakeAPI = "thetake_api_key"
            static let BaselineAPI = "baseline_api_key"
            static let GoogleMapsAPI = "google_maps_api_key"
        }
    }

    static var theTakeAPIKey: String?
    static var baselineAPIKey: String?

    static func load() {
        UIFont.loadFonts()

        // Load configuration file
        if let configDataPath = Bundle.main.path(forResource: "Data/config", ofType: "json") {
            do {
                let configData = try Data(contentsOf: URL(fileURLWithPath: configDataPath), options: NSData.ReadingOptions.mappedIfSafe)
                if let configJSON = try JSONSerialization.jsonObject(with: configData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    theTakeAPIKey = configJSON[Constants.ConfigKey.TheTakeAPI] as? String
                    baselineAPIKey = configJSON[Constants.ConfigKey.BaselineAPI] as? String

                    if let key = configJSON[Constants.ConfigKey.GoogleMapsAPI] as? String {
                        GMSServices.provideAPIKey(key)
                        CPEXMLSuite.Settings.mapsAPIService = .googleMaps
                        CPEXMLSuite.Settings.mapsAPIKey = key
                    }
                }
            } catch {
                print("Error parsing config file: \(error.localizedDescription)")
            }
        } else {
            print("Configuration file not found")
        }
    }

}

class InputViewController: UIViewController {

    private struct Constants {
        static let BigBuckBunnyURL = URL(string: "http://pdl.warnerbros.com/digitalcopy2/s/bbb/big_buck_bunny_480p_h264.mov")!
    }

    @IBOutlet weak private var manifestXMLTextField: UITextField!
    @IBOutlet weak private var appDataXMLTextField: UITextField!
    @IBOutlet weak private var cpeStyleXMLTextField: UITextField!
    @IBOutlet weak private var mainFeatureTextField: UITextField!

    private var hud: MBProgressHUD?
    fileprivate var mainFeatureURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        ExperienceLauncher.delegate = self

        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapView))
        self.view.addGestureRecognizer(singleTapGestureRecognizer)

        manifestXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.2_Manifest.xml"
        appDataXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.1_AppData.xml"
        cpeStyleXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.1_style.xml"
        mainFeatureTextField.text = Constants.BigBuckBunnyURL.absoluteString
    }

    @objc private func onTapView() {
        manifestXMLTextField.endEditing(true)
        appDataXMLTextField.endEditing(true)
        cpeStyleXMLTextField.endEditing(true)
        mainFeatureTextField.endEditing(true)
    }

    @IBAction private func onLoad() {
        if let manifestXMLURLString = manifestXMLTextField.text, let manifestXMLURL = URL(string: manifestXMLURLString) {
            hud = MBProgressHUD.showAdded(to: self.view, animated: true)

            var appDataXMLURL: URL?
            var cpeStyleXMLURL: URL?
            if let appDataXMLURLString = appDataXMLTextField.text {
                appDataXMLURL = URL(string: appDataXMLURLString)
            }

            if let cpeStyleXMLURLString = cpeStyleXMLTextField.text {
                cpeStyleXMLURL = URL(string: cpeStyleXMLURLString)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                if let key = Config.theTakeAPIKey {
                    CPEXMLSuite.Settings.productAPIUtil = TheTakeAPIUtil(apiKey: key)
                }

                if let key = Config.baselineAPIKey {
                    CPEXMLSuite.Settings.talentAPIUtil = BaselineAPIUtil(apiKey: key)
                }

                CPEXMLSuite.load(manifestXMLURL: manifestXMLURL, appDataXMLURL: appDataXMLURL, cpeStyleXMLURL: cpeStyleXMLURL) { (error) in
                    DispatchQueue.main.async {
                        self.hud?.hide(true)

                        if let error = error {
                            let alertController = UIAlertController(title: "Error parsing files", message: "\(error)", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.navigationController?.present(alertController, animated: true, completion: nil)
                        } else {
                            DispatchQueue.main.async {
                                if let urlString = self.mainFeatureTextField.text, let url = URL(string: urlString) {
                                    self.mainFeatureURL = url
                                } else {
                                    self.mainFeatureURL = Constants.BigBuckBunnyURL
                                }

                                ExperienceLauncher.launch(fromViewController: self)
                            }
                        }
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Error parsing files", message: "The specified Manifest XML file could not be found.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.navigationController?.present(alertController, animated: true, completion: nil)
        }
    }

}

extension InputViewController: ExperienceDelegate {

    func connectionStatusChanged(status: ConnectionStatus) {
        // Respond to any changes in the user's connection status (e.g. display prompt about cellular data usage)
    }

    @objc func experienceWillOpen() {
        // Any start-up tasks
    }

    @objc func experienceWillClose() {
        // Any shutdown tasks
    }

    @objc func experienceWillEnterDebugMode() {
        // Perform any debug tasks or unlock any debug sections of the app
        // Debug mode is activated by tapping and holding the "Extras" button on the home screen for five seconds
    }

    @objc public func previewModeShouldLaunchBuy() {
        // Callback for when the user taps the home screen buy button
    }

    @objc func interstitialShouldPlayMultipleTimes() -> Bool {
        // Return true if interstitial video should play again after user has already seen it (with ability to skip)
        return true
    }

    func urlForSharedContent(id: String, type: SharedContentType, completion: @escaping (URL?) -> Void) {
        var shareUrl = "your-domain.com"

        if type == .image {
            shareUrl += "/share/images"
        } else {
            shareUrl += "/share/videos"
        }

        shareUrl += "/" + id
        completion(URL(string: shareUrl))
    }

    func didFinishPlayingAsset(_ playbackAsset: PlaybackAsset, mode: VideoPlayerMode) {
        // Handle end of playback

        if mode == .mainFeature {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    func playbackAsset(withURL url: URL, title: String?, imageURL: URL?, forMode mode: VideoPlayerMode, completion: @escaping (PlaybackAsset) -> Void) {
        // Handle DRM
        if mode == .mainFeature {
            // TODO: Replace the this asset handler with your DRM flow
            completion(ExamplePlaybackAsset(id: url.absoluteString, url: mainFeatureURL!, title: "CPE Experience Test Title"))
        } else {
            completion(ExamplePlaybackAsset(id: url.absoluteString, url: url, title: title, imageURL: imageURL))
        }
    }

    @objc func didTapFilmography(forTitle title: String, fromViewController viewController: UIViewController) {
        let showQueryNotFound = {
            let alertController = UIAlertController(title: "", message: "Sorry, but this movie is currently unavailable on iTunes", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            viewController.present(alertController, animated: true, completion: nil)
        }

        if let searchUrl = URL(string: "https://itunes.apple.com/search?media=movie&entity=movie&term=\(title.replacingOccurrences(of: " ", with: "+"))") {
            let hud = MBProgressHUD.showAdded(to: viewController.view, animated: true)
            URLSession.shared.dataTask(with: searchUrl, completionHandler: { (data, _, error) in
                DispatchQueue.main.async {
                    hud?.hide(true)
                    if let data = data {
                        do {
                            if let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary, let urlString = (jsonResult["results"] as? [NSDictionary])?.first?["trackViewUrl"] as? String, let url = URL(string: urlString) {
                                url.promptLaunch(type: .itunes)
                            } else {
                                showQueryNotFound()
                            }
                        } catch {
                            print("Error parsing iTunes data: \(error)")
                            showQueryNotFound()
                        }
                    }
                }
            }).resume()
        } else {
            showQueryNotFound()
        }
    }

    func logAnalyticsEvent(_ event: AnalyticsEvent, action: AnalyticsAction, itemId: String?, itemName: String?) {
        // Adjust values as needed for your analytics implementation

        /* Take the provided parameters and construct the Google Analytics-specific properties that will be sent to log the event */
        /* let category = event.rawValue
         let action = action.rawValue
         var label: String
         if let itemId = itemId, let itemName = itemName {
         label = itemId + " - " + itemName
         } else {
         label = itemId ?? itemName ?? ""
         } */

        /* Google Analytics allows you to add custom dimensions. Use this dictionary to insert values related to this event,
         where they key is the custom dimension ID provided by Google Analytics */
        /* let tracker = GAI.sharedInstance().defaultTracker
         var customDimensions = [Int: String]()
         
         for (customDimension, value) in customDimensions {
         tracker?.set(GAIFields.customDimension(for: customDimension.rawValue), value: value)
         } */

        /* Build the Google Analytics event dictionary and send to tracker */
        /* if let builder = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: nil), let parameters = NSDictionary(dictionary: builder.build()) as? [AnyHashable: Any] {
         tracker?.send(parameters)
         } */
    }

}
