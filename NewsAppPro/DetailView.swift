//
//  DetailView.swift
//  NewsAppPro
//  
//  Created by Apple on 11/02/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit
import AVKit
import GoogleMobileAds

class DetailView: UIViewController,UIWebViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,GADBannerViewDelegate,GADInterstitialDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnshare : UIButton?
    var spinner: SWActivityIndicatorView!
    var DetailsArray = NSMutableArray()
    var storeArr = NSArray()
    var GalleryArray = NSArray()
    var RelatedArray = NSArray()
    var UserCommentsArray = NSArray()
    var SendCommentArray = NSMutableArray()
    
    @IBOutlet var myScrollview : UIScrollView?
    @IBOutlet var myView : UIView?
    @IBOutlet var iconImageView : UIImageView?
    @IBOutlet var btnIconImage : UIButton?
    @IBOutlet var myView1 : UIView?
    @IBOutlet var myView2 : UIView?
    @IBOutlet var myView3 : UIView?
    @IBOutlet var imgView : UIView?
    @IBOutlet var lblNewsTitle : UILabel?
    @IBOutlet var btnPlay : UIButton?
    @IBOutlet var btnFav : UIButton?
    @IBOutlet var lblDate : UILabel?
    @IBOutlet var lblViews : UILabel?
    @IBOutlet var btnShare : UIButton?
    @IBOutlet var webDesc : UIWebView?
    @IBOutlet var myCollectionView : UICollectionView?
    @IBOutlet var lblRelated : UILabel?
    @IBOutlet var lblComments : UILabel?
    @IBOutlet var btnViewAllComments : UIButton?
    @IBOutlet var imgComments : UIImageView?
    @IBOutlet var btnComment : UIButton?
    @IBOutlet var myTableView : UITableView?
    
    @IBOutlet var opacityView : UIView?
    @IBOutlet var commentView : UIView?
    @IBOutlet var imgCommentView : UIView?
    @IBOutlet var imgComment : UIImageView?
    @IBOutlet var txtComment : UITextView?
    @IBOutlet var btnSend : UIButton?
    @IBOutlet var btnAllComments : UIButton?

    var encodedString : String?
    var strImgPath : String?
    var newsTitleHeight : CGFloat = 0.0
    
    private var toast: JYToast!

    var bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
    var interstitial: GADInterstitial!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        toast = JYToast()
        
        //=======Register UICollectionView2 Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "NewsSmallCell_iPad", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "NewsSmallCell", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        }
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            flowLayout.itemSize = CGSize(width: 420, height: 150)
        } else {
            flowLayout.itemSize = CGSize(width: 320, height: 150)
        }
        self.myCollectionView?.collectionViewLayout = flowLayout
        
        //=======Register UITableView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "CommentCell_iPad", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "CommentCell", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        }
        //self.automaticallyAdjustsScrollViewInsets = false
        
        //======Opacity View Touch Event=====//
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(_:)))
        self.opacityView?.addGestureRecognizer(singleFingerTap)
        
        //======Get Single News Data======//
        self.myScrollview?.isHidden = true
        self.getSingleNews()
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
                self.DetailsArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count
                {
                    let storeDict:NSDictionary = storeArr[i] as! NSDictionary
                    self.DetailsArray.add(storeDict)
                    self.GalleryArray = storeDict["galley_image"] as! NSArray
                    
                    let isRelated = storeDict["related_news"]
                    if (isRelated is NSNull) {
                        self.myView2?.isHidden = true
                    } else {
                        self.myView2?.isHidden = false
                        self.RelatedArray = storeDict["related_news"] as! NSArray
                        self.myCollectionView?.reloadData()
                    }
                    
                    self.UserCommentsArray = storeDict["user_comments"] as! NSArray
                    let reverseArr =  NSMutableArray(array: self.UserCommentsArray.reverseObjectEnumerator().allObjects).mutableCopy() as! NSArray
                    self.UserCommentsArray = NSMutableArray(array: reverseArr)
                    let isComments = self.UserCommentsArray.componentsJoined(by: "")
                    if (isComments == "") {
                        self.btnAllComments?.isHidden = true
                        self.btnViewAllComments?.isHidden = true
                        self.myTableView?.isHidden = true
                    } else {
                        self.btnAllComments?.isHidden = false
                        self.btnViewAllComments?.isHidden = false
                        self.myTableView?.isHidden = false
                        self.myTableView?.reloadData()
                    }
                }
                print("DetailsArray Count = \(self.DetailsArray.count)")
                print("RelatedArray Count = \(self.RelatedArray.count)")
                print("UserCommentsArray Count : ",self.UserCommentsArray.count)

                self.SetDataIntoScrollView()
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    //======Set Data Into ScrollView=======//
    func SetDataIntoScrollView()
    {
        //1.Check News Favourite or Not
        let modalObj: Modal = Modal()
        modalObj.id = (self.DetailsArray.value(forKey: "id") as! NSArray).componentsJoined(by: "")
        let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
        if (isNewsExist.count == 0) {
            self.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
        } else {
            self.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
        }
        
        //2.Icon ImageView
        let newsType : String? = (self.DetailsArray.value(forKey: "news_type") as! NSArray).componentsJoined(by: "")
        if (newsType == "video") {
            let videoID : String? = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
            strImgPath = String(format: "http://i3.ytimg.com/vi/%@/hqdefault.jpg", videoID!)
            self.btnPlay?.isHidden = false
        } else {
            strImgPath = (self.DetailsArray.value(forKey: "news_image_b") as! NSArray).componentsJoined(by: "")
            self.btnPlay?.isHidden = true
        }
        let encodedString = strImgPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encodedString!)
        self.iconImageView?.sd_setImage(with: url, completed: nil)
        
        //3.News Title
        let news_title : String? = (self.DetailsArray.value(forKey: "news_title") as! NSArray).componentsJoined(by: "")
        self.lblNewsTitle?.text = news_title
        self.lblNewsTitle?.numberOfLines = 0
        self.lblNewsTitle?.lineBreakMode = .byWordWrapping
        self.lblNewsTitle?.sizeToFit()
        let font = UIFont(name: "Poppins-Medium", size: 15.0)
        newsTitleHeight = heightForView(text: news_title!, font: font!, width: (self.myView?.frame.size.width)!-20)
        
        //4.Set MyView1 Frame
        self.myView1?.frame = CGRect(x: 8, y: newsTitleHeight+20, width: (self.myView?.frame.size.width)!-16, height: 20)
        
        //5.News Date
        let news_date : String? = (self.DetailsArray.value(forKey: "news_date") as! NSArray).componentsJoined(by: "")
        self.lblDate?.text = news_date
        
        //6.News Viewed
        let news_views : String? = (self.DetailsArray.value(forKey: "news_views") as! NSArray).componentsJoined(by: "")
        self.lblViews?.text = news_views

        //7.News Description
        DispatchQueue.main.async {
            let htmlDesc : String? = (self.DetailsArray.value(forKey: "news_description") as! NSArray).componentsJoined(by: "")
            let htmlString = String(format: "%@%@", Settings.SetWebViewDetailsPageFont(),htmlDesc!)
            self.webDesc?.scrollView.isScrollEnabled = false
            self.webDesc?.loadHTMLString(htmlString, baseURL:nil)
        }
    }
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        //1.WebView Description
        let webHeight = self.webDesc?.scrollView.contentSize.height
        self.webDesc?.frame = CGRect(x: 3, y: self.newsTitleHeight+20+25, width: (self.myView?.frame.size.width)!-6, height: webHeight!)
        
        //2.MyView Frame
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            self.myView?.frame = CGRect(x: 10, y: 410, width: (self.myScrollview?.frame.size.width)!-20, height: self.newsTitleHeight+20+25+webHeight!)
        } else {
            self.myView?.frame = CGRect(x: 10, y: 210, width: (self.myScrollview?.frame.size.width)!-20, height: self.newsTitleHeight+20+25+webHeight!)
        }
        self.myView?.layer.cornerRadius = 5.0
        self.myView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.myView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.myView?.layer.shadowRadius = 1.0
        self.myView?.layer.shadowOpacity = 1
        self.myView?.layer.masksToBounds = false
        self.myView?.layer.shadowPath = UIBezierPath(roundedRect: (self.myView?.bounds)!, cornerRadius: (self.myView?.layer.cornerRadius)!).cgPath
        
        //3.MyView2 Frame
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            self.myView2?.frame = CGRect(x: 10, y: 410+self.newsTitleHeight+20+25+webHeight!+10, width: (self.myScrollview?.frame.size.width)!-20, height: self.newsTitleHeight+20+25+webHeight!+180)
        } else {
            self.myView2?.frame = CGRect(x: 10, y: 210+self.newsTitleHeight+20+25+webHeight!+10, width: (self.myScrollview?.frame.size.width)!-20, height: self.newsTitleHeight+20+25+webHeight!+180)
        }
        
        //5.ScrollView Hieght
        if (self.RelatedArray.count == 0) {
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                let isComments = self.UserCommentsArray.componentsJoined(by: "")
                if (isComments == "") {
                    self.myView3?.frame = CGRect(x: 10, y: 410+self.newsTitleHeight+20+25+webHeight!+15, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+430+115)
                } else {
                    self.myView3?.frame = CGRect(x: 10, y: 410+self.newsTitleHeight+20+25+webHeight!+15, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                    let tableHieght:CGFloat = (self.myTableView?.contentSize.height)!
                    //print("TableView Hieght = \(tableHieght)")
                    self.myTableView?.frame = CGRect(x: 5, y: 410+self.newsTitleHeight+20+25+webHeight!+15+115, width: (self.myScrollview?.frame.size.width)!-10, height: tableHieght+30)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+430+115+tableHieght)
                }
            } else {
                let isComments = self.UserCommentsArray.componentsJoined(by: "")
                if (isComments == "") {
                    self.myView3?.frame = CGRect(x: 10, y: 210+self.newsTitleHeight+20+25+webHeight!+15, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+230+115)
                } else {
                    self.myView3?.frame = CGRect(x: 10, y: 210+self.newsTitleHeight+20+25+webHeight!+15, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                    let tableHieght:CGFloat = (self.myTableView?.contentSize.height)!
                    //print("TableView Hieght = \(tableHieght)")
                    self.myTableView?.frame = CGRect(x: 5, y: 210+self.newsTitleHeight+20+25+webHeight!+15+115, width: (self.myScrollview?.frame.size.width)!-10, height: tableHieght+30)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+230+115+tableHieght)
                }
            }
        } else {
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                self.myView3?.frame = CGRect(x: 10, y: 410+self.newsTitleHeight+20+25+webHeight!+180+35, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                let isComments = self.UserCommentsArray.componentsJoined(by: "")
                if (isComments == "") {
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+430+200+115)
                } else {
                    let tableHieght:CGFloat = (self.myTableView?.contentSize.height)!
                    //print("TableView Hieght = \(tableHieght)")
                    self.myTableView?.frame = CGRect(x: 5, y: 410+self.newsTitleHeight+20+25+webHeight!+180+35+115, width: (self.myScrollview?.frame.size.width)!-10, height: tableHieght+30)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+430+200+115+tableHieght)
                }
            } else {
                self.myView3?.frame = CGRect(x: 10, y: 210+self.newsTitleHeight+20+25+webHeight!+180+35, width: (self.myScrollview?.frame.size.width)!-20, height: 115)
                let isComments = self.UserCommentsArray.componentsJoined(by: "")
                if (isComments == "") {
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+230+200+115)
                } else {
                    let tableHieght:CGFloat = (self.myTableView?.contentSize.height)!
                    //print("TableView Hieght = \(tableHieght)")
                    self.myTableView?.frame = CGRect(x: 5, y: 210+self.newsTitleHeight+20+25+webHeight!+180+35+115, width: (self.myScrollview?.frame.size.width)!-10, height: tableHieght+30)
                    self.myScrollview?.contentSize = CGSize(width: (self.myScrollview?.frame.size.width)!, height: self.newsTitleHeight+20+25+webHeight!+230+200+115+tableHieght)
                }
            }
        }
        
        //6.Stop Spinner
        self.myScrollview?.isHidden = false
        self.stopSpinner()
        self.CallAdmobBanner()
    }
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat
    {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
    
    
    //============UICollectionView Delegate & Datasource Methods============//
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.RelatedArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! NewsSmallCell
        
        cell.backgroundColor = UIColor.clear
        cell.contentView.layer.cornerRadius = 5.0
        cell.contentView.layer.shadowColor = UIColor.lightGray.cgColor
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.contentView.layer.shadowRadius = 2.0
        cell.contentView.layer.shadowOpacity = 2
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.shadowPath = UIBezierPath(roundedRect: cell.contentView.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        let newsType : String? = (self.RelatedArray.value(forKey: "news_type") as! NSArray).object(at: indexPath.row) as? String
        if (newsType == "video") {
            let videoID : String? = (self.RelatedArray.value(forKey: "video_id") as! NSArray).object(at: indexPath.row) as? String
            strImgPath = String(format: "http://i3.ytimg.com/vi/%@/hqdefault.jpg", videoID!)
            cell.btnPlay?.isHidden = false
        } else {
            strImgPath = (self.RelatedArray.value(forKey: "news_image_b") as! NSArray).object(at: indexPath.row) as? String
            cell.btnPlay?.isHidden = true
        }
        let encodedString = strImgPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encodedString!)
        cell.newsImageView?.sd_setImage(with: url, completed: nil)
        
        cell.lblNewsTitle?.text = (self.RelatedArray.value(forKey: "news_title") as! NSArray).object(at: indexPath.row) as? String
        cell.lblDate?.text = (self.RelatedArray.value(forKey: "news_date") as! NSArray).object(at: indexPath.row) as? String
        cell.lblViews?.text = (self.RelatedArray.value(forKey: "news_views") as! NSArray).object(at: indexPath.row) as? String
        
        cell.btnPlay?.addTarget(self, action:#selector(self.OnPlaySmallVideoClick), for: .touchUpInside)
        cell.btnPlay?.tag = indexPath.row
        
        cell.btnFav?.addTarget(self, action:#selector(self.OnFavSmallNewsClick), for: .touchUpInside)
        cell.btnFav?.tag = indexPath.row
        
        cell.btnShare?.addTarget(self, action:#selector(self.OnShareSmallNewsClick), for: .touchUpInside)
        cell.btnShare?.tag = indexPath.row
        
        DispatchQueue.main.async {
            let htmlDesc = (self.RelatedArray.value(forKey: "news_description") as! NSArray).object(at: indexPath.row) as? String
            let htmlString = String(format: "%@%@", Settings.SetWebViewFont(),htmlDesc!)
            cell.webDesc?.scrollView.isScrollEnabled = false
            cell.webDesc?.loadHTMLString(htmlString, baseURL:nil)
        }
        
        //Check News Favourite or Not
        let modalObj: Modal = Modal()
        modalObj.id = ((self.RelatedArray.value(forKey: "id") as! NSArray).object(at: indexPath.row) as? String)!
        let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
        if (isNewsExist.count == 0) {
            cell.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
        } else {
            cell.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let newsID : String = ((self.RelatedArray.value(forKey: "id") as! NSArray).object(at: indexPath.row) as? String)!
        UserDefaults.standard.set(newsID, forKey: "NEWS_ID")
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
    @objc private func OnPlaySmallVideoClick(_ sender: UIButton?)
    {
        let video_id : String = ((self.RelatedArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
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
    @objc private func OnFavSmallNewsClick(_ sender: UIButton?)
    {
        let modalObj: Modal = Modal()
        modalObj.id = ((self.RelatedArray.value(forKey: "id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cid = ((self.RelatedArray.value(forKey: "cid") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.category_name = ((self.RelatedArray.value(forKey: "category_name") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cat_id = ((self.RelatedArray.value(forKey: "cat_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_type = ((self.RelatedArray.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_title  = ((self.RelatedArray.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_url = ((self.RelatedArray.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_id = ((self.RelatedArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_b = ((self.RelatedArray.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_s = ((self.RelatedArray.value(forKey: "news_image_s") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_description = ((self.RelatedArray.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_date = ((self.RelatedArray.value(forKey: "news_date") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_views = ((self.RelatedArray.value(forKey: "news_views") as! NSArray).object(at: (sender?.tag)!) as? String)!
        
        let indexpath = IndexPath(row: (sender?.tag)!, section: 0)
        let tappedButton = self.myCollectionView!.cellForItem(at: indexpath) as? NewsSmallCell
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
    @objc private func OnShareSmallNewsClick(_ sender: UIButton?)
    {
        let news_title = (self.RelatedArray.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!)
        let news_image_b = (self.RelatedArray.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!)
        let news_description = (self.RelatedArray.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!)
        let news_type : String = (self.RelatedArray.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as! String
        let video_id = (self.RelatedArray.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!)
        let video_url = (self.RelatedArray.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!)
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
    
    //=========UITableView Delegate & Datasource Methods========//
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (self.UserCommentsArray.count == 2) {
            return self.UserCommentsArray.count
        } else {
            //return self.UserCommentsArray.count
            let arraySlice = self.UserCommentsArray.prefix(2)
            let newArray = Array(arraySlice)
            return newArray.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentCell
        
        cell.minHeight = 70.0

        let userNAME = (self.UserCommentsArray.value(forKey: "user_name") as! NSArray).object(at: indexPath.row) as? String
        cell.lblUserName?.text = userNAME
        let userCOMMENT = (self.UserCommentsArray.value(forKey: "comment_text") as! NSArray).object(at: indexPath.row) as? String
        cell.lblUserComment?.text = userCOMMENT

        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableView.automaticDimension
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 0.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("Comment Cell Click = \(indexPath.section)")
    }
    
    //======Share Button Click======//
    @IBAction func OnShareClick(sender:UIButton)
    {
        let news_title : String? = (self.DetailsArray.value(forKey: "news_title") as! NSArray).componentsJoined(by: "")
        let news_image_b : String? = (self.DetailsArray.value(forKey: "news_image_b") as! NSArray).componentsJoined(by: "")
        let news_description : String? = (self.DetailsArray.value(forKey: "news_description") as! NSArray).componentsJoined(by: "")
        let news_type : String? = (self.DetailsArray.value(forKey: "news_type") as! NSArray).componentsJoined(by: "")
        let video_id = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
        let video_url : String? = (self.DetailsArray.value(forKey: "video_url") as! NSArray).componentsJoined(by: "")
        let description = try? NSAttributedString(htmlString:news_description!)
        if (news_type == "video") {
            let youtubeIMAGE = "http://i3.ytimg.com/vi/\(video_id)/hqdefault.jpg"
            encodedString = (youtubeIMAGE as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        } else {
            encodedString = (news_image_b as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        let imgURL = URL(string: encodedString!)
        let data = try? Data(contentsOf: imgURL!)
        let image = UIImage(data: data!)
        let title:NSString = NSString(format: "%@", news_title!)
        let strDesc = description?.string
        let desc:NSString = NSString(format: "%@", strDesc!)
        let videoURL:NSURL = NSURL(string: video_url!)!
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
    
    //======Play Button Click======//
    @IBAction func OnPlayClick(sender:UIButton)
    {
        let video_id : String? = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
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
    
    //======Favourite Button Click======//
    @IBAction func OnFavouriteClick(sender:UIButton)
    {
        let modalObj: Modal = Modal()
        modalObj.id = (self.DetailsArray.value(forKey: "id") as! NSArray).componentsJoined(by: "")
        modalObj.cid = (self.DetailsArray.value(forKey: "cid") as! NSArray).componentsJoined(by: "")
        modalObj.category_name = (self.DetailsArray.value(forKey: "category_name") as! NSArray).componentsJoined(by: "")
        modalObj.cat_id = (self.DetailsArray.value(forKey: "cat_id") as! NSArray).componentsJoined(by: "")
        modalObj.news_type = (self.DetailsArray.value(forKey: "news_type") as! NSArray).componentsJoined(by: "")
        modalObj.news_title  = (self.DetailsArray.value(forKey: "news_title") as! NSArray).componentsJoined(by: "")
        modalObj.video_url = (self.DetailsArray.value(forKey: "video_url") as! NSArray).componentsJoined(by: "")
        modalObj.video_id = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
        modalObj.news_image_b = (self.DetailsArray.value(forKey: "news_image_b") as! NSArray).componentsJoined(by: "")
        modalObj.news_image_s = (self.DetailsArray.value(forKey: "news_image_s") as! NSArray).componentsJoined(by: "")
        modalObj.news_description = (self.DetailsArray.value(forKey: "news_description") as! NSArray).componentsJoined(by: "")
        modalObj.news_date = (self.DetailsArray.value(forKey: "news_date") as! NSArray).componentsJoined(by: "")
        modalObj.news_views = (self.DetailsArray.value(forKey: "news_views") as! NSArray).componentsJoined(by: "")
        
        let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
        if (isNewsExist.count != 0)
        {
            let isDeleted = Singleton.getInstance().DeleteQueryData(modalObj)
            if (isDeleted) {
                self.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
                KSToastView.ks_showToast(CommonMessage.RemoveToFavourite(), duration: 3.0)
                //toast.isShow(CommonMessage.RemoveToFavourite())
            }
        } else {
            let isInserted = Singleton.getInstance().InsertQueryData(modalObj)
            if (isInserted) {
                self.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
                KSToastView.ks_showToast(CommonMessage.AddToFavourite(), duration: 3.0)
                //toast.isShow(CommonMessage.AddToFavourite())
            }
        }
    }
    
    //======Share News Button Click======//
    @IBAction func OnShareNewsClick(sender:UIButton)
    {
        let news_title : String? = (self.DetailsArray.value(forKey: "news_title") as! NSArray).componentsJoined(by: "")
        let news_image_b : String? = (self.DetailsArray.value(forKey: "news_image_b") as! NSArray).componentsJoined(by: "")
        let news_description : String? = (self.DetailsArray.value(forKey: "news_description") as! NSArray).componentsJoined(by: "")
        let news_type : String? = (self.DetailsArray.value(forKey: "news_type") as! NSArray).componentsJoined(by: "")
        let video_id = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
        let video_url : String? = (self.DetailsArray.value(forKey: "video_url") as! NSArray).componentsJoined(by: "")
        let description = try? NSAttributedString(htmlString:news_description!)
        if (news_type == "video") {
            let youtubeIMAGE = "http://i3.ytimg.com/vi/\(video_id)/hqdefault.jpg"
            encodedString = (youtubeIMAGE as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        } else {
            encodedString = (news_image_b as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        let imgURL = URL(string: encodedString!)
        let data = try? Data(contentsOf: imgURL!)
        let image = UIImage(data: data!)
        let title:NSString = NSString(format: "%@", news_title!)
        let strDesc = description?.string
        let desc:NSString = NSString(format: "%@", strDesc!)
        let videoURL:NSURL = NSURL(string: video_url!)!
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
    
    //======All Comments Click======//
    @IBAction func OnAllCommentsClick(sender:UIButton)
    {
        UserDefaults.standard.set(self.UserCommentsArray, forKey: "COMMENTS_ARRAY")
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = AllComments(nibName: "AllComments_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = AllComments(nibName: "AllComments_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = AllComments(nibName: "AllComments", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    
    //======Comments View All Button Click======//
    @IBAction func OnCommentsViewAllClick(sender:UIButton)
    {
        UserDefaults.standard.set(self.UserCommentsArray, forKey: "COMMENTS_ARRAY")
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = AllComments(nibName: "AllComments_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = AllComments(nibName: "AllComments_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = AllComments(nibName: "AllComments", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
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
    
    //======Icon Image Button Click======//
    @IBAction func OnIconImageClick(sender:UIButton)
    {
        let newstype : String? = (self.DetailsArray.value(forKey: "news_type") as! NSArray).componentsJoined(by: "")
        if (newstype == "video") {
            let videoID : String? = (self.DetailsArray.value(forKey: "video_id") as! NSArray).componentsJoined(by: "")
            self.strImgPath = String(format: "http://i3.ytimg.com/vi/%@/hqdefault.jpg", videoID!)
        } else {
            self.strImgPath = (self.DetailsArray.value(forKey: "news_image_b") as! NSArray).componentsJoined(by: "")
        }
        let encodedString = self.strImgPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var myArr = NSMutableArray()
        let str = self.GalleryArray.componentsJoined(by: "")
        if (str != "") {
            myArr = NSMutableArray(array: self.GalleryArray)
        }
        let myDict : NSDictionary = ["image_name" : encodedString as Any]
        myArr.insert(myDict, at: 0)
        let vc = ZoomableImageSlider(images: myArr.value(forKey: "image_name") as! [String], currentIndex: nil, placeHolderImage: nil)
        present(vc, animated: true, completion: nil)
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
        let newsID = (self.DetailsArray.value(forKey: "id") as! NSArray).componentsJoined(by: "")
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
                    self.myScrollview?.isHidden = true
                    self.getSingleNews()
                }
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
        self.lblheadername?.text = CommonMessage.NewsDetails()
        
        //5.Related News
        self.lblRelated?.text = CommonMessage.RelatedNews()
        
        //6.Comments
        self.lblComments?.text = CommonMessage.Comments()
        
        //7.Comments View All
        self.btnViewAllComments?.setTitle(CommonMessage.ViewAll(), for: .normal)
        self.btnViewAllComments?.setTitleColor(UIColor(hexString: Colors.getHeaderColor()), for: .normal)
        
        //8.Comments Image
        self.imgView?.layer.cornerRadius = (self.imgView?.frame.size.width)!/2
        self.imgView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.imgView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.imgView?.layer.shadowRadius = 1.0
        self.imgView?.layer.shadowOpacity = 1
        self.imgView?.layer.masksToBounds = false
        self.imgView?.layer.shadowPath = UIBezierPath(roundedRect: (self.imgView?.bounds)!, cornerRadius: (self.imgView?.layer.cornerRadius)!).cgPath
        self.imgComments?.layer.cornerRadius = (self.imgComments?.frame.size.width)!/2
        self.imgComments?.clipsToBounds = true
        
        //9.Leave a Comments
        self.btnComment?.setTitle(CommonMessage.LeaveAComment(), for: .normal)
        
        //10.Comment View
        self.commentView?.layer.cornerRadius = 5.0
        self.commentView?.clipsToBounds = true
        self.commentView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.commentView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.commentView?.layer.shadowRadius = 1.0
        self.commentView?.layer.shadowOpacity = 1
        self.commentView?.layer.masksToBounds = false
        self.commentView?.layer.shadowPath = UIBezierPath(roundedRect: (self.commentView?.bounds)!, cornerRadius: (self.commentView?.layer.cornerRadius)!).cgPath
        
        //11.Send Comment ImageView
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
                self.myScrollview?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
            } else if (CommonUtils.screenHeight >= 812) {
                self.myScrollview?.frame = CGRect(x: 0, y: 100, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-100)
            } else {
                self.myScrollview?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
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
    
    @IBAction func OnBackClick(sender:UIButton)
    {
        let isNotication = UserDefaults.standard.bool(forKey: "PERTICULAR_NOTIFICATION")
        if (isNotication) {
            let userDefaults = Foundation.UserDefaults.standard
            userDefaults.set(false, forKey:"PERTICULAR_NOTIFICATION")
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                let view = HomeViewController(nibName: "HomeViewController_iPad", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            } else if (CommonUtils.screenHeight >= 812) {
                let view = HomeViewController(nibName: "HomeViewController_iPhoneX", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            } else {
                let view = HomeViewController(nibName: "HomeViewController", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            }
        } else {
            _ = navigationController?.popViewController(animated:true)
        }
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

extension Optional where Wrapped == String
{
    func isEmptyOrWhitespace() -> Bool {
        // Check nil
        guard let this = self else { return true }
        
        // Check empty string
        if this.isEmpty {
            return true
        }
        // Trim and check empty string
        return (this.trimmingCharacters(in: .whitespaces) == "")
    }
}

