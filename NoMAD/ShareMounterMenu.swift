//
//  ShareMounterMenu.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/12/17.
//  Copyright © 2017 Orchard & Grove Inc. All rights reserved.
//

import Foundation

let shareMounterMenu = ShareMounterMenu()
let shareMounterQueue = DispatchQueue(label: "menu.nomad.NoMAD.shareMounting", attributes: [])

// class to build the share mount menu and accept clicks

class ShareMounterMenu: NSObject {
    
    @objc let myShareMounter = ShareMounter()
    @objc var worksWhenModal = true
    @objc let myShareMenu = NSMenu()
    
    var sharePrefs: UserDefaults? = UserDefaults.init(suiteName: "menu.nomad.shares")
    
    @objc func updateShares(connected: Bool=false) {
        
        if (sharePrefs?.integer(forKey: "Version") ?? 0) >= 1 {
        shareMounterQueue.sync(execute: {
            self.myShareMounter.connectedState = connected
            self.myShareMounter.userPrincipal = defaults.string(forKey: Preferences.userPrincipal)!
            self.myShareMounter.getMountedShares()
            self.myShareMounter.getMounts()
            self.myShareMounter.mountShares()
        })
        }
    }
    
    @objc func buildMenu(connected: Bool=false) -> NSMenu {
        
        if sharePrefs?.integer(forKey: "Version") != 1 {
            return NSMenu.init()
        }
        
        if myShareMounter.all_shares.count > 0 {
            // Menu Items and Menu
            
            myShareMenu.removeAllItems()
            
            if CommandLine.arguments.contains("-shares") {
                print("***Building Share Menu***")
                print(self.myShareMounter.all_shares)
            }
            
            for share in self.myShareMounter.all_shares {
                let myItem = NSMenuItem()
                myItem.title = share.name
                
                if share.connectedOnly && connected {
                    myItem.target = self
                } else {
                    myItem.target = nil
                }
                
                myItem.action = #selector(openShareFromMenu)
                myItem.toolTip = String(describing: share.url)
                if share.mountStatus == .mounted {
                    myItem.isEnabled = true
                    myItem.state = NSControl.StateValue(rawValue: 1)
                } else if share.mountStatus == .mounting {
                    myItem.isEnabled = false
                    myItem.state = NSControl.StateValue(rawValue: 0)
                } else if share.mountStatus == .unmounted {
                    myItem.isEnabled = true
                    myItem.state = NSControl.StateValue(rawValue: 0)
                } else if share.mountStatus == .errorOnMount {
                    myItem.isEnabled = false
                    myItem.state = NSControl.StateValue(rawValue: 0)
                }

                myShareMenu.addItem(myItem)
            }
            
            // Edit menu item to come later
            
            //myShareMenu.addItem(NSMenuItem.separator())
            //myShareMenu.addItem(withTitle: "Edit...".translate, action: nil, keyEquivalent: "")
            
        }
        
        if CommandLine.arguments.contains("-shares") {
            print("***Share Menuu***")
            print(myShareMenu)
        }
        
        return myShareMenu
    }
    
    @IBAction func openShareFromMenu(_ sender: AnyObject) {
                
        for share in myShareMounter.all_shares {
            if share.name == sender.title {
                if share.mountStatus != .mounted && share.mountStatus != .mounting {
                    myLogger.logit(.debug, message: "Mounting share: " + String(describing: share.url))
                    
                    //myShareMounter.asyncMountShare(share.url, options: share.options, open: true)
                    //_ = cliTask("open " + DFSResolver.checkAndReplace(url: share.url))
                    _ = cliTask("open " + share.url.absoluteString.safeURLPath()!)
                } else if share.mountStatus == .mounted {
                    print(share.localMountPoints ?? "")
                    // open up the local shares
                    
                    // cliTask(“open ” + DFSResolver.checkAndReplace(url: share.url))
                    NSWorkspace.shared.open(URL(fileURLWithPath: share.localMountPoints!, isDirectory: true))
                }
            }
        }
    updateShares()
    }
    
    // utility functions
    
    @objc func sharesAvilable() -> Bool {
        if myShareMenu.items.count == 0 {
            return false
        } else {
            return true
        }
    }
}
