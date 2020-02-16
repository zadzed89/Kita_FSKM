//
//  Latest.swift
//  NewsAppPro
//
//  Created by Apple on 10/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit
import AVKit
import GoogleMobileAds

class Latest: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,GADBannerViewDelegate,GADInterstitialDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnback : UIButton?
    @IBOutlet var btnsearch : UIButton?
    @IBOutlet var myTableView : UITableView?
    @IBOutlet var lblnodatafound : UILabel?
    @IBOutlet var searchBar : UISearchBar?
    @IBOutlet var btnbacksearch : UIButton?
    var spinner: SWActivityIndicatorView!
    var LatestArray = NSMutableArray()
    
    var encodedString : String?
    var strImgPath : String?
    
    var bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
    var interstitial: GADInterstitial!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //=======Register UITableView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "NewsBigCell_iPad", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "NewsBigCell", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        }
        self.myTableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0);
        
        //======Get Latest News Data======//
        self.myTableView?.isHidden = true
        self.getLatestNews()
    }
    
    //===========Get Latest News Data==========//
    func getLatestNews()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getLatestNewsData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getLatestNewsData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_latest"]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Latest News API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Latest News Responce Data : \(responseObject)")
                self.LatestArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.LatestArray.add(storeDict as Any)
                    }
                }
                print("LatestArray Count = \(self.LatestArray.count)")
                
                DispatchQueue.main.async {
                    if (self.LatestArray.count == 0) {
                        self.myTableView?.isHidden = true
                        self.lblnodatafound?.isHidden = false
                    } else {
                        self.myTableView?.isHidden = false
                        self.lblnodatafound?.isHidden = true
                        self.myTableView?.reloadData()
                        self.CallAdmobBanner()
                    }
                }
                
                self.stopSpinner()
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //=========UITableView Delegate & Datasource Methods========//
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return self.LatestArray.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NewsBigCell
        
        let newsType : String? = (self.LatestArray.value(forKey: "news_type") as! NSArray).object(at: indexPath.section) as? String
        if (newsType == "video") {
            let videoID : String? = (self.LatestArray.value(forKey: "video_id") as! NSArray).object(at: indexPath.section) as? String
            strImgPath = String(format: "http://i3.ytimg.com/vi/%@/hqdefault.jpg", videoID!)
            cell.btnPlay?.isHidden = false
        } else {
            strImgPath = (self.LatestArray.value(forKey: "news_image_b") as! NSArray).object(at: indexPath.section) as? String
            cell.btnPlay?.isHidden = true
        }
        let encodedString = strImgPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encodedString!)
        cell.newsImageView?.sd_setImage(with: url, completed: nil)
        
        cell.lblNewsTitle?.text = (self.LatestArray.value(forKey: "news_title") as! NSArray).object(at: indexPath.section) as? String
        cell.lblDate?.text = (self.LatestArray.value(forKey: "news_date") as! NSArray).object(at: indexPath.section) as? String
        cell.lblViews?.text = (self.LatestArray.value(forKey: "news_views") as! NSArray).object(at: indexPath.section) as? String
        
        cell.btnPlay?.addTarget(self, action:#selector(self.OnPlayBigVideoClick), for: .touchUpInside)
        cell.btnPlay?.tag = indexPath.section
        
        cell.btnFav?.addTarget(self, action:#selector(self.OnFavBigNewsClick), for: .touchUpInside)
        cell.btnFav?.tag = indexPath.section
        
        cell.btnShare?.addTarget(self, action:#selector(self.OnShareBigNewsClick), for: .touchUpInside)
        cell.btnShare?.tag = indexPath.section
        
        DispatchQueue.main.async {
            let htmlDesc = (self.LatestArray.value(forKey: "news_description") as! NSArray).object(at: indexPath.section) as? String
            let htmlString = String(format: "%@%@", Settings.SetWebViewFont(),htmlDesc!)
            cell.webDesc?.scrollView.isScrollEnabled = false
            cell.webDesc?.loadHTMLString(htmlString, baseURL:nil)
        }
        
        //Check News Favourite or Not
        let modalObj: Modal = Modal()
        modalObj.id = ((self.LatestArray.value(forKey: "id") as! NSArray).object(at: indexPath.section) as? String)!
        let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
        if (isNewsExist.count == 0) {
            cell.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
        } else {
            cell.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            return 330.0
        } else {
            return 230.0
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 15.0
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        view.tintColor = UIColor.clear
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let newsID : String = ((self.LatestArray.value(forKey: "id") as! NSArray).object(at: indexPath.section) as? String)!
        UserDefaults.standard.set(newsID, forKey: "NEWS_ID")
        self.CallAdmobInterstitial()
    }
    @objc private func OnPlayBigVideoClick(_ sender: UIButton?)
    {
        let video_id : String = ((self.LatestArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        let playerViewController = AVPlayerViewController()
        present(playerViewController, animated: true)
        weak var weakPlayerViewController: AVPlayerViewController? = playerViewController
        XCDYouTubeClient.default().getVideoWithIdentifier(video_id, completionHandler: { video, error in
            if video != nil {
                let streamURLs = video?.streamURLs
                let streamURL = streamURLs?[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs?[XCDYouTubeVideoQuality.HD720.rawValue] ?? streamURLs?[XCDYouTubeVideoQuality.medium360.rawValue] ?? streamURLs?[XCDYouTubeVideoQuality.small240.rawValue]
                if let anURL = streamURL {
                    weakPlayerViewController?.player = AVPlayer(url: anURL)
                }
                weakPlayerViewController?.player?.play()
            } else {
                self.dismiss(animated: true)
            }
        })
    }
    @objc private func OnFavBigNewsClick(_ sender: UIButton?)
    {
        let modalObj: Modal = Modal()
        modalObj.id = ((self.LatestArray.value(forKey: "id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cid = ((self.LatestArray.value(forKey: "cid") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.category_name = ((self.LatestArray.value(forKey: "category_name") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cat_id = ((self.LatestArray.value(forKey: "cat_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_type = ((self.LatestArray.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_title  = ((self.LatestArray.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_url = ((self.LatestArray.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_id = ((self.LatestArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_b = ((self.LatestArray.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_s = ((self.LatestArray.value(forKey: "news_image_s") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_description = ((self.LatestArray.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_date = ((self.LatestArray.value(forKey: "news_date") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_views = ((self.LatestArray.value(forKey: "news_views") as! NSArray).object(at: (sender?.tag)!) as? String)!
        
        let indexpath = IndexPath(row: 0, section: (sender?.tag)!)
        let tappedButton = self.myTableView!.cellForRow(at: indexpath) as? NewsBigCell
        let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
        if (isNewsExist.count != 0)
        {
            let isDeleted = Singleton.getInstance().DeleteQueryData(modalObj)
            if (isDeleted) {
                tappedButton?.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
            }
        } else {
            let isInserted = Singleton.getInstance().InsertQueryData(modalObj)
            if (isInserted) {
                tappedButton?.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
            }
        }
    }
    @objc private func OnShareBigNewsClick(_ sender: UIButton?)
    {
        let news_title = (self.LatestArray.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!)
        let news_image_b = (self.LatestArray.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!)
        let news_description = (self.LatestArray.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!)
        let news_type : String = (self.LatestArray.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as! String
        let video_id = (self.LatestArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!)
        let video_url = (self.LatestArray.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!)
        let description = try? NSAttributedString(htmlString:news_description as! String)
        if (news_type == "video") {
            let youtubeIMAGE = "http://i3.ytimg.com/vi/\(video_id)/hqdefault.jpg"
            encodedString = (youtubeIMAGE as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        } else {
            encodedString = (news_image_b as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        let imgURL = URL(string: encodedString!)
        let data = try? Data(contentsOf: imgURL!)
        let image = UIImage(data: data!)
        let title:NSString = NSString(format: "%@", news_title as! CVarArg)
        let strDesc = description?.string
        let desc:NSString = NSString(format: "%@", strDesc!)
        let videoURL:NSURL = NSURL(string: video_url as! String)!
        let objectsToShare = [title,"\n",desc,"\n",videoURL,image as Any] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.postToVimeo]
        activityVC.excludedActivityTypes = objectsToShare as? [UIActivity.ActivityType]
        DispatchQueue.main.async(execute: {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                DispatchQueue.main.async(execute: {
                    if let popoverController = activityVC.popoverPresentationController {
                        popoverController.sourceView = self.view
                        popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                        self.present(activityVC, animated: true)
                    }
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.present(activityVC, animated: true)
                })
            }
        })
    }
    
    //======Search Button Click======//
    @IBAction func OnSearchClick(sender:UIButton)
    {
        self.searchBar?.becomeFirstResponder()
        self.searchBar?.isHidden = false
        self.btnbacksearch?.isHidden = false
        self.btnback?.isHidden = true
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        UserDefaults.standard.set(self.searchBar?.text, forKey: "SEARCH_TEXT")
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.btnbacksearch?.isHidden = true
        self.btnback?.isHidden = false
        self.searchBar?.text = ""
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = SearchView(nibName: "SearchView_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = SearchView(nibName: "SearchView_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = SearchView(nibName: "SearchView", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    @IBAction func OnBackSearchClick(sender:UIButton)
    {
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.btnbacksearch?.isHidden = true
        self.searchBar?.text = ""
        self.btnback?.isHidden = false
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
        self.lblheadername?.text = CommonMessage.LatestNews()
        
        //5.No Data Found
        self.lblnodatafound?.text = CommonMessage.NoNewsFound()
        
        //6.UITableview Clear Color
        self.myTableView?.backgroundColor = UIColor.clear
        
        //7.UISearchbar Clear Background Color
        if #available(iOS 13.0, *) {
            self.searchBar?.barTintColor = UIColor(hexString: Colors.getHeaderColor())
            self.searchBar?.searchTextField.backgroundColor = UIColor.white
        } else {
            for subView in (self.searchBar?.subviews)! {
                for view in subView.subviews {
                    if view.isKind(of: NSClassFromString("UISearchBarBackground")!) {
                        let imageView = view as! UIImageView
                        imageView.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    //================Admob Banner Ads===============//
    func CallAdmobBanner()
    {
        let isBannerAd = UserDefaults.standard.value(forKey: "banner_ad_ios") as? String
        if (isBannerAd == "true") {
            let isGDPR_STATUS: Bool = UserDefaults.standard.bool(forKey: "GDPR_STATUS")
            if (isGDPR_STATUS) {
                let request = DFPRequest()
                let extras = GADExtras()
                extras.additionalParameters = ["npa": "1"]
                request.register(extras)
                self.setAdmob()
            } else {
                self.setAdmob()
            }
        } else {
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                self.myTableView?.frame = CGRect(x: 10, y: 75, width: CommonUtils.screenWidth-20, height: CommonUtils.screenHeight-75)
            } else if (CommonUtils.screenHeight >= 812) {
                self.myTableView?.frame = CGRect(x: 10, y: 100, width: CommonUtils.screenWidth-20, height: CommonUtils.screenHeight-100)
            } else {
                self.myTableView?.frame = CGRect(x: 10, y: 75, width: CommonUtils.screenWidth-20, height: CommonUtils.screenHeight-75)
            }
        }
    }
    func setAdmob()
    {
        let banner_ad_id_ios = UserDefaults.standard.value(forKey: "banner_ad_id_ios") as? String
        bannerView = GADBannerView(frame: CGRect(x:10, y:CommonUtils.screenHeight-50, width:CommonUtils.screenWidth-20, height:50))
        addBannerView(to: bannerView)
        bannerView.adUnitID = banner_ad_id_ios
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    func adViewDidReceiveAd(_ adView: GADBannerView)
    {
        // We've received an ad so lets show the banner
        print("adViewDidReceiveAd")
    }
    func adView(_ adView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError)
    {
        // Failed to receive an ad from AdMob so lets hide the banner
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription )")
    }
    func addBannerView(to bannerView: UIView?)
    {
        if let aView = bannerView {
            view.addSubview(aView)
        }
        if let aView = bannerView {
            view.addConstraints([NSLayoutConstraint(item: aView, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0), NSLayoutConstraint(item: aView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)])
        }
    }
    
    //================Admob Interstitial Ads===============//
    func CallAdmobInterstitial()
    {
        //1.Interstitial Ad Click
        let ad_click: Int = UserDefaults.standard.integer(forKey: "ADClick")
        UserDefaults.standard.set(ad_click + 1, forKey: "ADClick")
        //2.Load Interstitial
        let isInterstitialAd = UserDefaults.standard.value(forKey: "interstital_ad_ios") as? String
        if (isInterstitialAd == "true") {
            let interstital_ad_click_ios = UserDefaults.standard.value(forKey: "interstital_ad_click_ios") as? String
            let adminCount = Int(interstital_ad_click_ios!)
            let ad_click1: Int = UserDefaults.standard.integer(forKey: "ADClick")
            print("ad_click1 : \(ad_click1)")
            if (ad_click1 % adminCount! == 0) {
                let isGDPR_STATUS: Bool = UserDefaults.standard.bool(forKey: "GDPR_STATUS")
                if (isGDPR_STATUS) {
                    let request = DFPRequest()
                    let extras = GADExtras()
                    extras.additionalParameters = ["npa": "1"]
                    request.register(extras)
                    self.createAndLoadInterstitial()
                } else {
                    self.createAndLoadInterstitial()
                }
            } else {
                self.pushScreen()
            }
        } else {
            self.createAndLoadInterstitial()
        }
    }
    func createAndLoadInterstitial()
    {
        let interstitialAdId = UserDefaults.standard.value(forKey: "interstital_ad_id_ios") as? String
        interstitial = GADInterstitial(adUnitID: interstitialAdId!)
        let request = GADRequest()
        interstitial.delegate = self
        //request.testDevices = @[ kGADSimulatorID ];
        interstitial.load(request)
    }
    func interstitialDidReceiveAd(_ ad: GADInterstitial)
    {
        if (interstitial.isReady) {
            interstitial.present(fromRootViewController: self)
        } else {
            print("interstitial Ad wasn't ready")
            pushScreen()
        }
    }
    func interstitialWillDismissScreen(_ ad: GADInterstitial)
    {
        print("interstitialWillDismissScreen")
        pushScreen()
    }
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError)
    {
        pushScreen()
    }
    func pushScreen()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = DetailView(nibName: "DetailView_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = DetailView(nibName: "DetailView_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = DetailView(nibName: "DetailView", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
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
