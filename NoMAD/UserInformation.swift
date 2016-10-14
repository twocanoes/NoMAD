//
//  UserInformation.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/20/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

import Foundation

class UserInformation {
    
    // set up defaults for the domain
    
    var status = "NoMADMenuController-NotConnected"
    var domain = ""
    var realm = ""
    
    var passwordAging = false
    var connected = false
    var tickets = false
    var loggedIn = false
    
    var serverPasswordExpirationDefault: Double
    
    // User Info
    var userShortName: String
    var userLongName: String
    var userPrincipal: String
    var userPrincipalShort: String
    var userDisplayName: String
    var userPasswordSetDate = NSDate()
    var userPasswordExpireDate = NSDate()
    var userHome: String
    
    var lastSetDate = NSDate()
    
    var userCertDate = NSDate()
    var groups = [String]()
    
    let myLDAPServers = LDAPServers()
    let myKeychainUtil = KeychainUtil()
    
    var UserPasswordSetDates = [String : AnyObject ]()
    
    init() {
        // zero everything out
        
        userShortName = ""
        userLongName = ""
        userPrincipal = ""
        userPrincipalShort = ""
        userPasswordSetDate = NSDate()
        userPasswordExpireDate = NSDate()
        userHome = ""
        userCertDate = NSDate()
        serverPasswordExpirationDefault = Double(0)
        userDisplayName = ""
        if defaults.dictionaryForKey("UserPasswordSetDates") != nil {
            UserPasswordSetDates = defaults.dictionaryForKey("UserPasswordSetDates")!
        }
    }
    
    func checkNetwork() -> Bool {
        myLDAPServers.check()
        return myLDAPServers.returnState()
    }
    
    // Determine what certs are available locally
    
    func getCertDate() {
        let myCertExpire = myKeychainUtil.findCertExpiration(userDisplayName, defaultNamingContext: myLDAPServers.defaultNamingContext )
        
        if myCertExpire != 0 {
            myLogger.logit(1, message: "Last certificate will expire on: " + String(myCertExpire) )
        }
        
        // Act on Cert expiration
        
        if myCertExpire.timeIntervalSinceNow < 2592000 && myCertExpire.timeIntervalSinceNow > 0 {
            myLogger.logit(0, message: "Your certificate will expire in less than 30 days.")
            
            // TODO: Trigger an action
            
        }
        
        if myCertExpire.timeIntervalSinceNow < 0 && myCertExpire != NSDate.distantPast() {
            myLogger.logit(0, message: "Your certificate has already expired.")
        }
        
        defaults.setObject(myCertExpire, forKey: "LastCertificateExpiration")
    }
	
