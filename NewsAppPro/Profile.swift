//
//  Profile.swift
//  NewsAppPro
//
//  Created by Apple on 22/02/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit

class Profile: UIViewController,UITextFieldDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnback : UIButton?
    var spinner: SWActivityIndicatorView!
    var ProfileArray = NSMutableArray()
    
    @IBOutlet var myScrollview : UIScrollView?
    @IBOutlet var lblsignup : UILabel?
    @IBOutlet var lblusername : UILabel?
    @IBOutlet var lblemail : UILabel?
    @IBOutlet var lblpassword : UILabel?
    @IBOutlet var lblcofirmpassword : UILabel?
    @IBOutlet var lblphone : UILabel?
    @IBOutlet var txtusername : UITextField?
    @IBOutlet var txtemail : UITextField?
    @IBOutlet var txtpassword : UITextField?
    @IBOutlet var txtcofirmpassword : UITextField?
    @IBOutlet var txtphone : UITextField?
    @IBOutlet var btnupdate : UIButton?
    var UpdateArray = NSMutableArray()
    
    var keyboardHieght : CGFloat = 0.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //=====Phone Keyboard=====//
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.onKeyboardDoneClicked(_:)))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        self.txtphone?.inputAccessoryView = keyboardToolbar
        
        //===========Get User Profile Data==========//
        self.myScrollview?.isHidden = true
        self.getUserProfile()
    }
    
    //===========Get User Profile Data==========//
    func getUserProfile()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getUserProfileData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getUserProfileData(_ requesturl: String?)
    {
        let userID = UserDefaults.standard.string(forKey: "USER_ID")
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"user_profile", "id":userID]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("User Profile API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("User Profile Responce Data : \(responseObject)")
                self.ProfileArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.ProfileArray.add(storeDict as Any)
                    }
                }
                print("ProfileArray Count = \(self.ProfileArray.count)")
                
                DispatchQueue.main.async {
                    let name = (self.ProfileArray.value(forKey: "name") as! NSArray).componentsJoined(by: "")
                    self.txtusername?.text = name
                    let email = (self.ProfileArray.value(forKey: "email") as! NSArray).componentsJoined(by: "")
                    self.txtemail?.text = email
                    let phone = (self.ProfileArray.value(forKey: "phone") as! NSArray).componentsJoined(by: "")
                    self.txtphone?.text = phone
                }
                
                self.stopSpinner()
                self.myScrollview?.isHidden = false
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //======Update Profile Click======//
    @IBAction func OnUpdateProfileClick(sender:UIButton)
    {
        if (self.txtusername?.text == "") {
            self.txtusername?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_Name())
            self.txtusername?.bs_showError()
        } else if (self.txtemail?.text == "") {
            self.txtemail?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_email_address())
            self.txtemail?.bs_showError()
        } else if !CommonUtils.validateEmail(with: self.txtemail?.text) {
            self.txtemail?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_Valid_email_address())
            self.txtemail?.bs_showError()
        } else if (self.txtpassword?.text == "") {
            self.txtpassword?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_Password())
            self.txtpassword?.bs_showError()
        } else if (self.txtpassword?.text?.count)! < 6 {
            let errorMessageView = BSErrorMessageView(message: CommonMessage.Password_required_minimum_6_characters())
            errorMessageView?.mainTintColor = UIColor.green
            errorMessageView?.textFont = UIFont.systemFont(ofSize: 14.0)
            errorMessageView?.messageAlwaysShowing = true
            self.txtpassword?.bs_setupErrorMessageView(with: errorMessageView)
            self.txtpassword?.bs_showError()
        } else if (self.txtcofirmpassword?.text == "") {
            self.txtcofirmpassword?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_Confirm_Password())
            self.txtcofirmpassword?.bs_showError()
        } else if (self.txtcofirmpassword?.text?.count)! < 6 {
            let errorMessageView = BSErrorMessageView(message: CommonMessage.Password_required_minimum_6_characters())
            errorMessageView?.mainTintColor = UIColor.green
            errorMessageView?.textFont = UIFont.systemFont(ofSize: 14.0)
            errorMessageView?.messageAlwaysShowing = true
            self.txtcofirmpassword?.bs_setupErrorMessageView(with: errorMessageView)
            self.txtcofirmpassword?.bs_showError()
        } else if (self.txtpassword?.text != self.txtcofirmpassword?.text) {
            self.txtcofirmpassword?.bs_setupErrorMessageView(withMessage: CommonMessage.Password_Not_Matched())
            self.txtcofirmpassword?.bs_showError()
        } else {
            self.txtusername?.resignFirstResponder()
            self.txtemail?.resignFirstResponder()
            self.txtpassword?.resignFirstResponder()
            self.txtcofirmpassword?.resignFirstResponder()
            self.txtphone?.resignFirstResponder()
            
            //===========Get Update User Profile Data==========//
            self.getUpdateUserProfile()
        }
    }
    
    //===========Check Internet Status==========//
    /*func checkInternetStatus1()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            self.getUpdateProfileData()
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    //===========Get Update Profile Data==========//
    func getUpdateProfileData()
    {
        let userID = UserDefaults.standard.string(forKey: "USER_ID")
        let str = NSString(format: "%@api.php?user_profile_update&user_id=%@&name=%@&email=%@&password=%@&phone=%@", CommonUtils.getBaseUrl(),userID!,(self.txtusername?.text)!,(self.txtemail?.text)!,(self.txtpassword?.text)!,(self.txtphone?.text)!)
        let urlEncodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        print("Update Profile API : ",urlEncodedString ?? true)
        let url = URL(string: urlEncodedString!)
        URLSession.shared.dataTask(with:url!)
        {
            (data, response, error) in
            if (error != nil) {
                print("Url Error")
            } else {
                do {
                    let response = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                    print("Responce Data : ",response)
                    if let JSONDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                        self.UpdateArray = (JSONDictionary["NEWS_APP"] as? NSArray)!
                    }
                    print("UpdateArray Count : ",self.UpdateArray.count)
                    
                    DispatchQueue.main.async {
                        let success = (self.UpdateArray.value(forKey: "success") as! NSArray).componentsJoined(by: "")
                        if (success == "0") {
                            let msg = (self.UpdateArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                            KSToastView.ks_showToast(msg, delay: 3.0)
                        } else {
                            let msg = (self.UpdateArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                            KSToastView.ks_showToast(msg, delay: 3.0)
                            _ = self.navigationController?.popViewController(animated:true)
                        }
                        self.stopSpinner()
                    }
                } catch _ as NSError {
                    self.Networkfailure()
                }
            }
            }.resume()
    }*/
    
    //===========Get Update User Profile Data==========//
    func getUpdateUserProfile()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getUpdateUserProfileData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getUpdateUserProfileData(_ requesturl: String?)
    {
        let userID = UserDefaults.standard.string(forKey: "USER_ID")
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign as Any, "method_name":"user_profile_update", "user_id":userID as Any, "name":self.txtusername?.text as Any, "email":self.txtemail?.text as Any, "password":self.txtpassword?.text as Any, "phone":self.txtphone?.text as Any]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("User Profile API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("User Profile Responce Data : \(responseObject)")
                self.UpdateArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.UpdateArray.add(storeDict as Any)
                    }
                }
                print("UpdateArray Count : ",self.UpdateArray.count)

                DispatchQueue.main.async {
                    let success = (self.UpdateArray.value(forKey: "success") as! NSArray).componentsJoined(by: "")
                    if (success == "0") {
                        let msg = (self.UpdateArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                        KSToastView.ks_showToast(msg, delay: 3.0)
                    } else {
                        let msg = (self.UpdateArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                        KSToastView.ks_showToast(msg, delay: 3.0)
                        _ = self.navigationController?.popViewController(animated:true)
                    }
                }
                
                self.stopSpinner()
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //======UITextfield Delegate Methods======//
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.txtusername?.resignFirstResponder()
        self.txtemail?.resignFirstResponder()
        self.txtpassword?.resignFirstResponder()
        self.txtcofirmpassword?.resignFirstResponder()
        self.myScrollview?.contentOffset = .zero
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        self.txtusername?.bs_hideError()
        self.txtemail?.bs_hideError()
        self.txtpassword?.bs_hideError()
        self.txtcofirmpassword?.bs_hideError()
        self.txtphone?.bs_hideError()
        
        if textField == self.txtcofirmpassword {
            NotificationCenter.default.addObserver(self, selector: #selector(self.onKeyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        } else if textField == self.txtphone {
            NotificationCenter.default.addObserver(self, selector: #selector(self.onKeyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        } else {
            //self.myScrollview?.contentOffset = .zero
        }
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,                   replacementString string: String) -> Bool
    {
        self.txtusername?.bs_hideError()
        self.txtemail?.bs_hideError()
        self.txtpassword?.bs_hideError()
        self.txtcofirmpassword?.bs_hideError()
        self.txtphone?.bs_hideError()
        return true
    }
    
    //=======Keyboard Methods=======//
    @IBAction func onKeyboardDoneClicked(_ sender: Any)
    {
        self.myScrollview?.contentOffset = .zero
        self.txtphone?.resignFirstResponder()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    @objc func onKeyboardShow(_ notification: Notification?)
    {
        keyboardHieght = (notification?.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size.height
        self.myScrollview?.contentOffset = CGPoint(x: 0, y: (self.txtphone?.frame.origin.y)! - keyboardHieght)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        //1.Background Color
        self.view.backgroundColor = UIColor(hexString: Colors.getBackgroundColor())
        
        //2.StatusBar Color
        self.lblstatusbar?.backgroundColor = UIColor(hexString: Colors.getStatusBarColor())
        
        //3.Header Color
        self.lblheader?.backgroundColor = UIColor(hexString: Colors.getHeaderColor())
        
        //4.Header Name
        self.lblheadername?.text = CommonMessage.Profile()
        
        //=====User Name Lable====//
        //1.Bottom
        let bottomBorder0 = CALayer()
        bottomBorder0.frame = CGRect(x: 0, y: (self.lblusername?.frame.size.height)!, width: (self.lblusername?.frame.size.width)!, height: 2.0)
        bottomBorder0.borderWidth = 2.0
        bottomBorder0.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblusername?.layer.addSublayer(bottomBorder0)
        //2.Left
        let leftBorder0 = CALayer()
        leftBorder0.frame = CGRect(x: 0, y: (self.lblusername?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder0.borderWidth = 2.0
        leftBorder0.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblusername?.layer.addSublayer(leftBorder0)
        //3.Right
        let rightBorder0 = CALayer()
        rightBorder0.frame = CGRect(x: (self.lblusername?.frame.size.width)! - 2, y: (self.lblusername?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder0.borderWidth = 2.0
        rightBorder0.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblusername?.layer.addSublayer(rightBorder0)
        
        //=====User Email Lable====//
        //1.Bottom
        let bottomBorder1 = CALayer()
        bottomBorder1.frame = CGRect(x: 0, y: (self.lblemail?.frame.size.height)!, width: (self.lblemail?.frame.size.width)!, height: 2.0)
        bottomBorder1.borderWidth = 2.0
        bottomBorder1.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblemail?.layer.addSublayer(bottomBorder1)
        //2.Left
        let leftBorder1 = CALayer()
        leftBorder1.frame = CGRect(x: 0, y: (self.lblemail?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder1.borderWidth = 2.0
        leftBorder1.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblemail?.layer.addSublayer(leftBorder1)
        //3.Right
        let rightBorder1 = CALayer()
        rightBorder1.frame = CGRect(x: (self.lblemail?.frame.size.width)! - 2, y: (self.lblemail?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder1.borderWidth = 2.0
        rightBorder1.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblemail?.layer.addSublayer(rightBorder1)
        
        //=====User Password Lable====//
        //1.Bottom
        let bottomBorder2 = CALayer()
        bottomBorder2.frame = CGRect(x: 0, y: (self.lblpassword?.frame.size.height)!, width: (self.lblpassword?.frame.size.width)!, height: 2.0)
        bottomBorder2.borderWidth = 2.0
        bottomBorder2.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblpassword?.layer.addSublayer(bottomBorder2)
        //2.Left
        let leftBorder2 = CALayer()
        leftBorder2.frame = CGRect(x: 0, y: (self.lblpassword?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder2.borderWidth = 2.0
        leftBorder2.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblpassword?.layer.addSublayer(leftBorder2)
        //3.Right
        let rightBorder2 = CALayer()
        rightBorder2.frame = CGRect(x: (self.lblpassword?.frame.size.width)! - 2, y: (self.lblpassword?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder2.borderWidth = 2.0
        rightBorder2.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblpassword?.layer.addSublayer(rightBorder2)
        
        //=====User Confirm Password Lable====//
        //1.Bottom
        let bottomBorder3 = CALayer()
        bottomBorder3.frame = CGRect(x: 0, y: (self.lblcofirmpassword?.frame.size.height)!, width: (self.lblcofirmpassword?.frame.size.width)!, height: 2.0)
        bottomBorder3.borderWidth = 2.0
        bottomBorder3.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblcofirmpassword?.layer.addSublayer(bottomBorder3)
        //2.Left
        let leftBorder3 = CALayer()
        leftBorder3.frame = CGRect(x: 0, y: (self.lblcofirmpassword?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder3.borderWidth = 2.0
        leftBorder3.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblcofirmpassword?.layer.addSublayer(leftBorder3)
        //3.Right
        let rightBorder3 = CALayer()
        rightBorder3.frame = CGRect(x: (self.lblcofirmpassword?.frame.size.width)! - 2, y: (self.lblcofirmpassword?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder3.borderWidth = 2.0
        rightBorder3.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblcofirmpassword?.layer.addSublayer(rightBorder3)
        
        //=====User Phone Lable====//
        //1.Bottom
        let bottomBorder4 = CALayer()
        bottomBorder4.frame = CGRect(x: 0, y: (self.lblphone?.frame.size.height)!, width: (self.lblphone?.frame.size.width)!, height: 2.0)
        bottomBorder4.borderWidth = 2.0
        bottomBorder4.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblphone?.layer.addSublayer(bottomBorder4)
        //2.Left
        let leftBorder4 = CALayer()
        leftBorder4.frame = CGRect(x: 0, y: (self.lblphone?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder4.borderWidth = 2.0
        leftBorder4.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblphone?.layer.addSublayer(leftBorder4)
        //3.Right
        let rightBorder4 = CALayer()
        rightBorder4.frame = CGRect(x: (self.lblphone?.frame.size.width)! - 2, y: (self.lblphone?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder4.borderWidth = 2.0
        rightBorder4.borderColor = UIColor(hexString: Colors.getTextBorderColor())?.cgColor
        self.lblphone?.layer.addSublayer(rightBorder4)
        
        //=====Username Placeholder Color====//
        self.txtusername?.attributedPlaceholder = NSAttributedString(string: CommonMessage.Name(),                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: Colors.getTextBorderColor())!])
        
        //=====Email Placeholder Color====//
        self.txtemail?.attributedPlaceholder = NSAttributedString(string: CommonMessage.Email(),                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: Colors.getTextBorderColor())!])
        
        //=====Password Placeholder Color====//
        self.txtpassword?.attributedPlaceholder = NSAttributedString(string: CommonMessage.Password(),                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: Colors.getTextBorderColor())!])
        
        //=====Confirm Password Placeholder Color====//
        self.txtcofirmpassword?.attributedPlaceholder = NSAttributedString(string: CommonMessage.ConfirmPassword(),                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: Colors.getTextBorderColor())!])
        
        //=====Password Placeholder Color====//
        self.txtphone?.attributedPlaceholder = NSAttributedString(string: CommonMessage.Phone(),                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: Colors.getTextBorderColor())!])
        
        //=====Register Button====//
        self.btnupdate?.layer.cornerRadius = 5.0
        self.btnupdate?.clipsToBounds = true
        self.btnupdate?.setTitle(CommonMessage.Update(), for: UIControl.State.normal)
        self.btnupdate?.backgroundColor = UIColor(hexString: Colors.getButtonColor())
        
        //=======Set UIScrollview Content Size========//
        //self.myScrollview?.contentSize = CGSize(width: UIScreen.main.bounds.size.width, height: 992)
    }
    
    //=======Start & Stop Spinner=======//
    func startSpinner()
    {
        self.spinner = SWActivityIndicatorView(frame: CGRect(x:(CommonUtils.screenWidth-60)/2, y:(CommonUtils.screenHeight-60)/2, width: 60, height: 60))
        self.spinner.backgroundColor = UIColor.clear
        self.spinner.lineWidth = 3.5
        self.spinner.color = UIColor(hexString: Colors.getSpinnerColor())!
        self.view.addSubview(self.spinner)
        self.spinner.startAnimating()
    }
    func stopSpinner()
    {
        self.spinner.stopAnimating()
        self.spinner.removeFromSuperview()
    }
    
    //=======Internet Connection Not Available=======//
    func InternetConnectionNotAvailable() {
        _ = SCLAlertView().showError(CommonMessage.NetworkError(), subTitle:CommonMessage.InternetConnectionNotAvailable(), closeButtonTitle:CommonMessage.OK())
    }
    func Networkfailure() {
        _ = SCLAlertView().showError(CommonMessage.NetworkError(), subTitle:CommonMessage.CouldNotConnectToServer(), closeButtonTitle:CommonMessage.OK())
    }
    
    //=====Status Bar Hidden & Style=====//
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func OnBackClick(sender:UIButton) {
        _ = navigationController?.popViewController(animated:true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
