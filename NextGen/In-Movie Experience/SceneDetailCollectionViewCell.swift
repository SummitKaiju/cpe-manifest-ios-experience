//
//  SceneDetailCollectionViewCell.swift
//  NextGen
//
//  Created by Alec Ananian on 2/8/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class SceneDetailCollectionViewCell: UICollectionViewCell {
    
    struct Constants {
        static let UpdateInterval: Double = 15
    }
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var _title: String? {
        didSet {
            titleLabel?.text = _title?.uppercaseString
        }
    }
    
    internal var _descriptionText: String? {
        didSet {
            descriptionLabel.text = _descriptionText
        }
    }
    
    var experience: NGDMExperience? {
        didSet {
            if experience != oldValue {
                experienceDidChange()
            }
        }
    }
    
    var timedEvent: NGDMTimedEvent? {
        didSet {
            if timedEvent != oldValue {
                timedEventDidChange()
            }
        }
    }
    
    private var _lastSavedTime: Double = -1.0
    var currentTime: Double = -1.0 {
        didSet {
            if _lastSavedTime == -1 || abs(currentTime - _lastSavedTime) >= Constants.UpdateInterval {
                _lastSavedTime = currentTime
                currentTimeDidChange()
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        experience = nil
        timedEvent = nil
    }
    
    func experienceDidChange() {
        _title = experience?.title
    }
    
    func timedEventDidChange() {
        _descriptionText = timedEvent?.descriptionText
    }
    
    func currentTimeDidChange() {
        // Override
    }
}