	func getUserInfo() {
		
		// 1. check if AD can be reached
		
		var canary = true
		checkNetwork()
		
		//myLDAPServers.tickets.getDetails()
		
		if myLDAPServers.currentState {
			status = "NoMADMenuController-Connected"
			connected = true
		} else {
			status = "NoMADMenuController-NotConnected"
			connected = false
			myLogger.logit(0, message: "Not connected to the network")
		}
		
		// 2. check for tickets
		
		if myLDAPServers.tickets.state {
			userPrincipal = myLDAPServers.tickets.principal
			realm = defaults.stringForKey("KerberosRealm")!
			if userPrincipal.containsString(realm) {
				userPrincipalShort = userPrincipal.stringByReplacingOccurrencesOfString("@" + realm, withString: "")
				status = "Logged In"
				myLogger.logit(0, message: "Logged in.")
			} else {
				myLogger.logit(0, message: "No ticket for realm.")
			}
		} else {
			myLogger.logit(0, message: "No tickets")
		}
		
		// 3. if connected and with tickets, get password aging information
		var passwordSetDate: String?
		var computedExpireDateRaw: String?
		var userPasswordUACFlag: String = ""
		var userHomeTemp: String = ""
        //var userDisplayNameTemp: String = ""
        //var userDisplayName: String = ""
		var groupsTemp: String?
		
		if connected && myLDAPServers.tickets.state {
			
			let attributes = ["pwdLastSet", "msDS-UserPasswordExpiryTimeComputed", "userAccountControl", "homeDirectory", "displayName", "memberOf"] // passwordSetDate, computedExpireDateRaw, userPasswordUACFlag, userHomeTemp, userDisplayName, groupTemp
			// "maxPwdAge" // passwordExpirationLength
			
			let searchTerm = "sAMAccountName=" + userPrincipalShort
			
			if let ldifResult = try? myLDAPServers.getLDAPInformation(attributes, searchTerm: searchTerm) {
				let ldapResult = myLDAPServers.getAttributesForSingleRecordFromCleanedLDIF(attributes, ldif: ldifResult)
				passwordSetDate = ldapResult["pwdLastSet"]
				computedExpireDateRaw = ldapResult["msDS-UserPasswordExpiryTimeComputed"]
				userPasswordUACFlag = ldapResult["userAccountControl"] ?? ""
				userHomeTemp = ldapResult["homeDirectory"] ?? ""
				userDisplayName = ldapResult["displayName"] ?? ""
				groupsTemp = ldapResult["memberOf"]
			} else {
				myLogger.logit(0, message: "Unable to find user.")
				canary = false
			}
			if canary {
				if (passwordSetDate != nil) {
					userPasswordSetDate = NSDate(timeIntervalSince1970: (Double(passwordSetDate!)!)/10000000-11644473600)
				}
				if ( computedExpireDateRaw != nil) {
					// Windows Server 2008 and Newer
					if ( Int(computedExpireDateRaw!) == 9223372036854775807) {
						// Password doesn't expire
						passwordAging = false
						defaults.setObject(false, forKey: "UserAging")
						
						// Set expiration to set date
						userPasswordExpireDate = NSDate()
					} else {
						// Password expires
						
						passwordAging = true
						defaults.setObject(true, forKey: "UserAging")
						
						// TODO: Change all Double() to NumberFormatter().number(from: myString)?.doubleValue
						//       when we switch to Swift 3
						let computedExpireDate = NSDate(timeIntervalSince1970: (Double(computedExpireDateRaw!)!)/10000000-11644473600)
						
						// Set expiration to the computed date.
						userPasswordExpireDate = computedExpireDate
					}
				} else {
					// Older then Windows Server 2008
					// need to go old skool
					var passwordExpirationLength: String
					let attribute = "maxPwdAge"
					if let ldifResult = try? myLDAPServers.getLDAPInformation([attribute], baseSearch: true) {
						passwordExpirationLength = myLDAPServers.getAttributeForSingleRecordFromCleanedLDIF(attribute, ldif: ldifResult)
					} else {
						passwordExpirationLength = ""
					}
					
					if ( passwordExpirationLength.characters.count > 15 ) {
						passwordAging = false
					} else if ( passwordExpirationLength != "" ) {
						if ~~( Int(userPasswordUACFlag)! & 0x10000 ) {
							passwordAging = false
							defaults.setObject(false, forKey: "UserAging")
						} else {
							serverPasswordExpirationDefault = Double(abs(Int(passwordExpirationLength)!)/10000000)
							passwordAging = true
							defaults.setObject(true, forKey: "UserAging")
						}
					} else {
						serverPasswordExpirationDefault = Double(0)
						passwordAging = false
					}
					userPasswordExpireDate = userPasswordSetDate.dateByAddingTimeInterval(serverPasswordExpirationDefault)
				}
				
			}
			// Check if the password was changed without NoMAD knowing.
			if (UserPasswordSetDates[userPrincipal] != nil) && (String(UserPasswordSetDates[userPrincipal]) != "just set" ) {
				// user has been previously set so we can check it
				
				if ((UserPasswordSetDates[userPrincipal] as? NSDate )! != userPasswordSetDate) {
					myLogger.logit(0, message: "Password was changed underneath us.")
					
					// TODO: Do something if we get here
					
					let alertController = NSAlert()
					alertController.messageText = "Your Password Changed"
					alertController.runModal()
					
					// record the new password set date
					
					UserPasswordSetDates[userPrincipal] = userPasswordSetDate
					defaults.setObject(UserPasswordSetDates, forKey: "UserPasswordSetDates")
					
				}
			} else {
				UserPasswordSetDates[userPrincipal] = userPasswordSetDate
				defaults.setObject(UserPasswordSetDates, forKey: "UserPasswordSetDates")
			}
			
			
		}
		
		// 4. if connected and with tickets, get all of user information
		if connected && myLDAPServers.tickets.state && canary {
			userHome = userHomeTemp.stringByReplacingOccurrencesOfString("\\", withString: "/")
			
			groups.removeAll()
			
			if groupsTemp != nil {
				let groupsArray = groupsTemp!.componentsSeparatedByString(";")
				for group in groupsArray {
					let a = group.componentsSeparatedByString(",")
					let b = a[0].stringByReplacingOccurrencesOfString("CN=", withString: "") as String
					if b != "" {
						groups.append(b)
					}
				}
				myLogger.logit(1, message: "You are a member of: " + groups.joinWithSeparator(", ") )
			}
            
            // look at local certs if an x509 CA has been set
            
            if (defaults.stringForKey("x509CA") ?? "" != "") {
                getCertDate()
            }
			
			defaults.setObject(userHome, forKey: "userHome")
			defaults.setObject(userDisplayName, forKey: "displayName")
			defaults.setObject(userPrincipal, forKey: "userPrincipal")
			defaults.setObject(userPrincipalShort, forKey: "LastUser")
			defaults.setObject(userPasswordExpireDate, forKey: "LastPasswordExpireDate")
			defaults.setObject(groups, forKey: "Groups")
		}
	}
	
