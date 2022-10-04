//
//  ijnDate.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation
extension Date {
    /// 這個目前有 bug, 2020-11-10 時會對，但 1020-11-10 就會差幾秒，還不知道為何。
    public init(_ year:Int=1,_ month:Int=1,_ day:Int=1,_ hour:Int=0,_ minute:Int=0,_ second:Int=0){
        self = (Calendar.current as NSCalendar).date(era: 1, year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: 0)!
    }
    /// 透過親測過的 ISO8601DateFormatter 來作，效率可能較慢。
    public init(utc:Int = 0, _ year:Int=1,_ month:Int=1,_ day:Int=1,_ hour:Int=0,_ minute:Int=0,_ second:Int=0){
        if utc == 0 {
            // 2020-11-11T11:11:11Z
            let r1 = ISO8601DateFormatter().date(from: "\(year)-\(month)-\(day)T\(hour):\(minute):\(second)Z")
            if r1 != nil { self = r1! }
            else { self.init() }
        } else {
            // 2020-11-11T11:11:11-8 or 2020-11-11T11:11:11+8
            let r1 = ISO8601DateFormatter().date(from: "\(year)-\(month)-\(day)T\(hour):\(minute):\(second)\( utc>0 ? "+":"")\(utc)")
            if r1 != nil { self = r1! }
            else { self.init() }
        }
    }
    /// AD 1/1/1. 仿 C# Datetime 預設建構子
    public static var ijn111 = ISO8601DateFormatter().date(from: "0001-01-01T00:00:00Z")!
    
    /// 2021-04-21T23:12:42Z 或 2021-04-22T07:12:42+08:00 (此稱為 ISO8601)，只有UTC=0時會有Z結尾
    public func ijnToStringUTC(_ utc: Int = 0) -> String {
        let r1 = ISO8601DateFormatter()
        r1.timeZone = TimeZone(secondsFromGMT:  utc * 3600)
        return r1.string(from: self)
    }
}
extension Date {
    // yyyy/MM/dd HH:mm:ss 這是 uiabv.php 的字串型態
    public static func ijnFromStr(_ str: String?) -> Date? {
        guard let str = str else { return nil }
        if str.count == 0 { return nil }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return df.date(from: str)
    }
}
