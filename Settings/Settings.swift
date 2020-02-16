//
//  Settings.swift
//  NewsAppPro
//
//  Created by Apple on 08/12/18.
//  Copyright © 2018 Viavi Webtech. All rights reserved.
//

import UIKit

class Settings: NSObject
{
    class func SetSplashScreenTime() -> Int
    {
        return 2
    }
    
    class func SetHomeSliderTime() -> Int
    {
        return 3
    }
    
    class func SetWebViewFont() -> String
    {
        return "<font face='Poppins-Medium' size='1' align='left' color='#797a7c'>"
    }
    
    class func SetWebViewDetailsPageFont() -> String
    {
        return "<font face='Poppins-Medium' size='2' align='left' color='#797a7c'>"
    }
}
