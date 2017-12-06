//
//  InMovieExperienceViewController.swift
//

import UIKit
import CPEData

class InMovieExperienceExtrasViewController: UIViewController {

    fileprivate struct Constants {
        static let HeaderHeight: CGFloat = 35
        static let FooterHeight: CGFloat = 45
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
    fileprivate var currentTalents: [Person]?
    private var hiddenTalents: [Person]?
    fileprivate var isShowingMore = false
    fileprivate var talentTableViewHeaderLabel: UILabel?

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

        if CPEDataUtils.hasPeopleForDisplay {
            talentTableView?.register(UINib(nibName: TalentTableViewCell.NibNameNarrow + (DeviceType.IS_IPAD ? "" : "_iPhone"), bundle: Bundle.frameworkResources), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
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

                let newTalents = CPEXMLSuite.current!.manifest.timedEvents(atTimecode: time, type: .person)?.sorted(by: {
                    return $0.person!.billingBlockOrder < $1.person!.billingBlockOrder
                }).map({
                    $0.person!
                })

                if self.isShowingMore {
                    self.hiddenTalents = newTalents
                } else {
                    if self.currentTalents == nil || newTalents == nil || newTalents!.count != self.currentTalents!.count || newTalents!.contains(where: { !self.currentTalents!.contains($0) }) {
                        DispatchQueue.main.async {
                            self.currentTalents = newTalents
                            self.talentTableView?.reloadData()
                        }
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

        if isShowingMore {
            hiddenTalents = currentTalents
            currentTalents = CPEDataUtils.peopleForDisplay
            Analytics.log(event: .imeTalentAction, action: .showMore)
        } else {
            currentTalents = hiddenTalents
            Analytics.log(event: .imeTalentAction, action: .showLess)
        }

        talentTableView?.contentOffset = CGPoint.zero
        talentTableView?.reloadData()
    }

    // MARK: Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.ShowTalent, let talentDetailViewController = (segue.destination as? TalentDetailViewController), let talent = (sender as? Person) {
            talentDetailViewController.title = CPEDataUtils.personExperienceName
            talentDetailViewController.talent = talent
            talentDetailViewController.mode = TalentDetailMode.Synced
        }
    }

}

extension InMovieExperienceExtrasViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (currentTalents?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? TalentTableViewCell else {
            return tableViewCell
        }

        if let talents = currentTalents, talents.count > indexPath.row {
            cell.talent = talents[indexPath.row]
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if talentTableViewHeaderLabel == nil {
            talentTableViewHeaderLabel = UILabel(frame: CGRect(x: 5, y: 0, width: tableView.bounds.width - 10, height: Constants.HeaderHeight))
            talentTableViewHeaderLabel?.textAlignment = .center
            talentTableViewHeaderLabel?.textColor = UIColor(netHex: 0xe5e5e5)
            talentTableViewHeaderLabel?.font = UIFont.themeCondensedFont(DeviceType.IS_IPAD ? 19 : 17)
            talentTableViewHeaderLabel?.adjustsFontSizeToFitWidth = true
            talentTableViewHeaderLabel?.minimumScaleFactor = 0.65
            talentTableViewHeaderLabel?.text = CPEDataUtils.peopleExperienceName.uppercased()
        }

        return talentTableViewHeaderLabel
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
