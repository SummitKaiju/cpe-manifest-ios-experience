//
//  SecondTemplateViewController.swift
//

import UIKit

class ExtrasVideoGalleryViewController: ExtrasExperienceViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak private var galleryTableView: UITableView!
    
    @IBOutlet weak private var videoContainerView: UIView!
    @IBOutlet weak private var previewImageView: UIImageView?
    @IBOutlet weak private var previewPlayButton: UIButton?
    @IBOutlet weak private var mediaTitleLabel: UILabel!
    @IBOutlet weak private var mediaDescriptionLabel: UILabel!
    @IBOutlet weak private var mediaRuntimeLabel: UILabel!
    private var videoPlayerViewController: VideoPlayerViewController?
    
    @IBOutlet weak private var galleryScrollView: ImageGalleryScrollView!
    @IBOutlet weak private var galleryPageControl: UIPageControl!
    @IBOutlet weak private var turntableSlider: UISlider!
    private var galleryDidScrollToPageObserver: NSObjectProtocol?
    
    private var didPlayFirstItem = false
    private var previewPlayURL: NSURL?
    private var userDidSelectNextItem = true
    
    private var willPlayNextItemObserver: NSObjectProtocol?
    
    // MARK: Initialization
    deinit {
        let center = NSNotificationCenter.defaultCenter()
        
        if let observer = willPlayNextItemObserver {
            center.removeObserver(observer)
            willPlayNextItemObserver = nil
        }
        
        if let observer = galleryDidScrollToPageObserver {
            center.removeObserver(observer)
            galleryDidScrollToPageObserver = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        galleryScrollView.cleanInvisibleImages()
    }
    
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        galleryTableView.registerNib(UINib(nibName: String(VideoCell), bundle: nil), forCellReuseIdentifier: VideoCell.ReuseIdentifier)

        let selectedPath = NSIndexPath(forRow: 0, inSection: 0)
        self.galleryTableView.selectRowAtIndexPath(selectedPath, animated: false, scrollPosition: UITableViewScrollPosition.Top)
        self.tableView(self.galleryTableView, didSelectRowAtIndexPath: selectedPath)

        willPlayNextItemObserver = NSNotificationCenter.defaultCenter().addObserverForName(kWBVideoPlayerWillPlayNextItem, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] (notification) -> Void in
            if let strongSelf = self, userInfo = notification.userInfo, index = userInfo["index"] as? Int where index < (strongSelf.experience.childExperiences?.count ?? 0) {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                strongSelf.galleryTableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Top)
                strongSelf.userDidSelectNextItem = false
                strongSelf.tableView(strongSelf.galleryTableView, didSelectRowAtIndexPath: indexPath)
            }
        }
        
        galleryDidScrollToPageObserver = NSNotificationCenter.defaultCenter().addObserverForName(ImageGalleryNotification.DidScrollToPage, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { [weak self] (notification) in
            if let strongSelf = self, page = notification.userInfo?["page"] as? Int {
                strongSelf.galleryPageControl.currentPage = page
            }
        })
    }
    
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VideoCell.ReuseIdentifier, forIndexPath: indexPath) as! VideoCell
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle = .None
        cell.experience = experience.childExperiences?[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return experience.childExperiences?.count ?? 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 200
    }
    
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if !cell.selected {
                return indexPath
            }
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let thisExperience = experience.childExperiences?[indexPath.row] {
            mediaTitleLabel.text = thisExperience.metadata?.title
            mediaDescriptionLabel.text = thisExperience.metadata?.description
            
            // Reset media detail views
            galleryPageControl.hidden = true
            turntableSlider.hidden = true
            galleryScrollView.hidden = true
            videoContainerView.hidden = false
            previewImageView?.hidden = didPlayFirstItem
            previewPlayButton?.hidden = didPlayFirstItem
            mediaRuntimeLabel.text = nil
            
            // Set new media detail views
            if let gallery = thisExperience.gallery {
                galleryScrollView.hidden = false
                videoContainerView.hidden = true
                previewImageView?.hidden = true
                previewPlayButton?.hidden = true
                
                let numberOfPages = gallery.pictures?.count ?? 0
                if gallery.isSubType(.Turntable) {
                    turntableSlider.hidden = false
                    turntableSlider.minimumValue = 0
                    turntableSlider.maximumValue = Float(numberOfPages - 1)
                    turntableSlider.value = 0
                } else {
                    galleryPageControl.hidden = false
                    galleryPageControl.numberOfPages = numberOfPages
                }
                
                galleryScrollView.gallery = gallery
                if gallery.isSubType(.Turntable) {
                    galleryScrollView.preloadImages()
                }
            } else if thisExperience.isType(.AudioVisual) {
                let runtime = thisExperience.videoRuntime
                if runtime > 0 {
                    mediaRuntimeLabel.text = String.localize("label.runtime", variables: ["runtime": runtime.timeString()])
                }
            
                if let videoURL = thisExperience.videoURL, videoPlayerViewController = videoPlayerViewController ?? UIStoryboard.getNextGenViewController(VideoPlayerViewController) as? VideoPlayerViewController {
                    if let player = videoPlayerViewController.player {
                        player.removeAllItems()
                    }
                    
                    videoPlayerViewController.mode = VideoPlayerMode.Supplemental
                    videoPlayerViewController.curIndex = indexPath.row
                    videoPlayerViewController.indexMax = experience.childExperiences?.count ?? 0
                    
                    videoPlayerViewController.view.frame = videoContainerView.bounds
                    videoContainerView.addSubview(videoPlayerViewController.view)
                    self.addChildViewController(videoPlayerViewController)
                    videoPlayerViewController.didMoveToParentViewController(self)
                    self.videoPlayerViewController = videoPlayerViewController
                    
                    if !didPlayFirstItem {
                        previewPlayURL = videoURL
                    
                        if indexPath.row == 0 {
                            if let imageURL = thisExperience.imageURL {
                                previewImageView?.setImageWithURL(imageURL)
                            }
                        } else {
                            playFirstItem(nil)
                        }
                    } else {
                        if userDidSelectNextItem {
                            videoPlayerViewController.cancel(videoPlayerViewController.nextItemTask)
                        }
                            
                        videoPlayerViewController.playVideoWithURL(videoURL)
                        userDidSelectNextItem = true
                    }
                }
            }
        }
    }
    
    
    // MARK: Actions
    @IBAction func playFirstItem(sender: UIButton?) {
        didPlayFirstItem = true
        
        previewImageView?.removeFromSuperview()
        previewPlayButton?.removeFromSuperview()
        previewImageView = nil
        previewPlayButton = nil
        
        if let videoURL = previewPlayURL {
            videoPlayerViewController?.playVideoWithURL(videoURL)
        }
    }
    
    @IBAction func turntableSliderValueChanged(slider: UISlider!) {
        galleryScrollView.gotoPage(Int(floor(slider.value)), animated: false)
    }
    
    @IBAction func turntableSliderDidEnd() {
        galleryScrollView.cleanInvisibleImages()
    }
    
}