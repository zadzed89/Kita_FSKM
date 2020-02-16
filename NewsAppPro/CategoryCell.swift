//
//  CategoryCell.swift
//  NewsAppPro
//
//  Created by Apple on 29/01/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell
{
    @IBOutlet var catImageView : UIImageView?
    @IBOutlet var catOpacityImageView : UIImageView?
    @IBOutlet var lblCatName : UILabel?

    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect)
    {
        //1.Cell Shadow
        self.layer.cornerRadius = 5.0
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width:0, height:0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 2
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: (self.layer.bounds), cornerRadius: (self.layer.cornerRadius)).cgPath
    }
}
