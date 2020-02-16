//
//  HomeViewController.swift
//  NewsAppPro
//
//  Created by Apple on 08/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit
import AVKit
import SystemConfiguration
import AdSupport
import PersonalizedAdConsent
import GoogleMobileAds

class HomeViewController: UIViewController,VKSideMenuDelegate,VKSideMenuDataSource,LCBannerViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,GADBannerViewDelegate,GADInterstitialDelegate
{
    var menuLeft: VKSideMenu?
    var LeftMenuArray : NSArray = NSMutableArray()
    var LeftMenuIconArray : NSArray = NSMutableArray()
    
    var spinner: SWActivityIndicatorView!
    private var toast: JYToast!
    @IBOutlet var myScrollview : UIScrollView?
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnleftmenu : UIButton?
    @IBOutlet var btnsearch : UIButton?
    @IBOutlet var pagecontrol : UIPageControl?
    @IBOutlet weak var baseBannerView: LCBannerView!
    @IBOutlet var myView : UIView?
    @IBOutlet var lblCategories : UILabel?
    @IBOutlet var btnCatViewAll : UIButton?
    @IBOutlet var lblTop10News : UILabel?
    @IBOutlet var btnTop10ViewAll : UIButton?
    @IBOutlet var lblLatest : UILabel?
    @IBOutlet var btnLatest : UIButton?
    @IBOutlet var myCollectionView : UICollectionView?
    @IBOutlet var myCollectionView2 : UICollectionView?
    @IBOutlet var myTableView : UITableView?
    
    var HomeArray = NSMutableArray()
    var SliderArray = NSArray()
    var Top10Array = NSArray()
    var CategoryArray = NSArray()
    var LatestArray = NSArray()
    
    @IBOutlet var searchBar : UISearchBar?
    @IBOutlet var btnbacksearch : UIButton?
    
    var encodedString : String?
    var strImgPath : String?
    
    var bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
    var interstitial: GADInterstitial!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
                
