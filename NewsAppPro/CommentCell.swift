//
//  CommentCell.swift
//  NewsAppPro
//
//  Created by Apple on 15/02/19.
//  Copyright © 2019 Viavi Webtech. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell
{
    @IBOutlet var imgView : UIView?
    @IBOutlet var imgIcon : UIImageView?
    @IBOutlet var lblUserName : UILabel?
    @IBOutlet var lblUserComment : UILabel?
    
    var minHeight: CGFloat?
    
    required init?(coder aDecoder: (NSCoder?))
    {
        super.init(coder: aDecoder!)
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func draw(_ rect: CGRect)
    {
        self.imgView?.layer.cornerRadius = (self.imgView?.frame.size.width)!/2
        self.imgView?.layer.shadowColor = UIColor.darkGray.cgColor
        self.imgView?.layer.shadowOffset = CGSize(width:0, height:0)
        self.imgView?.layer.shadowRadius = 1.0
        self.imgView?.layer.shadowOpacity = 1
        self.imgView?.layer.masksToBounds = false
        self.imgView?.layer.shadowPath = UIBezierPath(roundedRect: (self.imgView?.bounds)!, cornerRadius: (self.imgView?.layer.cornerRadius)!).cgPath
        self.imgIcon?.layer.cornerRadius = (self.imgIcon?.frame.size.width)!/2
        self.imgIcon?.clipsToBounds = true
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        guard let minHeight = minHeight else { return size }
        return CGSize(width: size.width, height: max(size.height, minHeight))
    }
}
