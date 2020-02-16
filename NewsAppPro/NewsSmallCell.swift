//
//  NewsSmallCell.swift
//  NewsAppPro
//
//  Created by Apple on 29/01/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit

class NewsSmallCell: UICollectionViewCell
{
    @IBOutlet var newsBackView : UIView?
    @IBOutlet var iconBackView : UIView?
    @IBOutlet var newsImageView : UIImageView?
    @IBOutlet var newsOpacityImageView : UIImageView?
    @IBOutlet var lblNewsTitle : UILabel?
    @IBOutlet var btnPlay : UIButton?
    @IBOutlet var btnFav : UIButton?
    @IBOutlet var lblDate : UILabel?
    @IBOutlet var lblViews : UILabel?
    @IBOutlet var btnShare : UIButton?
    @IBOutlet var webDesc : UIWebView?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
    }
    
    override func draw(_ rect: CGRect)
    {
        //1.Back Shadow
        self.newsBackView?.layer.cornerRadius = 5.0
        self.newsBackView?.layer.shadowColor = UIColor.lightGray.cgColor
        self.newsBackView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.newsBackView?.layer.shadowRadius = 2.0
        self.newsBackView?.layer.shadowOpacity = 2
        self.newsBackView?.layer.masksToBounds = false
        self.newsBackView?.layer.shadowPath = UIBezierPath(roundedRect: ((self.newsBackView?.layer.bounds)!), cornerRadius: ((self.newsBackView?.layer.cornerRadius)!)).cgPath

        //2.Icon Back View
        self.iconBackView?.clipsToBounds = false
        self.iconBackView?.layer.shadowColor = UIColor.lightGray.cgColor
        self.iconBackView?.layer.shadowOpacity = 2
        self.iconBackView?.layer.shadowOffset = CGSize.zero
        self.iconBackView?.layer.shadowRadius = 2
        self.iconBackView?.layer.shadowPath = UIBezierPath(roundedRect: ((self.iconBackView?.layer.bounds)!), cornerRadius: ((self.iconBackView?.layer.cornerRadius)!)).cgPath

        //3.Icon ImageView
        self.newsImageView?.layer.cornerRadius = 5
        self.newsImageView?.clipsToBounds = true
        self.newsOpacityImageView?.layer.cornerRadius = 5
        self.newsOpacityImageView?.clipsToBounds = true
    }
}
