//
//  IjnTime.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/29.
//

import Foundation
import AVKit
import AVFoundation

// --:-- or -:--:--
// 有聲聖經時用的
// 真正核心
func ctime2dashdashformat(_ sec:CMTime)->String{
    // Format remaining time as "mm:ss" or "h:mm:ss"
    let formatter = DateComponentsFormatter()
    formatter.zeroFormattingBehavior = .pad
    if sec >= CMTimeMake(value: 3600, timescale: 1) {
        formatter.allowedUnits = [.hour, .minute, .second]
    } else {
        formatter.allowedUnits = [.minute, .second]
    }
    
    return formatter.string(from: sec.seconds) ?? "--:--"
}
func ctime2dashdashformat(_ sec:Double)->String{
    return ctime2dashdashformat(convertToCMTime(seconds: sec))
}

fileprivate func convertToCMTime(seconds: Double) -> CMTime {
    let timeScale: Int32 = 1000 // 設定時間的刻度，這裡示範設定為 1000，代表以毫秒為單位
    let timeValue = Int64(seconds * Double(timeScale))
    return CMTimeMake(value: timeValue, timescale: timeScale)
}
