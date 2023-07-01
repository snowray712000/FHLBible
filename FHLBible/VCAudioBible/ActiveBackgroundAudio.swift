//
//  ActiveBackgroundAudio.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/22.
//

import Foundation
import AVFoundation
import CoreMedia
import AVFoundation
import UIKit
import MediaPlayer

// EasyPlayer 會用到，是有聲聖經，只會呼叫一次即可 (VCAudioBible 用到的)
// VCAudioTextBible 也會用到。
func activeBackgroundAudio(_ isActive:Bool){
    // 只需一次，如果沒設定，其實我們用 AVPlayer 時也會自動設定
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
        try AVAudioSession.sharedInstance().setActive(isActive)
    } catch {
        print(error)
    }
}

func setPlayingCenterInfo(_ title: String,_ artist: String,_ durationInSecond: Double,_ currentTimeInSecond: Double){
    // 获取App图标
    // let appIcon = UIImage(named: "AppIcon")
    // let appIcon = UIImage(named: "AppIcon-iPhone App-60x60@2x")
    let appIcon = UIImage(named: "FHLLOGO")
    let artwork = MPMediaItemArtwork(boundsSize: appIcon?.size ?? CGSize.zero) { size in
        return appIcon ?? UIImage()
    }
    
    let nowPlayingInfo: [String : Any] = [
        MPMediaItemPropertyTitle: title,
        MPMediaItemPropertyArtist: artist,
        MPMediaItemPropertyArtwork: artwork,
        MPMediaItemPropertyPlaybackDuration: durationInSecond,
        MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTimeInSecond,
        MPNowPlayingInfoPropertyPlaybackRate: AVPlayer.s?.rate ?? DAudioBible.s.speed
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}

// 避免中控中心按下播放，是兩個音源
enum TpBackgroundMusic : Int{
    case none = 0
    case bible
    case bibleText
}


// 為了處理: 背景播放，有聲聖經，有聲文字會兩個同時播放
class DBackgroundMusic : NSObject {
    static var s = DBackgroundMusic()
    
    var tp: TpBackgroundMusic = .none {
        didSet {
            if self.tp != oldValue {
                self.evChanged.trigger(self.tp, oldValue)
            }
        }
    }
    // newValue, oldValue
    // assign .tp , maybe trigger this
    var evChanged = IjnEventAdvanced<TpBackgroundMusic,TpBackgroundMusic>()
}
