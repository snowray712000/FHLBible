
import Foundation
import CoreMedia
import AVFoundation
import UIKit
import MediaPlayer


extension AVPlayer {
    static var s: AVPlayer?
}
class EasyAVPlayer {
    typealias EventThisClass = IjnEventAdvanced<EasyAVPlayer,Any>
    private var timeObserver: Any? // player 的 timeObserver
    private var itemHelper: EasyPlayerItem?
    static var s = EasyAVPlayer()
    
    var evForUpdateSliderValueAtMainQueue:EventThisClass = EventThisClass()
    // 可設定 slider value 的最大值，取得 duration
    var evBeenReadyStatus:EventThisClass = EventThisClass()
    // 切換下首歌，self就處理了，若要addCallback，只要專心處理 ui 即可
    var evOneFileCompleted: EventThisClass = EventThisClass()
    var evAppBackForeSwitch = EasyEventAppBackgroundForegroundSwitch()
    
    init(){
        setupCallbacks()
        
        setupAudioSession()
    }
    private func setupCallbacks(){
        evAppBackForeSwitch.evEnteredBackground.addCallback {[weak self] sender, pData in
            print("easypleyer enter background")
            self?.startBackgroundMusic()
        }
        evAppBackForeSwitch.evEnteredForeground.addCallback {[weak self] sender, pData in
            print("easypleyer enter forebackground")
            self?.stopBackgroundMusic()
        }
        self.evOneFileCompleted.addCallback {[weak self] sender, pData in
            print("easypleyer one file completed")
            self?.goNext()
            self?.setupAudioSession()
        }
        self.evBeenReadyStatus.addCallback({[weak self] sender, pData in
            // 更新进度信息
            assert( AVPlayer.s != nil && AVPlayer.s!.currentItem != nil )
            self?.updateInfoOfControlCenter()
//            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
//            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
//
//            let curInSeconds = AVPlayer.s!.currentTime().seconds
//            let duration = AVPlayer.s!.currentItem!.duration
//            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = curInSeconds
//            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration.seconds
//            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        })
        // 若 loop 是 chap, 不要真的播放完成，而是將時間拉回0秒，較省流量
        self.evForUpdateSliderValueAtMainQueue.addCallback({sender, pData in
            if DAudioBible.s.loopMode != .Chap { return }
            
            if let player = AVPlayer.s {
                let dt = player.currentItem!.duration - player.currentTime()
                if dt.seconds < 1.0 {
                    let time = CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    AVPlayer.s?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                }
            }
        }, "EasyAVPlayer")
    }
    // replace 比起 initial 動詞更準確，因為若原本存在，會安全釋放
    // replace 了，但 events 不需要重綁定唷
    func replacePlayer(_ mp3url: String){
        if AVPlayer.s != nil {
            assert( timeObserver != nil )
            pauseAndRelease()
        }
        
        if mp3url.isEmpty { return }
        
        guard let url = URL(string:mp3url) else { return }
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        AVPlayer.s = player
        
        // 綁定 item 相關事件.
        itemHelper = EasyPlayerItem(playerItem)
        itemHelper!.evReadyStatus.addCallback { [weak self] sender, pData in
            self?.evBeenReadyStatus.trigger(self, nil)
        }
        itemHelper!.evPlayCompleted.addCallback { [weak self] sender, pData in
            self?.evOneFileCompleted.trigger(self, nil)
        }
        itemHelper!.mainAsyncWhenYouBindEventAlready()
        
        // 綁定 player 相關事件. (對使用者來說，沒分 player 與 item)
        timeObserver = addTimeObserver(player)
        
    }
    private func pauseAndRelease() {
        guard let player = AVPlayer.s else { return }
        assert ( self.itemHelper != nil )
        assert ( self.timeObserver != nil )
        
        player.rate = 0.0 // 停播放
        self.itemHelper!.do_deinit()
        self.itemHelper = nil
        
        self.removeTimeObserver(player, self.timeObserver!)
        self.timeObserver = nil
        
        AVPlayer.s = nil
    }
    private func addTimeObserver(_ player:AVPlayer)->Any{
        // 在播放器上添加一个时间观察器，以便在播放时更新滑块的值
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] time in
            self?.evForUpdateSliderValueAtMainQueue.trigger(self, nil)
        })
        return timeObserver
    }
    private func removeTimeObserver(_ player:AVPlayer,_ timeOb: Any?){
        // 移除时间观察器
        if let observer = timeOb {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func stopBackgroundMusic(){
        print("stop background music func call")
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.removeTarget(targetPlayCallback)
        commandCenter.pauseCommand.removeTarget(targetPauseCallback)
        commandCenter.nextTrackCommand.removeTarget(targetNextCallback)
        commandCenter.previousTrackCommand.removeTarget(targetPreviousCallback)
        targetNextCallback = nil
        targetPlayCallback = nil
        targetPauseCallback = nil
        targetPreviousCallback = nil
    }
    private func setupAudioSession(){
        activeBackgroundAudio()
    }
    private var targetPlayCallback: Any?
    private var targetPauseCallback: Any?
    private var targetNextCallback: Any?
    private var targetPreviousCallback: Any?
    
    private func startBackgroundMusic(){
        print("start background music func call")
        let commandCenter = MPRemoteCommandCenter.shared()
        // play command
        
        targetPlayCallback = commandCenter.playCommand.addTarget {event in
           print("easypleyer play command clicked")
           if let s = AVPlayer.s {
               s.rate = DAudioBible.s.speed // play will set 1 seepd.
           }
           return .success
        }
       // pause command
        targetPauseCallback = commandCenter.pauseCommand.addTarget {event in
           print("easypleyer pause command clicked")
           AVPlayer.s?.pause()
           return .success
       }
       // next track command
        targetNextCallback = commandCenter.nextTrackCommand.addTarget {[weak self] event in
           print("easypleyer next command clicked")
           // play next track here
           self?.goNext()
           self?.updateInfoOfControlCenter()
           return .success
       }
       // previous track command
        targetPreviousCallback = commandCenter.previousTrackCommand.addTarget {[weak self] event in
           print("easypleyer previous command clicked")
           // play previous track here
           self?.goPrev()
           self?.updateInfoOfControlCenter()
           return .success
       }
       updateInfoOfControlCenter()

    }
    
    func updateInfoOfControlCenter(){
        // set the now playing info
        let bookName = BibleBookNames.getBookName(DAudioBible.s.addr!.book, ManagerLangSet.s.curTpBookNameLang)
        let title = "\(bookName)-\(DAudioBible.s.addr!.chap)"
        
        let artist = AudioBibleVersions.s.getNameWhereId(DAudioBible.s.versionIndex!) ?? ""

        let currentTimeInSecond = AVPlayer.s?.currentTime().seconds ?? 0.0;
        let durationInSecond = AVPlayer.s?.currentItem?.duration.seconds ?? 10.0;
        
        setPlayingCenterInfo(title, artist, durationInSecond, currentTimeInSecond )
    }
    func goNext(){
        // 在 VC 可以用 isEnable 來確保，但在這個 class 不能有這樣的假設，所以要作一個保護
        if DAudioBible.s.mp3Next == nil { return }
        
        assert ( DAudioBible.s.mp3Next != nil )
        guard let player = AVPlayer.s else { return }
        
        player.rate = 0 // 停下
        
        AudioBibleSetter.s.setNextToCurrAndFindNext()
        self.replacePlayer(DAudioBible.s.mp3!)
        
        // 原本在播放，更換後，就繼續播放
        if DAudioBible.s.isPlaying { AVPlayer.s!.rate = DAudioBible.s.speed }
    }
    func goPrev(){
        if DAudioBible.s.mp3Prev == nil { return }
        
        assert ( DAudioBible.s.mp3Prev != nil )
        guard let player = AVPlayer.s else { return }
        
        player.rate = 0 // 停下
        
        AudioBibleSetter.s.setPrevToCurrAndFindPrev()
        self.replacePlayer(DAudioBible.s.mp3!)
        
        // 原本在播放，更換後，就繼續播放
        if DAudioBible.s.isPlaying { AVPlayer.s!.rate = DAudioBible.s.speed }
    }
}