	/*
    func getUserInfo() {
		
        // 1. check if AD can be reached
		
        var canary = true
        checkNetwork()
		
        //myLDAPServers.tickets.getDetails()
		
        if myLDAPServers.currentState {
            status = "NoMADMenuController-Connected"
            connected = true
        } else {
            status = "NoMADMenuController-NotConnected"
            connected = false
            myLogger.logit(0, message: "Not connected to the network")
        }
		
        // 2. check for tickets
		
        if myLDAPServers.tickets.state {
            userPrincipal = myLDAPServers.tickets.principal
            realm = defaults.stringForKey("KerberosRealm")!
            if userPrincipal.containsString(realm) {
                userPrincipalShort = userPrincipal.stringByReplacingOccurrencesOfString("@" + realm, withString: "")
                status = "Logged In"
                myLogger.logit(0, message: "Logged in.")
            } else {
                myLogger.logit(0, message: "No ticket for realm.")
            }
        } else {
            myLogger.logit(0, message: "No tickets")
        }
		
        // 3. if connected and with tickets, get password aging information
		
        if connected && myLDAPServers.tickets.state {
			
            var passwordSetDate = ""
			let attributes = ["pwdLastSet", "msDS-UserPasswordExpiryTimeComputed", "userAccountControl", "homeDirectory", "displayName", "memberOf"]
			
			let attribute = "pwdLastSet"
			let searchTerm = "sAMAccountName=" + userPrincipalShort
			
			guard let ldifResult = try? myLDAPServers.getLDAPInformation([attribute], searchTerm: searchTerm) else {
				passwordSetDate = ""
				myLogger.logit(0, message: "We shouldn't have gotten here... tell Joel")
				canary = false
			}
			passwordSetDate = myLDAPServers.getAttributeForSingleRecordFromCleanedLDIF(attribute, ldif: ldifResult)
			
            if canary {
				if (passwordSetDate != "") {
					userPasswordSetDate = NSDate(timeIntervalSince1970: (Double(Int(passwordSetDate)!))/10000000-11644473600)
				}
				
                // Now get default password expiration time - this may not be set for environments with no password cycling requirements
                
                myLogger.logit(1, message: "Getting password aging info")
                
                // First try msDS-UserPasswordExpiryTimeComputed
				var computedExpireDateRaw: String
                let attribute = "msDS-UserPasswordExpiryTimeComputed"
				let searchTerm = "sAMAccountName=" + userPrincipalShort
				if let ldifResult = try? myLDAPServers.getLDAPInformation([attribute], searchTerm: searchTerm) {
					computedExpireDateRaw = myLDAPServers.getAttributeForSingleRecordFromCleanedLDIF(attribute, ldif: ldifResult)
				} else {
					computedExpireDateRaw = ""
				}
				
					
                if ( Int(computedExpireDateRaw) == 9223372036854775807 ) {
                    
                    // password doesn't expire
                    
                    passwordAging = false
                    defaults.setObject(false, forKey: "UserAging")
                    
                    // set expiration to set date
                    
                    userPasswordExpireDate = NSDate()
                    
                } else if ( Int(computedExpireDateRaw) != nil ) {
                    
                    // password expires
                    
                    passwordAging = true
                    defaults.setObject(true, forKey: "UserAging")
                    let computedExpireDate = NSDate(timeIntervalSince1970: (Double(Int(computedExpireDateRaw)!))/10000000-11644473600)
                    userPasswordExpireDate = computedExpireDate
                    
                } else {
                    
                    // need to go old skool
					var passwordExpirationLength: String
					let attribute = "maxPwdAge"
					
					if let ldifResult = try? myLDAPServers.getLDAPInformation([attribute], baseSearch: true) {
						passwordExpirationLength = myLDAPServers.getAttributeForSingleRecordFromCleanedLDIF(attribute, ldif: ldifResult)
					} else {
						passwordExpirationLength = ""
					}
                    //let passwordExpirationLength = try! myLDAPServers.getLDAPInformation("maxPwdAge", baseSearch: true )
                    
                    if ( passwordExpirationLength.characters.count > 15 ) {
                        //serverPasswordExpirationDefault = Double(0)
                        passwordAging = false
                    } else if ( passwordExpirationLength != "" ){
                        
                        // now check the users uAC to see if they are exempt
						var userPasswordUACFlag: String
						let attribute = "userAccountControl"
						let searchTerm = "sAMAccountName=" + userPrincipalShort
						
						if let ldifResult = try? myLDAPServers.getLDAPInformation([attribute], searchTerm: searchTerm) {
							userPasswordUACFlag = myLDAPServers.getAttributeForSingleRecordFromCleanedLDIF(attribute, ldif: ldifResult)
						} else {
							userPasswordUACFlag = ""
						}
                        
                        if ~~( Int(userPasswordUACFlag)! & 0x10000 ) {
                            passwordAging = false
                            defaults.setObject(false, forKey: "UserAging")
                        } else {
                            serverPasswordExpirationDefault = Double(abs(Int(passwordExpirationLength)!)/10000000)
                            passwordAging = true
                            defaults.setObject(true, forKey: "UserAging")
                        }
                    } else {
                        serverPasswordExpirationDefault = Double(0)
                        passwordAging = false
                    }
                    userPasswordExpireDate = userPasswordSetDate.dateByAddingTimeInterval(serverPasswordExpirationDefault)
                }
            }
            
            // now to see if the password has changed without NoMAD knowing
            
            if (UserPasswordSetDates[userPrincipal] != nil) && (String(UserPasswordSetDates[userPrincipal]) != "just set" ) {
                
                // user has been previously set so we can check it
                
				if ((UserPasswordSetDates[userPrincipal] as? NSDate )! != userPasswordSetDate) {
					myLogger.logit(0, message: "Password was changed underneath us.")
                    
					// TODO: Do something if we get here
                    
                    let alertController = NSAlert()
                    alertController.messageText = "Your Password Changed"
                    alertController.runModal()
					
					// record the new password set date
					
					UserPasswordSetDates[userPrincipal] = userPasswordSetDate
					defaults.setObject(UserPasswordSetDates, forKey: "UserPasswordSetDates")
                
                }
            } else {
                UserPasswordSetDates[userPrincipal] = userPasswordSetDate
                defaults.setObject(UserPasswordSetDates, forKey: "UserPasswordSetDates")
            }
        }
        
        // 4. if connected and with tickets, get all of user information
        
        if connected && myLDAPServers.tickets.state && canary {
            let userHomeTemp = try! myLDAPServers.getLDAPInformation("homeDirectory", searchTerm: "sAMAccountName=" + userPrincipalShort)
            userHome = userHomeTemp.stringByReplacingOccurrencesOfString("\\", withString: "/")
            userDisplayName = try! myLDAPServers.getLDAPInformation("displayName", searchTerm: "sAMAccountName=" + userPrincipalShort)
            
            groups.removeAll()
            
            let groupsTemp = try! myLDAPServers.getLDAPInformation("memberOf", searchTerm: "sAMAccountName=" + userPrincipalShort ).componentsSeparatedByString(", ")
            for group in groupsTemp {
                let a = group.componentsSeparatedByString(",")
                let b = a[0].stringByReplacingOccurrencesOfString("CN=", withString: "") as String
                if b != "" {
                    groups.append(b)
                }
            }
            
            myLogger.logit(1, message: "You are a member of: " + groups.joinWithSeparator(", ") )
            
            // look at local certs if an x509 CA has been set
            
            if (defaults.stringForKey("x509CA") ?? "" != "") {
            
            let myCertExpire = myKeychainUtil.findCertExpiration(userDisplayName, defaultNamingContext: myLDAPServers.defaultNamingContext )
            
            if myCertExpire != 0 {
                myLogger.logit(1, message: "Last certificate will expire on: " + String(myCertExpire) )
            }
            
            // Act on Cert expiration
            
            if myCertExpire.timeIntervalSinceNow < 2592000 && myCertExpire.timeIntervalSinceNow > 0 {
                myLogger.logit(0, message: "Your certificate will expire in less than 30 days.")
                
                // TODO: Trigger an action
                
                }
                
                if myCertExpire.timeIntervalSinceNow < 0 && myCertExpire != NSDate.distantPast() {
                    myLogger.logit(0, message: "Your certificate has already expired.")
                }
                
                defaults.setObject(myCertExpire, forKey: "LastCertificateExpiration")

            }
            

            // set defaults for these
            
            defaults.setObject(userHome, forKey: "userHome")
            defaults.setObject(userDisplayName, forKey: "displayName")
            defaults.setObject(userPrincipal, forKey: "userPrincipal")
            defaults.setObject(userPrincipalShort, forKey: "LastUser")
            defaults.setObject(userPasswordExpireDate, forKey: "LastPasswordExpireDate")
            defaults.setObject(groups, forKey: "Groups")
        }
        
        myLogger.logit(0, message: "User information update done.")
    }
    */
    
}
