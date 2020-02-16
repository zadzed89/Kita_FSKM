//
//  PrivacyPolicy.swift
//  NewsAppPro
//
//  Created by Apple on 12/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit

class PrivacyPolicy: UIViewController,UIWebViewDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnback : UIButton?
    var spinner: SWActivityIndicatorView!
    var PrivacyArray = NSMutableArray()
    @IBOutlet var myView : UIView?
    @IBOutlet var myWebView : UIWebView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //===========Get Privacy Policy Data==========//
        self.myView?.isHidden = true
        self.getPrivacyPolicy()
    }
    
    //===========Get Privacy Policy Data==========//
    func getPrivacyPolicy()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getPrivacyPolicyData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getPrivacyPolicyData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_app_details"]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Privacy Policy API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Privacy Policy Responce Data : \(responseObject)")
                self.PrivacyArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.PrivacyArray.add(storeDict as Any)
                    }
                }
                print("PrivacyArray Count = \(self.PrivacyArray.count)")
                
                DispatchQueue.main.async {
                    let htmlStr = (self.PrivacyArray.value(forKey: "app_privacy_policy") as! NSArray).object(at: 0)
                    self.myWebView?.loadHTMLString(htmlStr as! String, baseURL:nil)
                }
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //========UIWebview Delegate Methods========//
    func webViewDidStartLoad(_ webView: UIWebView)
    {
        print("webViewDidStartLoad")
    }
    internal func webView(_ webView: UIWebView, didFailLoadWithError error: Error)
    {
        print("Webview ",error.localizedDescription)
    }
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        self.stopSpinner()
        self.myView?.isHidden = false
    }
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest,                          navigationType: UIWebView.NavigationType) -> Bool
    {
        if navigationType == .linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
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
        self.lblheadername?.text = CommonMessage.PrivacyPolicy()
        
        //5.My View
        self.myView?.layer.cornerRadius = 5.0
        self.myView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.myView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.myView?.layer.shadowRadius = 1.0
        self.myView?.layer.shadowOpacity = 1
        self.myView?.layer.masksToBounds = false
        self.myView?.layer.shadowPath = UIBezierPath(roundedRect: (self.myView?.bounds)!, cornerRadius: (self.myView?.layer.cornerRadius)!).cgPath

        //6.UIWebView
        self.myWebView?.layer.cornerRadius = 5.0
        self.myWebView?.clipsToBounds = true
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
