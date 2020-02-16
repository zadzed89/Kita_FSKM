//
//  AppDelegate.swift
//  NewsAppPro
//
//  Created by Apple on 08/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit
import OneSignal
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder,UIApplicationDelegate
{
    var window: UIWindow?
    var SettingArray = NSMutableArray()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        self.checkBundleIdentifire()
        
        Thread.sleep(forTimeInterval:TimeInterval(Settings.SetSplashScreenTime()))
        
        FirebaseApp.configure()
        
        //======Copy Database from my document directory======//
        CommonUtils.copyFile("NewsAppPro.sqlite")
        
        //===========OneSignal Initialization============//
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: CommonUtils.getOneSignalAppID(),
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
            if (accepted) {
                UserDefaults.standard.set(true, forKey: "PROMPT")
            } else {
                UserDefaults.standard.set(false, forKey: "PROMPT")
            }
        })
        OneSignal.add(self as? OSPermissionObserver)
        OneSignal.add(self as? OSSubscriptionObserver)
        
        let isLogin = UserDefaults.standard.bool(forKey: "LOGIN")
        if (isLogin) {
            self.CallHomeViewController()
        } else {
            self.CallLoginViewController()
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        print("userInfo : ",userInfo)
        let customdata = userInfo[AnyHashable("custom")]! as! NSDictionary
        let isData = customdata["a"]
        if ((isData) != nil) {
            let dict = customdata["a"]! as! NSDictionary
            let new_ids = dict["new_id"] as! String
            let new_id : Any? = new_ids
            if (new_id == nil) {
                self.CallHomeViewController()
            } else if (new_ids != "0") {
                let userDefaults = Foundation.UserDefaults.standard
                userDefaults.set(new_id, forKey:"NEWS_ID")
                userDefaults.set(true, forKey:"PERTICULAR_NOTIFICATION")
                self.CallDetailViewController()
            } else if (dict["external_link"] is String) {
                DispatchQueue.main.async {
                    let external_link = dict["external_link"] as? String
                    if let aLink = URL(string: external_link!) {
                        UIApplication.shared.openURL(aLink)
                    }
                }
            } else {
                self.CallHomeViewController()
            }
        } else {
            self.CallHomeViewController()
        }
    }
    
    func onOSPermissionChanged(_ stateChanges: OSPermissionStateChanges!)
    {
        if (stateChanges.from.status == OSNotificationPermission.notDetermined) {
            if (stateChanges.to.status == OSNotificationPermission.authorized) {
                print("Thanks for accepting notifications!")
            } else if (stateChanges.to.status == OSNotificationPermission.denied) {
                print("Notifications not accepted. You can turn them on later under your iOS settings.")
            }
        }
        print("PermissionStateChanges: \n\(String(describing: stateChanges))")
    }
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!)
    {
        if (!stateChanges.from.subscribed && stateChanges.to.subscribed) {
            print("Subscribed for OneSignal push notifications!")
        }
        print("SubscriptionStateChange: \n\(String(describing: stateChanges))")
    }
    
    func CallHomeViewController()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = HomeViewController(nibName: "HomeViewController_iPad", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        } else if (CommonUtils.screenHeight >= 812) {
            let view = HomeViewController(nibName: "HomeViewController_iPhoneX", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        } else {
            let view = HomeViewController(nibName: "HomeViewController", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        }
    }
    
    func CallDetailViewController()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = DetailView(nibName: "DetailView_iPad", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        } else if (CommonUtils.screenHeight >= 812) {
            let view = DetailView(nibName: "DetailView_iPhoneX", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        } else {
            let view = DetailView(nibName: "DetailView", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        }
    }
    
    func CallLoginViewController()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Login(nibName: "Login_iPad", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Login(nibName: "Login_iPhoneX", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        } else {
            let view = Login(nibName: "Login", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    //===========Get App Setting Data==========//
    func checkBundleIdentifire()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getSetting(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getSetting(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_app_details"]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Setting API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Setting Responce Data : \(responseObject)")
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.SettingArray.add(storeDict as Any)
                    }
                }
                print("SettingArray Count = \(self.SettingArray.count)")
                
                DispatchQueue.main.async {
                    //=====Check Bundle Identifire======//
                    let bundleIdentifier =  Bundle.main.bundleIdentifier
                    //print("Bundle Identifier = \(String(describing: bundleIdentifier))")
                    let packageName = (self.SettingArray.value(forKey: "ios_bundle_identifier") as! NSArray).componentsJoined(by: "")
                    if (packageName == bundleIdentifier) {
                        UserDefaults.standard.set(true, forKey: "PACKAGENAME")
                    } else {
                        UserDefaults.standard.set(false, forKey: "PACKAGENAME")
                        NotificationCenter.default.post(name: Notification.Name("PackageNameNotification"), object: nil)
                    }
                    
                    //========Store Admob all Ids Here========//
                    let publisher_id_ios : String? = (self.SettingArray.value(forKey: "publisher_id_ios") as! NSArray).object(at: 0) as? String
                    UserDefaults.standard.setValue(publisher_id_ios, forKey: "publisher_id_ios")
                    let banner_ad_ios1 : String? = (self.SettingArray.value(forKey: "banner_ad_ios") as! NSArray).object(at: 0) as? String
                    //let banner_ad_ios1 : String? = "false"
                    UserDefaults.standard.setValue(banner_ad_ios1, forKey: "banner_ad_ios")
                    let banner_ad_id_ios : String? = (self.SettingArray.value(forKey: "banner_ad_id_ios") as! NSArray).object(at: 0) as? String
                    UserDefaults.standard.setValue(banner_ad_id_ios, forKey: "banner_ad_id_ios")
                    let interstital_ad_ios : String? = (self.SettingArray.value(forKey: "interstital_ad_ios") as! NSArray).object(at: 0) as? String
                    UserDefaults.standard.setValue(interstital_ad_ios, forKey: "interstital_ad_ios")
                    let interstital_ad_id_ios : String? = (self.SettingArray.value(forKey: "interstital_ad_id_ios") as! NSArray).object(at: 0) as? String
                    UserDefaults.standard.setValue(interstital_ad_id_ios, forKey: "interstital_ad_id_ios")
                    let interstital_ad_click_ios : String? = (self.SettingArray.value(forKey: "interstital_ad_click_ios") as! NSArray).object(at: 0) as? String
                    UserDefaults.standard.setValue(interstital_ad_click_ios, forKey: "interstital_ad_click_ios")
                    UserDefaults.standard.setValue(interstital_ad_click_ios, forKey: "AdCount")
                    
                    UserDefaults.standard.set(true, forKey: "ADMOB")
                    NotificationCenter.default.post(name: Notification.Name("ADMOB"), object: nil)
                }
            }
        }, failure: { operation, error in
            self.Networkfailure()
        })
    }
    
    //=======Internet Connection Not Available=======//
    func InternetConnectionNotAvailable() {
        let alert = SCLAlertView()
        _ = alert.addButton(CommonMessage.RETRY()) {
            self.checkBundleIdentifire()
        }
        _ = alert.showError(CommonMessage.NetworkError(), subTitle: CommonMessage.InternetConnectionNotAvailable())
    }
    func Networkfailure() {
        let alert = SCLAlertView()
        _ = alert.addButton(CommonMessage.RETRY()) {
            self.checkBundleIdentifire()
        }
        _ = alert.showError(CommonMessage.NetworkError(), subTitle: CommonMessage.CouldNotConnectToServer())
    }
}

