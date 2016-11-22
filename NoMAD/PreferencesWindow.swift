//
//  PreferencesWindow.swift
//  NoMAD
//
//  Created by Joel Rennich on 4/21/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func doTheNeedfull()
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {

    var delegate: PreferencesWindowDelegate?

    @IBOutlet weak var ADDomainTextField: NSTextField!
    @IBOutlet weak var KerberosRealmField: NSTextField!
    //@IBOutlet weak var InternalSiteField: NSTextField!
    //@IBOutlet weak var InternalSiteIPField: NSTextField!
    @IBOutlet weak var x509CAField: NSTextField!
    @IBOutlet weak var TemplateField: NSTextField!
    @IBOutlet weak var ButtonNameField: NSTextField!
    @IBOutlet weak var HotKeyField: NSTextField!
    @IBOutlet weak var CommandField: NSTextField!
    @IBOutlet weak var SecondsToRenew: NSTextField!

    // Check boxes

    @IBOutlet weak var UseKeychain: NSButton!
    @IBOutlet weak var RenewTickets: NSButton!
    @IBOutlet weak var ShowHome: NSButton!

    override var windowNibName: String? {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()

//        guard let controls = self.window?.contentView?.subviews else {
//            myLogger.logit(.debug, message: "Preference window somehow drew without any controls.")
//            return
//        }
//
//        for object in controls {
//            let identifier = object.identifier
//            switch object.className {
//            case "NSTextField":
//                let textField = object as! NSTextField
//                textField.stringValue = defaults.string(forKey: identifier!) ?? ""
//            case "NSButton":
//                let button = object as! NSButton
//                button.state = defaults.integer(forKey: identifier!)
//            default:
//                return
//            }
//        }

        // set the fields and disable them if they're managed

//
//        ADDomainTextField.stringValue = defaults.string(forKey: Preferences.aDDomain)!
//
//        if defaults.objectIsForced(forKey: Preferences.aDDomain) {
//            ADDomainTextField.isEnabled = false
//        } else {
//            ADDomainTextField.isEnabled = true
//        }

//        KerberosRealmField.stringValue = defaults.string(forKey: Preferences.kerberosRealm)!
//
//        if defaults.objectIsForced(forKey: Preferences.kerberosRealm) {
//            KerberosRealmField.isEnabled = false
//        } else {
//            KerberosRealmField.isEnabled = true
//        }
        /*
         InternalSiteField.stringValue = defaults.stringForKey("InternalSite") ?? ""

         if defaults.objectIsForcedForKey("InternalSite") {
         InternalSiteField.enabled = false
         } else {
         InternalSiteField.enabled = true
         }

         InternalSiteIPField.stringValue = defaults.stringForKey("InternalSiteIP") ?? ""

         if defaults.objectIsForcedForKey("InternalSiteIP") {
         InternalSiteIPField.enabled = false
         } else {
         InternalSiteIPField.enabled = true
         }
         */
//        x509CAField.stringValue = defaults.string(forKey: Preferences.x509CA)!
//
//        if defaults.objectIsForced(forKey: Preferences.x509CA) {
//            x509CAField.isEnabled = false
//        } else {
//            x509CAField.isEnabled = true
//        }
//
//        TemplateField.stringValue = defaults.string(forKey: Preferences.template)!
//
//        if defaults.objectIsForced(forKey: Preferences.template) {
//            TemplateField.isEnabled = false
//        } else {
//            TemplateField.isEnabled = true
//        }

        // now the secret stuff
//
//        ButtonNameField.stringValue = defaults.string(forKey: Preferences.userCommandName1)!
//
//        if defaults.objectIsForced(forKey: Preferences.userCommandName1) {
//            ButtonNameField.isEnabled = false
//        } else {
//            ButtonNameField.isEnabled = true
//        }
//
//        HotKeyField.stringValue = defaults.string(forKey: Preferences.userCommandHotKey1)!
//
//        if defaults.objectIsForced(forKey: Preferences.userCommandHotKey1) {
//            HotKeyField.isEnabled = false
//        } else {
//            HotKeyField.isEnabled = true
//        }
//
//        CommandField.stringValue = defaults.string(forKey: Preferences.userCommandTask1)!
//
//        if defaults.objectIsForced(forKey: Preferences.userCommandTask1) {
//            CommandField.isEnabled = false
//        } else {
//            CommandField.isEnabled = true
//        }

        // now the buttons

//        UseKeychain.state = defaults.integer(forKey: Preferences.useKeychain)
//
//        if defaults.objectIsForced(forKey: Preferences.useKeychain) {
//            UseKeychain.isEnabled = false
//        } else {
//            UseKeychain.isEnabled = true
//        }
//
//        RenewTickets.state = defaults.integer(forKey: Preferences.renewTickets)
//
//        if defaults.objectIsForced(forKey: Preferences.renewTickets) {
//            RenewTickets.isEnabled = false
//        } else {
//            RenewTickets.isEnabled = true
//        }
//
//        ShowHome.state = defaults.integer(forKey: Preferences.showHome)
//
//        if defaults.objectIsForced(forKey: Preferences.showHome) {
//            ShowHome.isEnabled = false
//        } else {
//            ShowHome.isEnabled = true
//        }
//
//        // and the seconds
//
//        SecondsToRenew.stringValue = String(defaults.integer(forKey: Preferences.secondsToRenew) )
//
//        if defaults.objectIsForced(forKey: Preferences.secondsToRenew) {
//            SecondsToRenew.isEnabled = false
//        } else {
//            SecondsToRenew.isEnabled = true
//        }

    }

    func windowShouldClose(_ sender: Any) -> Bool {

        // make sure we have an AD Domain

        if ADDomainTextField.stringValue == "" {
            let alertController = NSAlert()
            alertController.messageText = "The AD Domain needs to be filled out."
            alertController.addButton(withTitle: "OK")
            alertController.addButton(withTitle: "Quit NoMAD")
            alertController.beginSheetModal(for: self.window!, completionHandler: {( response ) in
                if ( response == 1001 ) {
                    NSApp.terminate(self)
                } else {
                }
            })
            return false
        } else {
            return true
        }
    }

    func windowWillClose(_ notification: Notification) {

        // turn the fields into app defaults

//        defaults.set(ADDomainTextField.stringValue, forKey: Preferences.aDDomain)
        if ( KerberosRealmField.stringValue == "" ) {
            defaults.set(ADDomainTextField.stringValue.uppercased(), forKey: Preferences.kerberosRealm)
        } else {
            defaults.set(KerberosRealmField.stringValue.uppercased(), forKey: Preferences.kerberosRealm)
        }
        //defaults.setObject(InternalSiteField.stringValue, forKey: "InternalSite")
        //defaults.setObject(InternalSiteIPField.stringValue, forKey: "InternalSiteIP")
//        defaults.set(x509CAField.stringValue, forKey: Preferences.x509CA)
//        defaults.set(TemplateField.stringValue, forKey: Preferences.template)

        // secret stuff

//        defaults.set(ButtonNameField.stringValue, forKey: Preferences.userCommandName1)
//        defaults.set(HotKeyField.stringValue, forKey: Preferences.userCommandHotKey1)
//        defaults.set(CommandField.stringValue, forKey: Preferences.userCommandTask1)

        // buttons

//        defaults.set(UseKeychain.state, forKey: Preferences.useKeychain)
//        defaults.set(RenewTickets.state, forKey: Preferences.renewTickets)
//        defaults.set(ShowHome.state, forKey: Preferences.showHome)
//        
//        // and the seconds
//        
//        defaults.set(Int(SecondsToRenew.stringValue), forKey: Preferences.secondsToRenew)
        notificationCenter.post(notificationKey)
        
    }
    
}
