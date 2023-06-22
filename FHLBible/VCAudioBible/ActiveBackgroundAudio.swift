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
func activeBackgroundAudio(){
    // 只需一次，如果沒設定，其實我們用 AVPlayer 時也會自動設定
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print(error)
    }
    // try? AVAudioSession.sharedInstance().setActive(false)
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
