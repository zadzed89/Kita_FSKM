//
//  Register.swift
//  NewsAppPro
//
//  Created by Apple on 10/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit

class Register: UIViewController,UITextFieldDelegate
{
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
    @IBOutlet var btnregister : UIButton?
    @IBOutlet var lblalreadyaccount : UILabel?
    @IBOutlet var btnlogin : UIButton?
    @IBOutlet var lblline : UILabel?
    var RegisterArray = NSMutableArray()

    let spinner = SDLoader()
    var keyboardHieght : CGFloat = 0.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //========PackageName Notification========//
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivePackageNameNotification(_:)), name: NSNotification.Name("PackageNameNotification"), object: nil)
        
        //=====Phone Keyboard=====//
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.onKeyboardDoneClicked(_:)))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        self.txtphone?.inputAccessoryView = keyboardToolbar
    }
    
    //======Register Click======//
    @IBAction func OnRegisterClick(sender:UIButton)
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
            self.getRegister()
        }
    }
    
    //===========Get Register Data==========//
    func getRegister()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getRegisterData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getRegisterData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let name = self.txtusername?.text
        let email = self.txtemail?.text
        let password = self.txtpassword?.text
        let phone = self.txtphone?.text
        let dict = ["salt":salt, "sign":sign, "method_name":"user_register", "name":name, "email":email, "password":password, "phone":phone]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Register API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Register Responce Data : \(responseObject)")
                self.RegisterArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if storeDict != nil {
                        self.RegisterArray.add(storeDict as Any)
                    }
                }
                print("RegisterArray Count = \(self.RegisterArray.count)")
                
                DispatchQueue.main.async {
                    let success = (self.RegisterArray.value(forKey: "success") as! NSArray).componentsJoined(by: "")
                    if (success == "0") {
                        let msg = (self.RegisterArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                        KSToastView.ks_showToast(msg, duration: 3.0) {
                            print("\("End!")")
                        }
                    } else {
                        let msg = (self.RegisterArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                        KSToastView.ks_showToast(msg, duration: 3.0) {
                            print("\("End!")")
                        }
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
        
        //=====Welcome Title 1====//
        self.lblsignup?.text = CommonMessage.SignUp()
        
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
        
        //=====Email Lable====//
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
        
        //=====Password Lable====//
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
        
        //=====Confirm Password Lable====//
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
        
        //=====Phone Lable====//
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
        self.btnregister?.layer.cornerRadius = 5.0
        self.btnregister?.clipsToBounds = true
        self.btnregister?.setTitle(CommonMessage.REGISTER(), for: UIControl.State.normal)
        self.btnregister?.backgroundColor = UIColor(hexString: Colors.getButtonColor())
        
        //=====Already Have an Account Button====//
        self.lblalreadyaccount?.text = CommonMessage.AlreadyHaveanAccount()
        
        //=====Login Button====//
        self.btnlogin?.setTitle(CommonMessage.Login(), for: UIControl.State.normal)
        self.btnlogin?.setTitleColor(UIColor(hexString: Colors.getButtonColor()), for: UIControl.State.normal)
        
        //=====Bottom Line====//
        self.lblline?.layer.cornerRadius = (self.lblline?.frame.size.height)!/2
        self.lblline?.clipsToBounds = true
        self.lblline?.backgroundColor = UIColor(hexString: Colors.getButtonColor())
        
        //=======Set UIScrollview Content Size========//
        self.myScrollview?.contentSize = CGSize(width: UIScreen.main.bounds.size.width, height: 875)
    }
    
    //========Recive PackageName Notification========//
    @objc func receivePackageNameNotification(_ notification: Notification?)
    {
        if ((notification?.name)!.rawValue == "PackageNameNotification")
        {
            let isPackageNameSame = UserDefaults.standard.bool(forKey: "PACKAGENAME")
            if (!isPackageNameSame) {
                let msg = "You are using invalid License or Package name is already in use, for more information contact us: info@viaviweb.com or viaviwebtech@gmail.com"
                let uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertController.Style.alert)
                self.present(uiAlert, animated: true, completion: nil)
            }
        }
    }
    
    //=======Start & Stop Spinner=======//
    func startSpinner()
    {
        self.spinner.spinner?.lineWidth = 15
        self.spinner.spinner?.spacing = 0.2
        self.spinner.spinner?.sectorColor = UIColor.cyan.cgColor
        self.spinner.spinner?.textColor = UIColor.cyan
        self.spinner.spinner?.animationType = AnimationType.anticlockwise
        self.spinner.startAnimating(atView: self.view)
    }
    func stopSpinner()
    {
        self.spinner.stopAnimation()
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
        return true
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //======Login Click======//
    @IBAction func OnLoginClick(sender:UIButton)
    {
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
