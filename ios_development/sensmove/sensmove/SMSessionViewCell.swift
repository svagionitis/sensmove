//
//  SMSessionViewCell.swift
//  sensmove
//
//  Created by RIEUX Alexandre on 30/05/2015.
//  Copyright (c) 2015 ___alexprod___. All rights reserved.
//

import UIKit

class SMSessionViewCell: UITableViewCell {

//    @IBOutlet weak var sessionIdentifier: UILabel?
    @IBOutlet weak var sessionDuration: UILabel?
    @IBOutlet weak var averageLeftForces: UILabel?
    @IBOutlet weak var averageRightForces: UILabel?
    @IBOutlet weak var sendReport: UIButton?
    @IBOutlet weak var sessionTitle: UILabel?
    @IBOutlet weak var headerView: UIView?
    @IBOutlet weak var deleteSessionButton: UIButton?
    @IBOutlet weak var sessionIdentifier: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setSessionViewFromModel(session: SMSession) {

        self.designComponents()

        // Set values for components
        self.sessionIdentifier?.text = session.id as String
        self.sessionTitle?.text = session.name as String

        if let leftForceStringValue = session.averageLeftForce?.stringValue {
            self.averageLeftForces?.text = "\(leftForceStringValue) psi"
        }
        
        if let rightForceStringValue = session.averageRightForce?.stringValue {
            self.averageRightForces?.text = "\(rightForceStringValue) psi"
        }
        
        self.sessionDuration?.text = "\(session.duration!)"
    }

    // Set colors for differents component of session view
    func designComponents() {
        self.headerView?.backgroundColor = SMColor.ligthGrey()
        
        self.sessionDuration?.textColor = SMColor.red()
        self.averageRightForces?.textColor = SMColor.red()
        self.averageLeftForces?.textColor = SMColor.red()

        self.sendReport?.setTitleColor(SMColor.middleGrey(), forState: UIControlState.Normal)
    }
}
