//
//  NoMADAction.swift
//  NoMAD
//
//  Created by Joel Rennich on 1/24/18.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Foundation


// Class to handle an action

class NoMADAction : NSObject {
    
    // each action needs a name and GUID
    // we'll assign a GUID if one is not present
    
    let actionName : String
    let actionGUID : String
    
    // actions
    
    var show: [Dictionary<String, String?>]? = nil
    var title: Dictionary<String, String?>? = nil
    var action : [Dictionary<String, String?>]? = nil
    var post : [Dictionary<String, String?>]? = nil
    
    // timers and triggers

    var timer : Int? = nil
    var timerObject : Timer? = nil
    var trigger : [String]? = nil
    
    // status
    
    var status: String? = nil
    var visible: Bool = true
    var connected: Bool = false
    
    // globals
    
    var display : Bool = false
    var text : String = "action item"
    var tip : String = ""
    var actionResult : String = ""
    
    // init
    
    init(_ name: String, guid : String?) {
        actionName = name
        if guid == nil {
            actionGUID = UUID().uuidString
        } else {
            actionGUID = guid!
        }
    }
    
    /// Run a command set
    ///
    /// - Parameter commands: a dictionary of Commands
    /// - Returns: Bool passed back from the commands
    
    func runCommand(commands : [Dictionary<String,String?>]?) -> Bool {
        
        if commands == nil {
            return true
        }
        
        var result : String = ""
        
        for command in commands! {
            
            if result == "false" && (command["Command"] as? String ?? "" ).contains("True") {
                // result was false so don't trigger any True action
                continue
            }
            
            if result == "true" && (command["Command"] as? String ?? "" ).contains("False") {
                // result was true so don't trigger any false action
                continue
            }
            
            result = runActionCommand(action: (command["Command"] as? String ?? "none").replacingOccurrences(of: "True", with: "").replacingOccurrences(of: "False", with: "") , options: (command["CommandOptions"] as? String ?? "none").replacingOccurrences(of: "<<result>>", with: actionResult) )
            if result == "false" {
                actionResult = ""
                if result.contains("<<menu>>") {
                    nActionMenu.menuText = result.replacingOccurrences(of: "<<menu>>", with: "")
                }
                return false
            } else if result != "true" {
                actionResult = result
                
                if result.contains("<<menu>>") {
                    nActionMenu.menuText = result.replacingOccurrences(of: "<<menu>>", with: "")
                }
                
            } else {
                actionResult = "true"
            }
        }
        return true
    }
    
    func getTitle() -> String {
        
        if title == nil {
            return actionName
        }
        
        let result =  runActionCommand(action: title!["Command"] as? String ?? "none", options: title!["CommandOptions"] as? String ?? "none")
        
        if result == "true" {
            status = "green"
            return actionName
        } else if result == "false" {
            status = "red"
            return actionName
        } else if result == "yellow" {
            status = "yellow"
            return actionName
        } else {
            return result
        }
    }
    
    func displayItem() -> String {
        return text
    }
    
    @IBAction func runAction(_ sender: AnyObject) {
        let result = runCommand(commands: action)
        
        if result {
            myLogger.logit(.base, message: "Action succeeded: \(actionName)")
        } else {
            myLogger.logit(.base, message: "Action failed: \(actionName)")
        }
        
        if post != nil {
            // run any post commands
            // TODO: add in a way to report on result of Action

            _ = runCommand(commands: post)
        }
    }
    
    func runActionCLI() {
        let result = runCommand(commands: action)
        
        if result {
            myLogger.logit(.base, message: "Action succeeded: \(actionName)")
        } else {
            myLogger.logit(.base, message: "Action failed: \(actionName)")
        }
        
        if post != nil {
            // run any post commands
            
            _ = runCommand(commands: post)
        }
    }
    
    func runActionCLISilent() {
        let result = runCommand(commands: action)
        
        if result {
            myLogger.logit(.base, message: "Action succeeded: \(actionName)")
        } else {
            myLogger.logit(.base, message: "Action failed: \(actionName)")
        }
        // this method runs no post commands
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
}

