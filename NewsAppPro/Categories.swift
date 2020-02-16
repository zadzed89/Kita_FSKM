//
//  Categories.swift
//  NewsAppPro
//
//  Created by Apple on 10/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit
import GoogleMobileAds

class Categories: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UISearchBarDelegate,GADBannerViewDelegate,GADInterstitialDelegate
{
    @IBOutlet var lblstatusbar : UILabel?
    @IBOutlet var lblheader : UILabel?
    @IBOutlet var lblheadername : UILabel?
    @IBOutlet var btnback : UIButton?
    @IBOutlet var btnsearch : UIButton?
    @IBOutlet var lblnodatafound : UILabel?
    @IBOutlet var myCollectionView : UICollectionView?
    @IBOutlet var searchBar : UISearchBar?
    @IBOutlet var btnbacksearch : UIButton?
    var searchResult = NSMutableArray()
    var isFiltered = false
    var spinner: SWActivityIndicatorView!
    var CategoryArray = NSMutableArray()
    var CatArray = NSMutableArray()

    var bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
    var interstitial: GADInterstitial!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //=======Register UICollectionView Cell Nib=======//
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            let nibName = UINib(nibName: "CategoryCell_iPad", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        } else {
            let nibName = UINib(nibName: "CategoryCell", bundle:nil)
            self.myCollectionView?.register(nibName, forCellWithReuseIdentifier: "cell")
        }
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        //flowLayout.scrollDirection = .vertical
        //flowLayout.itemSize = CGSize(width: 180, height: 100)
        self.myCollectionView?.collectionViewLayout = flowLayout
        
