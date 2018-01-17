//
//  InMovieExperienceViewController.swift
//

import UIKit
import CPEData

class InMovieExperienceExtrasViewController: UIViewController {

    fileprivate struct Constants {
        static let HeaderHeight: CGFloat = 35
        static let FooterHeight: CGFloat = 45
        static let SegmentedControlPadding: CGFloat = (DeviceType.IS_IPAD ? 10 : 5)
        static let SegmentedControlFontSize: CGFloat = (DeviceType.IS_IPAD ? 10 : 9)
        static let SegmentedControlHeight: CGFloat = 30
    }

    fileprivate struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
    }

    @IBOutlet weak private var talentTableView: UITableView?
    @IBOutlet weak private var backgroundImageView: UIImageView!
    @IBOutlet weak private var showLessContainer: UIView!
    @IBOutlet weak private var showLessButton: UIButton!
    @IBOutlet weak private var showLessGradientView: UIView!
    private var showLessGradient = CAGradientLayer()
    fileprivate var isShowingMore = false
    
    fileprivate var talentTableHeaderView: UIView?
    fileprivate var talentTableViewHeaderLabel: UILabel?
    fileprivate var personSegmentedControl: UISegmentedControl?
    private var currentPersonJobFunction = PersonJobFunction.actor
    fileprivate var currentPeople: [Person]?
    fileprivate var allPeople: [Person]? {
        return CPEDataUtils.people?[currentPersonJobFunction]
    }

    private var currentTime: Double = -1
    private var didChangeTimeObserver: NSObjectProtocol?

    deinit {
        if let observer = didChangeTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            didChangeTimeObserver = nil
        }
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let nodeStyle = CPEXMLSuite.current!.cpeStyle?.nodeStyle(withExperienceID: CPEXMLSuite.current!.manifest.inMovieExperience.id, interfaceOrientation: UIApplication.shared.statusBarOrientation) {
            self.view.backgroundColor = nodeStyle.backgroundColor

            if let backgroundImageURL = nodeStyle.backgroundImage?.url {
                backgroundImageView.sd_setImage(with: backgroundImageURL)
                backgroundImageView.contentMode = nodeStyle.backgroundScaleMethod == .bestFit ? .scaleAspectFill : .scaleAspectFit
            }
        }
        
        if let people = CPEDataUtils.people {
            talentTableView?.register(UINib(nibName: TalentTableViewCell.NibNameNarrow + (DeviceType.IS_IPAD ? "" : "_iPhone"), bundle: Bundle.frameworkResources), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
            if people[.actor] == nil {
                currentPersonJobFunction = people.first!.0
            }
        } else {
            talentTableView?.removeFromSuperview()
            talentTableView = nil
        }

        showLessGradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        showLessGradientView.layer.insertSublayer(showLessGradient, at: 0)
        showLessButton.setTitle(String.localize("talent.show_less"), for: .normal)

        didChangeTimeObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidChangeTime, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if let strongSelf = self, let time = notification.userInfo?[NotificationConstants.time] as? Double, time != strongSelf.currentTime {
                strongSelf.processTimedEvents(time)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let talentTableView = talentTableView {
            showLessGradientView.frame.size.width = talentTableView.frame.width
        }

        showLessGradient.frame = showLessGradientView.bounds
    }

    private func processTimedEvents(_ time: Double) {
        if !self.view.isHidden {
            DispatchQueue.global(qos: .userInitiated).async {
                self.currentTime = time

                let newPeople = CPEXMLSuite.current!.manifest.timedEvents(atTimecode: time, type: .person)?.flatMap({ ($0.person?.jobFunction == self.currentPersonJobFunction ? $0.person : nil) }).sorted()
                if self.currentPeople == nil || newPeople == nil || newPeople!.contains(where: { !self.currentPeople!.contains($0) }) || self.currentPeople!.contains(where: { !newPeople!.contains($0) }) {
                    DispatchQueue.main.async {
                        self.currentPeople = newPeople
                        self.talentTableView?.reloadData()
                    }
                }
            }
        }
    }

    // MARK: Actions
    @objc fileprivate func onTapFooter() {
        toggleShowMore()
    }

    @IBAction private func onTapShowLess() {
        toggleShowMore()
    }

    private func toggleShowMore() {
        isShowingMore = !isShowingMore
        showLessContainer.isHidden = !isShowingMore
        Analytics.log(event: .imeTalentAction, action: (isShowingMore ? .showMore : .showLess))
        talentTableView?.contentOffset = .zero
        talentTableView?.reloadData()
    }
    
    @objc fileprivate func onSelectPersonJobFunction() {
        if let index = personSegmentedControl?.selectedSegmentIndex, let jobFunctions = CPEDataUtils.personJobFunctions, jobFunctions.count > index {
            currentPersonJobFunction = Array(jobFunctions)[index]
            processTimedEvents(currentTime)
            talentTableView?.reloadData()
        }
    }

    // MARK: Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.ShowTalent, let talentDetailViewController = (segue.destination as? TalentDetailViewController), let talent = (sender as? Person) {
            talentDetailViewController.title = CPEDataUtils.titleForPerson(with: currentPersonJobFunction)
            talentDetailViewController.talent = talent
            talentDetailViewController.mode = TalentDetailMode.Synced
        }
    }

}

extension InMovieExperienceExtrasViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ((isShowingMore ? allPeople : currentPeople)?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? TalentTableViewCell else {
            return tableViewCell
        }

        if let people = (isShowingMore ? allPeople : currentPeople), people.count > indexPath.row {
            cell.talent = people[indexPath.row]
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if CPEDataUtils.numPersonJobFunctions <= 1 {
            if talentTableViewHeaderLabel == nil {
                talentTableViewHeaderLabel = UILabel(frame: CGRect(x: 5, y: 0, width: tableView.bounds.width - 10, height: Constants.HeaderHeight))
                talentTableViewHeaderLabel?.textAlignment = .center
                talentTableViewHeaderLabel?.textColor = UIColor(netHex: 0xe5e5e5)
                talentTableViewHeaderLabel?.font = UIFont.themeCondensedFont(DeviceType.IS_IPAD ? 19 : 17)
                talentTableViewHeaderLabel?.adjustsFontSizeToFitWidth = true
                talentTableViewHeaderLabel?.minimumScaleFactor = 0.65
                talentTableViewHeaderLabel?.text = CPEDataUtils.titleForPeople().uppercased()
            }
            
            return talentTableHeaderView
        }
        
        if talentTableHeaderView == nil {
            if #available(iOS 9.0, *) {
                UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 0
            }
            personSegmentedControl = UISegmentedControl(items: CPEDataUtils.personJobFunctions?.map({ CPEDataUtils.titleForPeople(with: $0).uppercased() }))
            personSegmentedControl?.frame = CGRect(x: Constants.SegmentedControlPadding, y: 0, width: tableView.frame.width - (Constants.SegmentedControlPadding * 2), height: Constants.SegmentedControlHeight)
            personSegmentedControl?.tintColor = UIColor(netHex: 0xd61414)
            personSegmentedControl?.setTitleTextAttributes([
                NSFontAttributeName: UIFont.systemFont(ofSize: Constants.SegmentedControlFontSize),
                NSForegroundColorAttributeName: UIColor.white
            ], for: .normal)
            personSegmentedControl?.setTitleTextAttributes([
                NSForegroundColorAttributeName: UIColor.white
                ], for: .selected)
            personSegmentedControl?.selectedSegmentIndex = 0
            personSegmentedControl?.addTarget(self, action: #selector(onSelectPersonJobFunction), for: .valueChanged)
            
            talentTableHeaderView = UIView()
            talentTableHeaderView?.addSubview(personSegmentedControl!)
        }
        
        return talentTableHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.HeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Constants.FooterHeight
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return (isShowingMore ? nil : String.localize("talent.show_more"))
    }

}

extension InMovieExperienceExtrasViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textAlignment = .center
            footer.textLabel?.textColor = UIColor(netHex: 0xe5e5e5)
            footer.textLabel?.font = UIFont.themeCondensedFont(DeviceType.IS_IPAD ? 19 : 17)

            if footer.gestureRecognizers == nil || footer.gestureRecognizers!.count == 0 {
                footer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapFooter)))
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TalentTableViewCell, let talent = cell.talent {
            self.performSegue(withIdentifier: SegueIdentifier.ShowTalent, sender: talent)
            Analytics.log(event: .imeTalentAction, action: .selectTalent, itemId: talent.id)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

}
