
//
//  ReminderViewController.swift
//  Signal
//
//  Created by Michael Kirk on 3/1/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc
public class OWS2FAReminderViewController : UIViewController, UITextFieldDelegate {
    
    private var ows2FAManager: OWS2FAManager {
        return OWS2FAManager.shared()
    }
    
    private var actualPinCode: String! {
        return ows2FAManager.pinCode
    }
    
    var textField: UITextField!
    
    @objc
    public class func wrappedInNavController() -> UINavigationController {
        let navController = UINavigationController()
        navController.pushViewController(OWS2FAReminderViewController(), animated: false)
        
        return navController
    }
    
    override public func loadView() {
        assert(actualPinCode != nil)
        
        self.navigationItem.title = NSLocalizedString("TWO_FACTOR_AUTH_REMINDER_NAV_TITLE", comment: "Navbar title for when user is peridoically prompted to enter their registration lock PIN")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(didPressCloseButton))
        
        let view = UIView()
        self.view = view
        view.backgroundColor = .white

        let instructionsLabel = UILabel()
        // TODO use extracted styles from 2FASettingsViewController
        instructionsLabel.font = UIFont.ows_dynamicTypeBody()
        instructionsLabel.numberOfLines = 0
        
        let bodyText = NSLocalizedString("TWO_FACTOR_AUTH_REMINDER_BODY", comment: "Body text for when user is peridoically prompted to enter their registration lock PIN")
        
        // TODO style this as link
        let forgotText = NSLocalizedString("TWO_FACTOR_AUTH_REMINDER_BODY_FORGOT_PIN", comment: "Snippet appended to body when user is peridoically prompted to enter their registration lock PIN")
        
        let instructionsText = (bodyText as NSString).rtlSafeAppend(forgotText, isRTL: instructionsLabel.isRTL())
        instructionsLabel.text = instructionsText
        view.addSubview(instructionsLabel)
        
        let textField = UITextField()
        textField.delegate = self
        view.addSubview(textField)
        // TODO use extracted styles from 2FASettingsViewController
        textField.font = UIFont.ows_dynamicTypeBody()
        textField.isSecureTextEntry = true
        
        let submitButton = UIButton()
        view.addSubview(submitButton)
        // TODO use extracted styles from 2FASettingsViewController
        let submitText = NSLocalizedString("TWO_FACTOR_AUTH_REMINDER_SUBMIT_BUTTON", comment: "Button text for user to submit their registration lock PIN number when they are peridoically prompted")
        submitButton.setTitle(submitText, for: .normal)
        submitButton.addTarget(self, action: #selector(didPressSubmitButton), for: .touchUpInside)

        
        // Layout
        let kVOffset: CGFloat = 8;
        
        instructionsLabel.autoVCenterInSuperview()
        instructionsLabel.autoPinEdge(toSuperviewMargin: .left)
        instructionsLabel.autoPinEdge(toSuperviewMargin: .right)
        instructionsLabel.setContentHuggingHigh()
        instructionsLabel.setCompressionResistanceHigh()
        
        // TODO crib style from settings
        let kTextFieldWidth = ScaleFromIPhone5(100)
        textField.autoSetDimension(.width, toSize: kTextFieldWidth)
        textField.autoHCenterInSuperview()
        textField.autoPinEdge(.bottom, to: .top, of: instructionsLabel, withOffset: kVOffset)
        
        submitButton.autoPinEdge(.top, to: .bottom, of: textField, withOffset: kVOffset)
        submitButton.autoHCenterInSuperview()
    }
    
    // MARK: Helpers

    @objc
    private func didPressSubmitButton(sender: UIButton) {
        Logger.info("\(logTag) in \(#function)")
        if checkResult() {
            showSuccess()
        } else {
            showFailure()
        }
    }
    
    @objc
    private func didPressCloseButton(sender: UIButton) {
        Logger.info("\(logTag) in \(#function)")
        // We'll ask again next time they launch
        self.dismiss(animated: true)
    }
    
    private func checkResult() -> Bool {
        return textField.text == self.actualPinCode
    }
    
    private func showSuccess() {
        Logger.info("\(logTag) in \(#function)")
    }
    
    private func showFailure() {
        Logger.info("\(logTag) in \(#function)")
    }
    
    // MARK: UITextFieldDelegate
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // optimistically match, without having to press "done"
        if checkResult() {
            showSuccess()
        }
        return true
    }
}