        //======Get All Categories Data======//
        self.myCollectionView?.isHidden = true
        self.getCategories()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.isFiltered = false
        self.btnbacksearch?.isHidden = true
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.searchBar?.text = ""
        self.myCollectionView?.reloadData()
    }
    
    //===========Get All Categories Data==========//
    func getCategories()
    {
        if (Reachability.shared.isConnectedToNetwork()) {
            self.startSpinner()
            let str = String(format: "%@api.php",CommonUtils.getBaseUrl())
            let encodedString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.getAllCategoriesData(encodedString)
        } else {
            self.InternetConnectionNotAvailable()
        }
    }
    func getAllCategoriesData(_ requesturl: String?)
    {
        let salt:String = CommonUtils.getSalt() as String
        let sign = CommonUtils.getSign(salt)
        let dict = ["salt":salt, "sign":sign, "method_name":"get_category"]
        let data = CommonUtils.getBase64EncodedString(dict as [AnyHashable : Any])
        let strDict = ["data": data]
        print("Categories API URL : \(strDict)")
        let manager = AFHTTPSessionManager()
        manager.post(requesturl!, parameters: strDict, progress: nil, success:
        { task, responseObject in if let responseObject = responseObject
            {
                print("Categories Responce Data : \(responseObject)")
                self.CategoryArray.removeAllObjects()
                let response = responseObject as AnyObject?
                let storeArr = response?.object(forKey: "NEWS_APP") as! NSArray
                for i in 0..<storeArr.count {
                    let storeDict = storeArr[i] as? [AnyHashable : Any]
                    if (storeDict != nil) {
                        self.CategoryArray.add(storeDict as Any)
                    }
                    
                    let modal = Modal()
                    let tempDict = storeArr[i] as? [AnyHashable : Any]
                    modal.cid = tempDict?["cid"] as? String
                    modal.category_name = tempDict?["category_name"] as? String
                    modal.category_image = tempDict?["category_image"] as? String
                    modal.category_image_thumb = tempDict?["category_image_thumb"] as? String
                    self.CatArray.add(modal)
                }
                print("CategoryArray Count = \(self.CategoryArray.count)")
                
                DispatchQueue.main.async {
                    if (self.CategoryArray.count == 0) {
                        self.myCollectionView?.isHidden = true
                        self.lblnodatafound?.isHidden = false
                    } else {
                        self.myCollectionView?.isHidden = false
                        self.lblnodatafound?.isHidden = true
                        self.myCollectionView?.reloadData()
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
    
    //============UICollectionView Delegate & Datasource Methods============//
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var rowCount: Int = 0
        if (isFiltered) {
            rowCount = self.searchResult.count
        } else {
            rowCount = self.CatArray.count
        }
        return rowCount
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! CategoryCell
        
        cell.backgroundColor = UIColor.clear
        cell.contentView.layer.cornerRadius = 5.0
        cell.contentView.layer.shadowColor = UIColor.lightGray.cgColor
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.contentView.layer.shadowRadius = 2.0
        cell.contentView.layer.shadowOpacity = 2
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.shadowPath = UIBezierPath(roundedRect: cell.contentView.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        if (isFiltered) {
            var modal = Modal()
            modal = self.searchResult.object(at: indexPath.row) as! Modal
            let encodedString = modal.category_image_thumb!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: encodedString!)
            cell.catImageView?.sd_setImage(with: url, completed: nil)
            cell.lblCatName?.text = modal.category_name
        } else {
            var modal = Modal()
            modal = self.CatArray.object(at: indexPath.row) as! Modal
            let encodedString = modal.category_image_thumb!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: encodedString!)
            cell.catImageView?.sd_setImage(with: url, completed: nil)
            cell.lblCatName?.text = modal.category_name
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            return CGSize(width: (CommonUtils.screenWidth-40)/3, height: ((CommonUtils.screenWidth-40)/3)/2)
        } else if (CommonUtils.screenHeight >= 812) {
            return CGSize(width: (CommonUtils.screenWidth-40)/3, height: ((CommonUtils.screenWidth-40)/3)/2)
        } else {
            return CGSize(width: (CommonUtils.screenWidth-30)/2, height: ((CommonUtils.screenWidth-30)/2)/2)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if (isFiltered) {
            var modal = Modal()
            modal = self.searchResult.object(at: indexPath.row) as! Modal
            let catID : String = modal.cid!
            UserDefaults.standard.set(catID, forKey: "catID")
            let catNAME : String = modal.category_name!
            UserDefaults.standard.set(catNAME, forKey: "catNAME")
        } else {
            var modal = Modal()
            modal = self.CatArray.object(at: indexPath.row) as! Modal
            let catID : String = modal.cid!
            UserDefaults.standard.set(catID, forKey: "catID")
            let catNAME : String = modal.category_name!
            UserDefaults.standard.set(catNAME, forKey: "catNAME")
        }
        
        UserDefaults.standard.set(self.CategoryArray, forKey: "CATEGORY_ARRAY")
        self.searchBar?.resignFirstResponder()

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
    }
    
    //======UISearchBar Delegate Methods Click======//
    @IBAction func OnSearchClick(sender:UIButton)
    {
        self.searchBar?.becomeFirstResponder()
        self.searchBar?.isHidden = false
        self.btnbacksearch?.isHidden = false
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if (searchText.count == 0) {
            self.isFiltered = false
        } else {
            self.isFiltered = true
            self.searchResult.removeAllObjects()
            
            for element in self.CatArray {
                var modal = Modal()
                modal = element as! Modal
                let catName : String = modal.category_name!
                let nsRange = NSString(string: catName).range(of: searchText, options: String.CompareOptions.caseInsensitive)
                let descriptionRange = NSString(string: catName.description).range(of: searchText, options: String.CompareOptions.caseInsensitive)
                if (nsRange.location != NSNotFound || descriptionRange.location != NSNotFound)
                {
                    self.searchResult.add(modal)
                }
            }
        }
        self.myCollectionView?.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        print("SearchBar Button Click")
    }
    @IBAction func OnBackSearchClick(sender:UIButton)
    {
        self.isFiltered = false
        self.myCollectionView?.reloadData()
        self.searchBar?.resignFirstResponder()
        self.searchBar?.isHidden = true
        self.btnbacksearch?.isHidden = true
        self.searchBar?.text = ""
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
        self.lblheadername?.text = CommonMessage.Categories()
        
        //5.No Data Found
        self.lblnodatafound?.text = CommonMessage.NoCategoryFound()
        
        //6.UISearchbar Clear Background Color
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
                self.myCollectionView?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
            } else if (CommonUtils.screenHeight >= 812) {
                self.myCollectionView?.frame = CGRect(x: 0, y: 100, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-100)
            } else {
                self.myCollectionView?.frame = CGRect(x: 0, y: 75, width: CommonUtils.screenWidth, height: CommonUtils.screenHeight-75)
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
