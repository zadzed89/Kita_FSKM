//
//  AllComments.swift
//  NewsAppPro
//
//  Created by Apple on 18/02/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit

class AllComments: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextViewDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    var spinner: SWActivityIndicatorView!
    var AllCommentsArray = NSArray()
    @IBOutlet var myTableView : UITableView?
    @IBOutlet var btnComment : UIButton?

    @IBOutlet var opacityView : UIView?
    @IBOutlet var commentView : UIView?
    @IBOutlet var imgCommentView : UIView?
    @IBOutlet var imgComment : UIImageView?
    @IBOutlet var txtComment : UITextView?
    @IBOutlet var btnSend : UIButton?
    var storeArr = NSArray()
    var SendCommentArray = NSMutableArray()
    var UserCommentsArray = NSArray()
    
    private var toast: JYToast!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        toast = JYToast()

        self.AllCommentsArray = UserDefaults.standard.array(forKey: "COMMENTS_ARRAY")! as NSArray
        print("AllCommentsArray = \(self.AllCommentsArray.count)")
        
        //=======Register UITableView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "CommentCell_iPad", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "CommentCell", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        }
        self.myTableView?.contentInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        
        //======Opacity View Touch Event=====//
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(_:)))
        self.opacityView?.addGestureRecognizer(singleFingerTap)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
    }
    
    //=========UITableView Delegate & Datasource Methods========//
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.AllCommentsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentCell
        
        cell.minHeight = 70.0
        
        let userNAME = (self.AllCommentsArray.value(forKey: "user_name") as! NSArray).object(at: indexPath.row) as? String
        cell.lblUserName?.text = userNAME
        let userCOMMENT = (self.AllCommentsArray.value(forKey: "comment_text") as! NSArray).object(at: indexPath.row) as? String
        cell.lblUserComment?.text = userCOMMENT
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("Comment Click = \(indexPath.row)")
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableView.automaticDimension
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 0.0
    }
    
    //======Comments Button Click======//
    @IBAction func OnCommentsClick(sender:UIButton)
    {
        let isLogin = UserDefaults.standard.bool(forKey: "LOGIN")
        if (isLogin) {
            self.opacityView?.isHidden = false
            self.commentView?.isHidden = false
            self.txtComment?.text = ""
            NotificationCenter.default.addObserver(self, selector: #selector(DetailView.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            self.txtComment?.becomeFirstResponder()
        } else {
            UserDefaults.standard.set(true, forKey: "IS_SKIP")
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                let view = Login(nibName: "Login_iPad", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
            } else if (CommonUtils.screenHeight >= 812) {
                let view = Login(nibName: "Login_iPhoneX", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
            } else {
                let view = Login(nibName: "Login", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
            }
        }
    }
    @objc func keyboardWillShow(notification: Notification)
    {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            let keyWidth = keyboardSize.size.width
            let keyHieght = keyboardSize.size.height+85
            self.commentView?.frame = CGRect(x: 5, y: UIScreen.main.bounds.size.height-keyHieght, width: keyWidth-10, height: 80)
        }
    }
    @objc func keyboardWillHide(notification: Notification)
    {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            //let keyWidth = keyboardSize.size.width
            let keyHieght = keyboardSize.size.height
            print("keyboardWillHide = \(keyHieght)")
        }
    }
    @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer?)
    {
        self.txtComment?.text = "";
        self.opacityView?.isHidden = true
        self.txtComment?.resignFirstResponder()
        self.commentView?.isHidden = true
    }
    
    //======Send Comment Button Click======//
    @IBAction func OnSendCommentsClick(sender:UIButton)
    {
        if (!(self.txtComment?.text.isEmptyOrWhitespace())!) {
            self.opacityView?.isHidden = true
            self.txtComment?.resignFirstResponder()
            self.commentView?.isHidden = true
            
           //===========Send User Comment Data==========//
           self.getSendUserComment()
        }
    }
    
    //===========Get Send User Comment Data==========//
    func getSendUserComment()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getSendUserCommentData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getSendUserCommentData(_ requesturl: String?)
    {
        let newsID : String = UserDefaults.standard.string(forKey: "NEWS_ID")!
        let userNAME = UserDefaults.standard.string(forKey: "USER_NAME")
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign as Any, "method_name":"user_comment", "news_id":newsID, "user_name":userNAME as Any, "comment_text":self.txtComment?.text as Any] as [String : Any]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Send User Comment API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Send User Comment Responce Data : \(responseObject)")
                self.SendCommentArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.SendCommentArray.add(storeDict as Any)
                    }
                }
                print("SendCommentArray Count = \(self.SendCommentArray.count)")
                
                DispatchQueue.main.async {
                    let msg = (self.SendCommentArray.value(forKey: "msg") as! NSArray).componentsJoined(by: "")
                    //KSToastView.ks_showToast(msg, delay: 3.0)
                    self.toast.isShow(msg)
                    self.stopSpinner()
                    
                    //======Get Single News Data======//
                    self.myTableView?.isHidden = true
                    self.getSingleNews()
                }
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //===========Get Single News Details Data==========//
    func getSingleNews()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getSingleNewsData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getSingleNewsData(_ requesturl: String?)
    {
        let newsID : String = UserDefaults.standard.string(forKey: "NEWS_ID")!
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_single_news", "news_id":newsID]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Single News API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Single News Responce Data : \(responseObject)")
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count
                {
                    let storeDict:NSDictionary = storeArr[i] as! NSDictionary
                    
                    self.UserCommentsArray = storeDict["user_comments"] as! NSArray
                    let reverseArr =  NSMutableArray(array: self.UserCommentsArray.reverseObjectEnumerator().allObjects).mutableCopy() as! NSArray
                    self.AllCommentsArray = NSMutableArray(array: reverseArr)
                    
                    let isComments = self.UserCommentsArray.componentsJoined(by: "")
                    if (isComments == "") {
                        self.myTableView?.isHidden = true
                    } else {
                        self.myTableView?.isHidden = false
                        self.myTableView?.reloadData()
                    }
                }
                print("UserCommentsArray Count : ",self.UserCommentsArray.count)

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
        self.view.backgroundColor = UIColor(hexString: Colors.getBackgroundColor())
        
        //2.StatusBar Color
        self.lblstatusbar?.backgroundColor = UIColor(hexString: Colors.getStatusBarColor())
        
        //3.Header Color
        self.lblheader?.backgroundColor = UIColor(hexString: Colors.getHeaderColor())
        
        //4.Header Name
        self.lblheadername?.text = CommonMessage.AllComments()
        
        //5.Comment View
        self.commentView?.layer.cornerRadius = 5.0
        self.commentView?.clipsToBounds = true
        self.commentView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.commentView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.commentView?.layer.shadowRadius = 1.0
        self.commentView?.layer.shadowOpacity = 1
        self.commentView?.layer.masksToBounds = false
        self.commentView?.layer.shadowPath = UIBezierPath(roundedRect: (self.commentView?.bounds)!, cornerRadius: (self.commentView?.layer.cornerRadius)!).cgPath
        
        //6.Send Comment ImageView
        self.imgCommentView?.layer.cornerRadius = (self.imgCommentView?.frame.size.width)!/2
        self.imgCommentView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.imgCommentView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.imgCommentView?.layer.shadowRadius = 1.0
        self.imgCommentView?.layer.shadowOpacity = 1
        self.imgCommentView?.layer.masksToBounds = false
        self.imgCommentView?.layer.shadowPath = UIBezierPath(roundedRect: (self.imgCommentView?.bounds)!, cornerRadius: (self.imgCommentView?.layer.cornerRadius)!).cgPath
        self.imgComment?.layer.cornerRadius = (self.imgComment?.frame.size.width)!/2
        self.imgComment?.clipsToBounds = true
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

