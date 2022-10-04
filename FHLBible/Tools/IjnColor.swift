import Foundation
import UIKit

extension UIColor {
    public convenience init(r: Int,g: Int,b:Int){
        let c255 = CGFloat(255.0)
        self.init(red: CGFloat(r)/c255, green: CGFloat(g)/c255, blue: CGFloat(b)/c255, alpha: CGFloat(1.0))
    }
    /// 暗洋紅
    public static var darkmagenta = UIColor(r: 139, g: 0, b: 139)
    /// 暗寶石綠
    public static var darkturquoise = UIColor(r: 0, g: 206, b: 209)
    /// 巧克力色
    public static var chocolate = UIColor(r: 123, g: 63, b: 0)
    /// 緋紅色
    public static var crimson = UIColor(r: 220, g: 20, b: 60)
    /// 金菊色
    public static var goldenrod = UIColor(r: 218, g: 165, b: 32)
    /// 暗金菊色
    public static var darkgoldenrod = UIColor(r: 184, g: 134, b: 11)
    /// 暗紅色
    public static var darkred = UIColor(r: 139, g: 0, b: 0)
    /// 耐火磚紅
    public static var firebrick = UIColor(r: 178, g: 34, b: 34)
    /// 粟色、褐紫紅、深紅
    public static var maroon = UIColor(r: 128, g: 0, b: 0)
    public static var brownCss = UIColor(r: 165, g: 42, b: 42)
    /// 法老 摩西 
    
    public static var ijnKeywords = [
        UIColor.brownCss,
        UIColor.chocolate,
        UIColor.crimson,
        UIColor.darkgoldenrod,
        UIColor.darkred,
        UIColor.firebrick,
        UIColor.maroon,
    ]
}
