//
//  ForgotPassword.swift
//  NewsAppPro
//
//  Created by Apple on 14/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit

class ForgotPassword: UIViewController,UITextFieldDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnback : UIButton?
    @IBOutlet var lblfgp : UILabel?
    @IBOutlet var lbldesc : UILabel?
    @IBOutlet var lblemail : UILabel?
    @IBOutlet var txtemail : UITextField?
    @IBOutlet var btnsend : UIButton?
    var ForgotArray = NSMutableArray()
    
    let spinner = SDLoader()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //========PackageName Notification========//
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivePackageNameNotification(_:)), name: NSNotification.Name("PackageNameNotification"), object: nil)
    }
    
    //======Send Click======//
    @IBAction func OnSendClick(sender:UIButton)
    {
        if (self.txtemail?.text == "") {
            self.txtemail?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_email_address())
            self.txtemail?.bs_showError()
        } else if !CommonUtils.validateEmail(with: self.txtemail?.text) {
            self.txtemail?.bs_setupErrorMessageView(withMessage: CommonMessage.Enter_Valid_email_address())
            self.txtemail?.bs_showError()
        }  else {
            self.txtemail?.resignFirstResponder()
            self.getForgot()
        }
    }
    
    //===========Get Forgot Password Data==========//
    func getForgot()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getForgotData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getForgotData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let email = self.txtemail?.text
        let dict = ["salt":salt, "sign":sign, "method_name":"forgot_pass", "email":email]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Forgot Password API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Forgot Responce Data : \(responseObject)")
                self.ForgotArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if storeDict != nil {
                        self.ForgotArray.add(storeDict as Any)
                    }
                }
                print("ForgotArray Count = \(self.ForgotArray.count)")
                
                DispatchQueue.main.async {
                    let success = (self.ForgotArray.value(forKey: "success") as! NSArray).componentsJoined(by: "")
                    if (success == "0") {
                        let msg = (self.ForgotArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                        KSToastView.ks_showToast(msg, duration: 3.0) {
                            print("\("End!")")
                        }
                    } else {
                        let msg = (self.ForgotArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
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
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        //1.Background Color
        self.view.backgroundColor = UIColor.white
        
        //2.StatusBar Color
        self.lblstatusbar?.backgroundColor = UIColor(hexString: Colors.getStatusBarColor())
        
        //3.Header Color
        self.lblheader?.backgroundColor = UIColor(hexString: Colors.getHeaderColor())
        
        //4.Header Name
        self.lblheadername?.text = CommonMessage.ForgotYourPassword()
        
        //5.Forgot Your Password Lable
        self.lblfgp?.text = CommonMessage.ForgotYourPassword()
        
        //6.Forgot Password Description
        self.lbldesc?.text = CommonMessage.getForgotDescription()
        
        //7.Email Placeholder Color
        self.txtemail?.attributedPlaceholder = NSAttributedString(string: CommonMessage.EnterYourEmail(),                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        //=====Email Lable====//
        //1.Bottom
        let bottomBorder1 = CALayer()
        bottomBorder1.frame = CGRect(x: 0, y: (self.lblemail?.frame.size.height)!, width: (self.lblemail?.frame.size.width)!, height: 2.0)
        bottomBorder1.borderWidth = 2.0
        bottomBorder1.borderColor = UIColor.black.cgColor
        self.lblemail?.layer.addSublayer(bottomBorder1)
        //2.Left
        let leftBorder1 = CALayer()
        leftBorder1.frame = CGRect(x: 0, y: (self.lblemail?.frame.size.height)! - 5, width: 2, height: 5)
        leftBorder1.borderWidth = 2.0
        leftBorder1.borderColor = UIColor.black.cgColor
        self.lblemail?.layer.addSublayer(leftBorder1)
        //3.Right
        let rightBorder1 = CALayer()
        rightBorder1.frame = CGRect(x: (self.lblemail?.frame.size.width)! - 2, y: (self.lblemail?.frame.size.height)! - 5, width: 2, height: 5)
        rightBorder1.borderWidth = 2.0
        rightBorder1.borderColor = UIColor.black.cgColor
        self.lblemail?.layer.addSublayer(rightBorder1)
        
        //8.Send Button
        self.btnsend?.layer.cornerRadius = 5.0
        self.btnsend?.clipsToBounds = true
        self.btnsend?.setTitle(CommonMessage.SEND(), for: UIControl.State.normal)
        self.btnsend?.backgroundColor = UIColor(hexString: Colors.getButtonColor())
    }
    
    //======UITextfield Delegate Methods======//
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.txtemail?.resignFirstResponder()
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        self.txtemail?.bs_hideError()
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,                   replacementString string: String) -> Bool
    {
        self.txtemail?.bs_hideError()
        return true
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