        //========PackageName Notification========//
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivePackageNameNotification(_:)), name: NSNotification.Name("PackageNameNotification"), object: nil)
        
        //=======Share BannerView News Notification=======//
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveShareNotification(_:)), name: NSNotification.Name("ShareNotification"), object: nil)
        
        //=======Favourite BannerView News Notification=======//
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveFavouriteNotification(_:)), name: NSNotification.Name("FavouriteNotification"), object: nil)
        
        //=======Register UICollectionView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "CategoryCell_iPad", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "CategoryCell", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        }
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 180, height: 100)
        self.myCollectionView?.collectionViewLayout = flowLayout
        
        //=======Register UICollectionView2 Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "NewsSmallCell_iPad", bundle:nil)
            self.myCollectionView2?.register(nibName, forCellWithReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "NewsSmallCell", bundle:nil)
            self.myCollectionView2?.register(nibName, forCellWithReuseIdentifier: "cell")
        }
        let flowLayout2 = UICollectionViewFlowLayout()
        flowLayout2.scrollDirection = .horizontal
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            flowLayout2.itemSize = CGSize(width: 420, height: 150)
        } else {
            flowLayout2.itemSize = CGSize(width: 320, height: 150)
        }
        self.myCollectionView2?.collectionViewLayout = flowLayout2
        
        //=======Register UITableView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "NewsBigCell_iPad", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "NewsBigCell", bundle:nil)
            self.myTableView?.register(nibName, forCellReuseIdentifier: "cell")
        }
        
        //======Get Home Page Data======//
        self.myScrollview?.isHidden = true
        self.getHomePage()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.btnleftmenu?.isHidden = false
        self.btnbacksearch?.isHidden = true
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.searchBar?.text = ""
        
        //==============VKSlidemenu Initialize==============//
        let isLogin = UserDefaults.standard.bool(forKey: "LOGIN")
        if (isLogin) {
            self.LeftMenuArray = [CommonMessage.Home(), CommonMessage.LatestNews(),CommonMessage.MostViewedNews(), CommonMessage.Categories(), CommonMessage.Favourites(), CommonMessage.Profile(),CommonMessage.ShareApp(), CommonMessage.Settings(), CommonMessage.Logout()]
            self.LeftMenuIconArray = ["home", "latest", "popular","category", "favorite", "profile","share", "setting", "logout"]
        } else {
            self.LeftMenuArray = [CommonMessage.Home(), CommonMessage.LatestNews(),CommonMessage.MostViewedNews(), CommonMessage.Categories(), CommonMessage.Favourites(), CommonMessage.ShareApp(), CommonMessage.Settings(), CommonMessage.Login()]
            self.LeftMenuIconArray = ["home", "latest", "popular", "category", "favorite", "share", "setting", "login"]
        }
        self.menuLeft = VKSideMenu(size: 290, andDirection:.fromLeft)
        self.menuLeft?.dataSource = self
        self.menuLeft?.delegate = self
        self.menuLeft?.addSwipeGestureRecognition(view)
    }
    
    //===========Get Home Page Data==========//
    func getHomePage()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getHomePageData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getHomePageData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_home_news"]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Home API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Home Responce Data : \(responseObject)")
                self.HomeArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as AnyObject?
                
                //1.SliderArray
                self.SliderArray = storeArr?.object(forKey: "featured_news") as! NSArray
                print("SliderArray Count = \(self.SliderArray.count)")
                UserDefaults.standard.set(self.SliderArray, forKey: "SLIDERARRAY")
                
                //2.CategoryArray
                self.CategoryArray = storeArr?.object(forKey: "category_list") as! NSArray
                print("CategoryArray Count = \(self.CategoryArray.count)")
                
                //3.Top10Array
                self.Top10Array = storeArr?.object(forKey: "top_10_news") as! NSArray
                print("Top10Array Count = \(self.Top10Array.count)")
                
                //4.LatestArray
                self.LatestArray = storeArr?.object(forKey: "latest_news") as! NSArray
                print("LatestArray Count = \(self.LatestArray.count)")
                
                //======Open Admob GDPR Popup======//
                let isADMOB = UserDefaults.standard.bool(forKey: "ADMOB")
                if (isADMOB) {
                    self.getAdmobIDs()
                }
                
                DispatchQueue.main.async {
                    self.myCollectionView?.reloadData()
                    self.myCollectionView2?.reloadData()
                    self.myTableView?.reloadData()
                }
                    
                DispatchQueue.main.async {
                    if (self.SliderArray.count == 0) {
                        self.baseBannerView?.isHidden = true
                        self.pagecontrol?.isHidden = true
                    } else {
                        self.baseBannerView?.isHidden = false
                        self.pagecontrol?.numberOfPages = self.SliderArray.count
                        self.pagecontrol?.isHidden = false
                        
                        //=======KIImagePager Initialize======//
                        self.baseBannerView.addSubview(self.AddBannerView(bannerView: self.baseBannerView, newsIDsArray:(self.SliderArray.value(forKey: "id") as! [String]), imageUrlArray: (self.SliderArray.value(forKey: "news_image_b") as! [String]), TitleArray: (self.SliderArray.value(forKey: "news_title") as! [String]), DescArray: (self.SliderArray.value(forKey: "news_description") as! [String]), DatesArray: (self.SliderArray.value(forKey: "news_date") as! [String]), ViewsArray: (self.SliderArray.value(forKey: "news_views") as! [String]), NewsTypes: (self.SliderArray.value(forKey: "news_type") as! [String]), VideoIDs: (self.SliderArray.value(forKey: "video_id") as! [String]), VideoURLs: (self.SliderArray.value(forKey: "video_url") as! [String])))
                    }
                }
                
                DispatchQueue.main.async {
                    if (self.SliderArray.count == 0) {
                        let tableHieght = self.myTableView?.contentSize.height
                        if (UI_USER_INTERFACE_IDIOM() == .pad) {
                            self.myTableView?.frame = CGRect(x: 10, y: 415, width: CommonUtils.screenWidth-20, height: tableHieght!)
                            self.myView?.frame = CGRect(x: 0, y: 10, width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                            self.myScrollview?.contentSize = CGSize(width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                        } else {
                            self.myTableView?.frame = CGRect(x: 10, y: 415, width: CommonUtils.screenWidth-20, height: tableHieght!)
                            self.myView?.frame = CGRect(x: 0, y: 10, width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                            self.myScrollview?.contentSize = CGSize(width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                        }
                    } else {
                        let tableHieght = self.myTableView?.contentSize.height
                        if (UI_USER_INTERFACE_IDIOM() == .pad) {
                            self.myTableView?.frame = CGRect(x: 10, y: 415, width: CommonUtils.screenWidth-20, height: tableHieght!)
                            self.myView?.frame = CGRect(x: 0, y: 490, width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                            self.myScrollview?.contentSize = CGSize(width: CommonUtils.screenWidth, height: 490+415+20+tableHieght!)
                        } else {
                            self.myTableView?.frame = CGRect(x: 10, y: 415, width: CommonUtils.screenWidth-20, height: tableHieght!)
                            self.myView?.frame = CGRect(x: 0, y: 290, width: CommonUtils.screenWidth, height: 415+20+tableHieght!)
                            self.myScrollview?.contentSize = CGSize(width: CommonUtils.screenWidth, height: 290+415+20+tableHieght!)
                        }
                    }
                    self.stopSpinner()
                    self.myScrollview?.isHidden = false
                }
            }
        }, failure: { operation, error in
            self.Networkfailure()
            self.stopSpinner()
        })
    }
    
    
    //============LCBannerView Initialization============//
    func AddBannerView(bannerView: UIView, newsIDsArray: [String], imageUrlArray: [String], TitleArray: [String], DescArray: [String], DatesArray: [String], ViewsArray: [String], NewsTypes: [String], VideoIDs: [String], VideoURLs: [String]) -> LCBannerView
    {
        let banner = LCBannerView.init(frame: CGRect(x: 0, y: 0, width: bannerView.frame.size.width, height: bannerView.frame.size.height), delegate: self, newsIDs: newsIDsArray, imageURLs: imageUrlArray, placeholderImageName: "placeholder", titles: TitleArray, descriptions: DescArray, dates: DatesArray, views: ViewsArray, newsTypes: NewsTypes, videoIDs: VideoIDs, videoURLs: VideoURLs, timeInterval:Settings.SetHomeSliderTime(), currentPageIndicatorTintColor: UIColor.blue, pageIndicatorTintColor: UIColor.white)
        banner?.clipsToBounds = true
        return banner!
    }
    func bannerView(_ bannerView: LCBannerView?, didScrollTo index: Int)
    {
        pagecontrol?.currentPage = index
    }
    func bannerView(_ bannerView: LCBannerView?, didClickedImageIndex index: Int)
    {
        let newsID : String = ((self.SliderArray.value(forKey: "id") as! NSArray).object(at: index) as? String)!
        UserDefaults.standard.set(newsID, forKey: "NEWS_ID")
        self.CallAdmobInterstitial()
    }
    
    //============UICollectionView Delegate & Datasource Methods============//
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if (collectionView == self.myCollectionView) {
            return self.CategoryArray.count
        } else {
            return self.Top10Array.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if (collectionView == self.myCollectionView) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! CategoryCell
            
            cell.backgroundColor = UIColor.clear
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.shadowColor = UIColor.lightGray.cgColor
            cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
            cell.contentView.layer.shadowRadius = 2.0
            cell.contentView.layer.shadowOpacity = 2
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.shadowPath = UIBezierPath(roundedRect: cell.contentView.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            let strimgpath : String? = (self.CategoryArray.value(forKey: "category_image_thumb") as! NSArray).object(at: indexPath.row) as? String
            let encodedString = strimgpath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: encodedString!)
            cell.catImageView?.sd_setImage(with: url, completed: nil)
            
            cell.lblCatName?.text = (self.CategoryArray.value(forKey: "category_name") as! NSArray).object(at: indexPath.row) as? String
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! NewsSmallCell
            
            cell.backgroundColor = UIColor.clear
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.shadowColor = UIColor.lightGray.cgColor
            cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
            cell.contentView.layer.shadowRadius = 2.0
            cell.contentView.layer.shadowOpacity = 2
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.shadowPath = UIBezierPath(roundedRect: cell.contentView.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            let newsType : String? = (self.Top10Array.value(forKey: "news_type") as! NSArray).object(at: indexPath.row) as? String
            if (newsType == "video") {
                let videoID : String? = (self.Top10Array.value(forKey: "video_id") as! NSArray).object(at: indexPath.row) as? String
                strImgPath = String(format: "http://i3.ytimg.com/vi/%@/hqdefault.jpg", videoID!)
                cell.btnPlay?.isHidden = false
            } else {
                strImgPath = (self.Top10Array.value(forKey: "news_image_b") as! NSArray).object(at: indexPath.row) as? String
                cell.btnPlay?.isHidden = true
            }
            let encodedString = strImgPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: encodedString!)
            cell.newsImageView?.sd_setImage(with: url, completed: nil)

            cell.lblNewsTitle?.text = (self.Top10Array.value(forKey: "news_title") as! NSArray).object(at: indexPath.row) as? String
            cell.lblDate?.text = (self.Top10Array.value(forKey: "news_date") as! NSArray).object(at: indexPath.row) as? String
            cell.lblViews?.text = (self.Top10Array.value(forKey: "news_views") as! NSArray).object(at: indexPath.row) as? String
            
            cell.btnPlay?.addTarget(self, action:#selector(self.OnPlaySmallVideoClick), for: .touchUpInside)
            cell.btnPlay?.tag = indexPath.row
            
            cell.btnFav?.addTarget(self, action:#selector(self.OnFavSmallNewsClick), for: .touchUpInside)
            cell.btnFav?.tag = indexPath.row
            
            cell.btnShare?.addTarget(self, action:#selector(self.OnShareSmallNewsClick), for: .touchUpInside)
            cell.btnShare?.tag = indexPath.row
            
            DispatchQueue.main.async {
                let htmlDesc = (self.Top10Array.value(forKey: "news_description") as! NSArray).object(at: indexPath.row) as? String
                let htmlString = String(format: "%@%@", Settings.SetWebViewFont(),htmlDesc!)
                cell.webDesc?.scrollView.isScrollEnabled = false
                cell.webDesc?.loadHTMLString(htmlString, baseURL:nil)
            }
            
            //Check News Favourite or Not
            let modalObj: Modal = Modal()
            modalObj.id = ((self.Top10Array.value(forKey: "id") as! NSArray).object(at: indexPath.row) as? String)!
            let isNewsExist = Singleton.getInstance().SingleQueryData(modalObj)
            if (isNewsExist.count == 0) {
                cell.btnFav?.setBackgroundImage(UIImage(named: "ic_fav")!, for: UIControl.State.normal)
            } else {
                cell.btnFav?.setBackgroundImage(UIImage(named: "ic_favhov")!, for: UIControl.State.normal)
            }
            
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if (collectionView == self.myCollectionView) {
            let catID : String = ((self.CategoryArray.value(forKey: "cid") as! NSArray).object(at: indexPath.row) as? String)!
            UserDefaults.standard.set(catID, forKey: "catID")
            let catNAME : String = ((self.CategoryArray.value(forKey: "category_name") as! NSArray).object(at: indexPath.row) as? String)!
            UserDefaults.standard.set(catNAME, forKey: "catNAME")
            UserDefaults.standard.set(self.CategoryArray, forKey: "CATEGORY_ARRAY")
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                let view = CatList(nibName: "CatList_iPad", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
                } else if (CommonUtils.screenHeight >= 812) {
                let view = CatList(nibName: "CatList_iPhoneX", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
            } else {
                let view = CatList(nibName: "CatList", bundle: nil)
                self.navigationController?.pushViewController(view,animated:true)
            }
        } else {
            let newsID : String = ((self.Top10Array.value(forKey: "id") as! NSArray).object(at: indexPath.row) as? String)!
            UserDefaults.standard.set(newsID, forKey: "NEWS_ID")
            self.CallAdmobInterstitial()
        }
    }
    @objc private func OnPlaySmallVideoClick(_ sender: UIButton?)
    {
        let video_id : String = ((self.Top10Array.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
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
        modalObj.id = ((self.Top10Array.value(forKey: "id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cid = ((self.Top10Array.value(forKey: "cid") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.category_name = ((self.Top10Array.value(forKey: "category_name") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.cat_id = ((self.Top10Array.value(forKey: "cat_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_type = ((self.Top10Array.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_title  = ((self.Top10Array.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_url = ((self.Top10Array.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.video_id = ((self.Top10Array.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_b = ((self.Top10Array.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_image_s = ((self.Top10Array.value(forKey: "news_image_s") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_description = ((self.Top10Array.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_date = ((self.Top10Array.value(forKey: "news_date") as! NSArray).object(at: (sender?.tag)!) as? String)!
        modalObj.news_views = ((self.Top10Array.value(forKey: "news_views") as! NSArray).object(at: (sender?.tag)!) as? String)!
        
        let indexpath = IndexPath(row: (sender?.tag)!, section: 0)
        let tappedButton = self.myCollectionView2!.cellForItem(at: indexpath) as? NewsSmallCell
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
        let news_title = (self.Top10Array.value(forKey: "news_title") as! NSArray).object(at: (sender?.tag)!)
        let news_image_b = (self.Top10Array.value(forKey: "news_image_b") as! NSArray).object(at: (sender?.tag)!)
        let news_description = (self.Top10Array.value(forKey: "news_description") as! NSArray).object(at: (sender?.tag)!)
        let news_type : String = (self.Top10Array.value(forKey: "news_type") as! NSArray).object(at: (sender?.tag)!) as! String
        let video_id = (self.Top10Array.value(forKey: "video_id") as! NSArray).object(at: (sender?.tag)!)
        let video_url = (self.Top10Array.value(forKey: "video_url") as! NSArray).object(at: (sender?.tag)!)
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
    
    //============Show Slide Navigation Left Menu============//
    @IBAction func OnLeftMenuClick(sender:UIButton)
    {
        self.menuLeft?.show()
    }
    func numberOfSections(in sideMenu: VKSideMenu!) -> Int
    {
        return 1
    }
    func sideMenu(_ sideMenu: VKSideMenu!, numberOfRowsInSection section: Int) -> Int
    {
        return LeftMenuArray.count
    }
    func sideMenu(_ sideMenu: VKSideMenu!, itemForRowAt indexPath: IndexPath!) -> VKSideMenuItem!
    {
        let item = VKSideMenuItem()
        let imgname = LeftMenuIconArray[indexPath.row] as? String
        item.icon = UIImage(named: imgname ?? "")
        item.title = (LeftMenuArray[indexPath.row] as! String)
        return item
    }
    func sideMenuDidShow(_ sideMenu: VKSideMenu?)
    {
        var menu = ""
        if sideMenu == menuLeft {
            menu = "LEFT"
        }
        print("\(menu) VKSideMenue did show")
    }
    func sideMenuDidHide(_ sideMenu: VKSideMenu?)
    {
        var menu = ""
        if sideMenu == menuLeft {
            menu = "LEFT"
        }
        print("\(menu) VKSideMenue did hide")
    }
    func sideMenu(_ sideMenu: VKSideMenu?, titleForHeaderInSection section: Int) -> String?
    {
        return nil
    }
    func sideMenu(_ sideMenu: VKSideMenu?, didSelectRowAt indexPath: IndexPath?)
    {
        let isLogin = UserDefaults.standard.bool(forKey: "LOGIN")
        if (isLogin) {
            switch (indexPath?.row)
            {
            case 0:
                print("Home Click")
                break
            case 1:
                self.LatestView()
                break
            case 2:
                self.PopularView()
                break
            case 3:
                self.CategoriesView()
                break
            case 4:
                self.FavouritesView()
                break
            case 5:
                self.ProfileView()
                break
            case 6:
                self.shareApp()
                break
            case 7:
                self.SettingView()
                break
            case 8:
                self.LogoutView()
                break
            default:
                break
            }
        } else {
            switch (indexPath?.row)
            {
            case 0:
                print("Home Click")
                break
            case 1:
                self.LatestView()
                break
            case 2:
                self.PopularView()
                break
            case 3:
                self.CategoriesView()
                break
            case 4:
                self.FavouritesView()
                break
            case 5:
                self.shareApp()
                break
            case 6:
                self.SettingView()
                break
            case 7:
                self.LoginView()
                break
            default:
                break
            }
        }
    }
    
    //========Call Menu ViewController========//
    func LatestView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Latest(nibName: "Latest_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Latest(nibName: "Latest_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Latest(nibName: "Latest", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func PopularView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Popular(nibName: "Popular_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Popular(nibName: "Popular_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Popular(nibName: "Popular", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func CategoriesView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Categories(nibName: "Categories_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Categories(nibName: "Categories_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Categories(nibName: "Categories", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func FavouritesView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Favourites(nibName: "Favourites_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Favourites(nibName: "Favourites_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Favourites(nibName: "Favourites", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func ProfileView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Profile(nibName: "Profile_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Profile(nibName: "Profile_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Profile(nibName: "Profile", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func SettingView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Setting(nibName: "Setting_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Setting(nibName: "Setting_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Setting(nibName: "Setting", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    func LoginView()
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Login(nibName: "Login_iPad", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            let window: UIWindow? = UIApplication.shared.keyWindow
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Login(nibName: "Login_iPhoneX", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            let window: UIWindow? = UIApplication.shared.keyWindow
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        } else {
            let view = Login(nibName: "Login", bundle: nil)
            let nav = UINavigationController(rootViewController: view)
            nav.isNavigationBarHidden = true
            let window: UIWindow? = UIApplication.shared.keyWindow
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        }
    }
    func LogoutView()
    {
        let uiAlert = UIAlertController(title: nil, message: CommonMessage.AreYouSureToLogout(), preferredStyle: UIAlertController.Style.alert)
        self.present(uiAlert, animated: true, completion: nil)
        uiAlert.addAction(UIAlertAction(title: CommonMessage.YES(), style: .default, handler: { action in
            UserDefaults.standard.set(false, forKey: "LOGIN")
            UserDefaults.standard.set(false, forKey: "IS_SKIP")
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                let view = Login(nibName: "Login_iPad", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            } else if (CommonUtils.screenHeight >= 812) {
                let view = Login(nibName: "Login_iPhoneX", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            } else {
                let view = Login(nibName: "Login", bundle: nil)
                let nav = UINavigationController(rootViewController: view)
                nav.isNavigationBarHidden = true
                let window: UIWindow? = UIApplication.shared.keyWindow
                window?.rootViewController = nav
                window?.makeKeyAndVisible()
            }
        }))
        uiAlert.addAction(UIAlertAction(title: CommonMessage.NO(), style: .default, handler: { action in
            print("Click of NO button")
        }))
    }
    
    //============Share App============//
    func shareApp()
    {
        let appName = CommonMessage.NewsApplication() as NSString
        let appLINK: NSString = NSString(format: "https://itunes.apple.com/app/id%@", CommonUtils.getApplicationAppStoreAppleID() as NSString)
        let url = URL(string: appLINK as String)
        let appText = CommonMessage.ShareAppText() as NSString
        let objectsToShare = [appName,appText, url as Any]
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
    
    //=======LCBannerView Slider Click======//
    //1.Favourite Click
    @objc func receiveFavouriteNotification(_ notification: Notification?)
    {
        if ((notification?.name)!.rawValue == "FavouriteNotification") {
            let userInfo = notification?.userInfo
            let index = userInfo?["Data"] as? NSNumber
            
            let modalObj: Modal = Modal()
            modalObj.id = ((self.SliderArray.value(forKey: "id") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.cid = ((self.SliderArray.value(forKey: "cid") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.category_name = ((self.SliderArray.value(forKey: "category_name") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.cat_id = ((self.SliderArray.value(forKey: "cat_id") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_type = ((self.SliderArray.value(forKey: "news_type") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_title  = ((self.SliderArray.value(forKey: "news_title") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.video_url = ((self.SliderArray.value(forKey: "video_url") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.video_id = ((self.SliderArray.value(forKey: "video_id") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_image_b = ((self.SliderArray.value(forKey: "news_image_b") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_image_s = ((self.SliderArray.value(forKey: "news_image_s") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_description = ((self.SliderArray.value(forKey: "news_description") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_date = ((self.SliderArray.value(forKey: "news_date") as! NSArray).object(at: index as! Int) as? String)!
            modalObj.news_views = ((self.SliderArray.value(forKey: "news_views") as! NSArray).object(at: index as! Int) as? String)!
        }
    }
    //2.Share Click
    @objc func receiveShareNotification(_ notification: Notification?)
    {
        if ((notification?.name)!.rawValue == "ShareNotification") {
            let userInfo = notification?.userInfo
            let index = userInfo?["total"] as? NSNumber
            let news_title = (self.SliderArray.value(forKey: "news_title") as! NSArray).object(at: index as! Int)
            let news_image_b = (self.SliderArray.value(forKey: "news_image_b") as! NSArray).object(at: index as! Int)
            let news_description = (self.SliderArray.value(forKey: "news_description") as! NSArray).object(at: index as! Int)
            let news_type : String = (self.SliderArray.value(forKey: "news_type") as! NSArray).object(at: index as! Int) as! String
            let video_id = (self.SliderArray.value(forKey: "video_id") as! NSArray).object(at: index as! Int)
            let video_url = (self.SliderArray.value(forKey: "video_url") as! NSArray).object(at: index as! Int)
            let description = try? NSAttributedString(htmlString:news_description as! String)
            if news_type == "video" {
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
    }
    
    //=======Category View All Click=======//
    @IBAction func OnCatViewAllClick(sender:UIButton)
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Categories(nibName: "Categories_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Categories(nibName: "Categories_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Categories(nibName: "Categories", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    
    //=======Top 10 News View All Click=======//
    @IBAction func OnTop10ViewAllClick(sender:UIButton)
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Top10ViewNews(nibName: "Top10ViewNews_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Top10ViewNews(nibName: "Top10ViewNews_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Top10ViewNews(nibName: "Top10ViewNews", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    
    //=======Latest View All Click=======//
    @IBAction func OnLatestViewAllClick(sender:UIButton)
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let view = Latest(nibName: "Latest_iPad", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else if (CommonUtils.screenHeight >= 812) {
            let view = Latest(nibName: "Latest_iPhoneX", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        } else {
            let view = Latest(nibName: "Latest", bundle: nil)
            self.navigationController?.pushViewController(view,animated:true)
        }
    }
    
    //======Search Button Click======//
    @IBAction func OnSearchClick(sender:UIButton)
    {
        self.searchBar?.becomeFirstResponder()
        self.searchBar?.isHidden = false
        self.btnbacksearch?.isHidden = false
        self.btnleftmenu?.isHidden = true
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        UserDefaults.standard.set(self.searchBar?.text, forKey: "SEARCH_TEXT")
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.btnbacksearch?.isHidden = true
        self.btnleftmenu?.isHidden = false
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
        self.btnleftmenu?.isHidden = false
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
        self.lblheadername?.text = CommonMessage.Home()
        
        //5.Banner View Shadow Color
        self.baseBannerView?.layer.cornerRadius = 5.0
        self.baseBannerView?.clipsToBounds = true
        self.baseBannerView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.baseBannerView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.baseBannerView?.layer.shadowRadius = 1.0
        self.baseBannerView?.layer.shadowOpacity = 1
        self.baseBannerView?.layer.masksToBounds = false
        self.baseBannerView?.layer.shadowPath = UIBezierPath(roundedRect: (self.baseBannerView?.bounds)!, cornerRadius: (self.baseBannerView?.layer.cornerRadius)!).cgPath
        
        //6.Categories Text
        self.lblCategories?.text = CommonMessage.Categories()
        
        //7.Categories View All Button
        self.btnCatViewAll?.setTitle(CommonMessage.ViewAll(), for: .normal)
        self.btnCatViewAll?.setTitleColor(UIColor(hexString: Colors.getHeaderColor()), for: .normal)
        
        //8.Top 10 News Text
        self.lblTop10News?.text = CommonMessage.Top10News()
        
        //9.Top 10 News View All Button
        self.btnTop10ViewAll?.setTitle(CommonMessage.ViewAll(), for: .normal)
        self.btnTop10ViewAll?.setTitleColor(UIColor(hexString: Colors.getHeaderColor()), for: .normal)
        
        //10.Latest Text
        self.lblLatest?.text = CommonMessage.LatestNews()
        
        //11.Latest View All Button
        self.btnLatest?.setTitle(CommonMessage.ViewAll(), for: .normal)
        self.btnLatest?.setTitleColor(UIColor(hexString: Colors.getHeaderColor()), for: .normal)
        
        //12.UITableview Clear Color
        self.myTableView?.backgroundColor = UIColor.clear
        
        //13.UISearchbar Clear Background Color
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
    
    //========Initialization Admob GDPR Policy========//
    func getAdmobIDs()
    {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        let banner_ad_ios = UserDefaults.standard.value(forKey: "banner_ad_ios") as? String
        if (banner_ad_ios == "true")
        {
            let isSelect_GDPR: Bool = UserDefaults.standard.bool(forKey: "GDPR")
            if (isSelect_GDPR) {
                self.setAdmob()
            } else {
                self.checkAdmobGDPR()
            }
        } else {
            if (UI_USER_INTERFACE_IDIOM() == .pad) {
                self.myScrollview?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
            } else if (CommonUtils.screenHeight >= 812) {
                self.myScrollview?.frame = CGRect(x: 0, y: 100, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-137)
            } else {
                self.myScrollview?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
            }
        }
    }
    func checkAdmobGDPR()
    {
        let deviceid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        PACConsentInformation.sharedInstance.debugIdentifiers = [deviceid]
        PACConsentInformation.sharedInstance.debugGeography = .EEA
        
        let publisher_id_ios = UserDefaults.standard.value(forKey: "publisher_id_ios") as? String
        PACConsentInformation.sharedInstance.requestConsentInfoUpdate(forPublisherIdentifiers: [publisher_id_ios!])
        {(_ error: Error?) -> Void in
            if (error != nil) {
                print("Consent info update failed.")
            } else {
                let isSuccess: Bool = PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown
                if (isSuccess) {
                    guard let privacyUrl = URL(string: "https://www.your.com/privacyurl"),
                        let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
                            print("incorrect privacy URL.")
                            return
                    }
                    form.shouldOfferPersonalizedAds = true
                    form.shouldOfferNonPersonalizedAds = true
                    form.shouldOfferAdFree = true
                    form.load {(_ error: Error?) -> Void in
                        if let error = error {
                            print("Error loading form: \(error.localizedDescription)")
                        } else {
                            //Form Load successful.
                            let isSelect_GDPR: Bool = UserDefaults.standard.bool(forKey: "GDPR")
                            if (isSelect_GDPR) {
                                self.setAdmob()
                            } else {
                                form.present(from: self) { (error, userPrefersAdFree) in
                                    if (error != nil) {
                                        print("Error loading form: \(String(describing: error?.localizedDescription))")
                                    } else if userPrefersAdFree {
                                        print("User Select Free Ad from Form")
                                    } else {
                                        let status: PACConsentStatus = PACConsentInformation.sharedInstance.consentStatus;                                     switch(status)
                                        {
                                        case .unknown :
                                            print("PACConsentStatusUnknown")
                                            UserDefaults.standard.set(false, forKey: "GDPR_STATUS")
                                            UserDefaults.standard.set(true, forKey: "GDPR")
                                            self.setAdmob()
                                            break
                                        case .nonPersonalized :
                                            print("PACConsentStatusNonPersonalized")
                                            UserDefaults.standard.set(true, forKey: "GDPR_STATUS")
                                            UserDefaults.standard.set(true, forKey: "GDPR")
                                            let request = DFPRequest()
                                            let extras = GADExtras()
                                            extras.additionalParameters = ["npa": "1"]
                                            request.register(extras)
                                            self.setAdmob()
                                            break
                                        case .personalized :
                                            print("PACConsentStatusPersonalized")
                                            UserDefaults.standard.set(false, forKey: "GDPR_STATUS")
                                            UserDefaults.standard.set(true, forKey: "GDPR")
                                            self.setAdmob()
                                            break
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("Not European Area Country")
                    self.setAdmob()
                }
            }
        }
    }
    
    //================Admob Banner Ads===============//
    func setAdmob()
    {
        //1.Bottom Admob View
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            self.bannerView = GADBannerView(frame: CGRect(x:10, y:CommonUtils.screenHeight-50, width:CommonUtils.screenWidth-20, height:50))
        } else if (CommonUtils.screenHeight >= 812) {
            self.bannerView = GADBannerView(frame: CGRect(x:10, y:CommonUtils.screenHeight-65, width:CommonUtils.screenWidth-20, height:50))
        } else {
            self.bannerView = GADBannerView(frame: CGRect(x:10, y:CommonUtils.screenHeight-50, width:CommonUtils.screenWidth-20, height:50))
        }
        addBannerView(to: bannerView)
        let banner_ad_id_ios = UserDefaults.standard.value(forKey: "banner_ad_id_ios") as? String
        self.bannerView.adUnitID = banner_ad_id_ios
        self.bannerView.rootViewController = self
        self.bannerView.delegate = self
        self.bannerView.load(GADRequest())
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
    
    /*
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}





