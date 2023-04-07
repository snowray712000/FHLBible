//
//  VCAudioBible.swift
//  FHLBible
//
//  Created by littlesnow on 2023/3/22.
//

import Foundation
import AVFoundation
import AVKit
import MediaPlayer 
class VCAudioBible : UIViewController {
    enum LoopMode {
        case Chap // repeat.1
        case Book // repeat
        case All  // goforward
    }
    var loopMode: LoopMode = .All {
        didSet {
            switch loopMode {
            case .Chap:
                btnLoopMode.setImage( UIImage(systemName: "repeat.1"), for: .normal)
            case .Book:
                btnLoopMode.setImage( UIImage(systemName: "repeat"), for: .normal)
            case .All:
                btnLoopMode.setImage( UIImage(systemName: "goforward"), for: .normal)
            }
            
            // prepare init check
            btnNext.isEnabled = false
            btnPrev.isEnabled = false
            
            // init check
            self.findNextPrevAsync(isFindNext: true, isFindPrev: true)
        }
    }
    
    var player: AVPlayer?
    var isPlaying: Bool = false
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnPlayrate: UIButton!
    @IBOutlet var btnLoopMode: UIButton!
    
    var evInitCheck: IjnEventOnceAny!
    @IBOutlet weak var sliderProcess: UISlider!
    var timeObserver: Any?
    var playerItemContext = 0
    var playerItemDidPlayToEndTimeObserver: Any?
    
    
    var selectedSpeed:Float = 1.0 {
        didSet {
            if let player = player, player.rate > 0 {
                player.rate = selectedSpeed
            }
        }
    }
    @IBOutlet weak var labelTimeRemain: UILabel!
    @IBOutlet weak var labelTime1: UILabel!
    var versionIdx = 0 {
        didSet {
            if oldValue != versionIdx {
                DispatchQueue.main.async {
                    self.resetAndDoInitCheckAsync()
                }
            }
        }
    }
    var book = 40
    var chap = 1
    var mp3:String?
    // 依目前版本 versionIdx 與 book 與 chap 決定
    var isValidNow = false
    
    var bookNext = 40
    var chapNext = 1
    var bookPrev = 40
    var chapPrev = 1
    var mp3Next:String? // 算上面的時候，順便算出來的
    var mp3Prev:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupBackgroundPlayer()
        
        // 在滑块上添加一个 target-action，以便在滑块值变化时更新播放进度，不需要釋放，因為 slider 放釋放時就會自動
        sliderProcess.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
             
        self.resetAndDoInitCheckAsync()
    }
    // callby ViewDidLoad and version DidSet
    private func resetAndDoInitCheckAsync(){
        // prepare init check
        if player != nil {
            self.dePlayer()
        }
        setPlayImage(true)
        btnPlay.isEnabled = false
        btnNext.isEnabled = false
        btnPrev.isEnabled = false
        isValidNow = false
        self.mp3 = ""
        
        // init check
        self.evInitCheck = IjnEventOnceAny()
        self.evInitCheck.addCallback { sender, pData in
            if self.isValidNow {
                DispatchQueue.main.async {
                    self.btnPlay.isEnabled = true
                    self.dePlayer()
                    self.initPlayer(self.mp3!)
                }
                self.findNextPrevAsync(isFindNext: true, isFindPrev: true)
            } else {
                DispatchQueue.main.async {
                    self.btnPlay.isEnabled = false
                    
                    self.labelTimeRemain.text = NSLocalizedString("無此章節", comment: "")
                    
                }
            }
        }
        self.initCheckAsync()
    }
    // 當 current 確定後，就可以呼叫此
    private func findNextPrevAsync(isFindNext:Bool,isFindPrev:Bool){
        DispatchQueue.main.async {
            if isFindNext {
                self.btnNext.isEnabled = false
            }
            if isFindPrev {
                self.btnPrev.isEnabled = false
            }
        }
        // init find next and prev
        let finder = AudioBibleNextPrevGetter()
        if isFindNext {
            finder.evNext.addCallback { sender, pData in
                self.mp3Next = finder.mp3Next
                self.bookNext = finder.bookNext
                self.chapNext = finder.chapNext
                DispatchQueue.main.async {
                    self.btnNext.isEnabled = true
                }
            }
        }
        if isFindPrev {
            finder.evPrev.addCallback { sender, pData in
                self.mp3Prev = finder.mp3Prev
                self.bookPrev = finder.bookPrev
                self.chapPrev = finder.chapPrev
                DispatchQueue.main.async {
                    self.btnPrev.isEnabled = true
                }
            }
        }
        finder.mainAsync(book: self.book, chap: self.chap, versionIndex: self.versionIdx, loopMode: self.loopMode,mp3: self.mp3!, isFindNext: isFindNext, isFindPrev: isFindPrev)
    }
    private func initCheckAsync(){
        fhlAu("version=\(versionIdx)&bid=\(book)&chap=\(chap)") { data in
            if let mp3uri = data.mp3 {
                checkIfUrlExists(at: URL(string: mp3uri)!) { isExist in
                    if isExist {
                        self.isValidNow = true
                        self.mp3 = mp3uri
                        self.evInitCheck.triggerAndCleanCallback(self, nil)
                    } else {
                        self.isValidNow = false
                        self.mp3 = ""
                        self.evInitCheck.triggerAndCleanCallback(self, nil)
                    }
                }
            } else {
                self.isValidNow = false
                self.mp3 = ""
                self.evInitCheck.triggerAndCleanCallback(self, nil)
            }
        }
    }
    
    private func resetBeforeCheckValid(){
        self.isValidNow = false
        self.mp3 = ""
        self.bookNext = book
        self.chapNext = chap
        self.mp3Next = ""
        self.bookPrev = book
        self.chapPrev = chap
        self.mp3Prev = ""
        
        btnPlay.isEnabled = false
    }
    private func setPlayImage(_ isPlaying:Bool){
        if isPlaying{
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        } else {
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    
    deinit {
        dePlayer()
    }
    @objc func sliderValueChanged() {
        // 获取滑块的当前值，并将播放进度更改为相应的时间
        let value = sliderProcess.value
        let time = CMTime(seconds: Double(value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    func updateSliderValue() {
        // 更新滑块的值为当前播放时间
        if let player = player {
            let time = player.currentTime()
            
            let value = Float(time.seconds)
            sliderProcess.setValue(value, animated: true)
            self.labelTime1.text = ctime2dashdashformat(time)
            self.labelTimeRemain.text = ctime2dashdashformat(player.currentItem!.duration - time)
        }
    }
    // --:-- or -:--:--
    private func ctime2dashdashformat(_ sec:CMTime)->String{
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
    func whenPlayCompleted(){
        // 因為 completed 的 rate 會變成 0，但原本是在播放中的
        // clickNext 會依 目前播放與否 來決定要播放嗎，所以呼叫 clickNext 前，要變成 playing
        self.player?.rate = Float(self.selectedSpeed)
        self.clickNext()
    }
    @IBAction func clickPlay(){
        guard let player = player else { return  }
        if player.rate > 0 {
            player.pause()
            setPlayImage(true)
        } else {
            setPlayImage(false)
            // 設定 rate 等同於呼叫 play, 但呼叫 play 等於 設定為 1.0
            player.rate = Float(selectedSpeed)
        }
    }
    private func initPlayer (_ urlstring:String){
        let url = URL(string: urlstring)!
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        sliderProcess.value = 0
        // 在播放器上添加一个时间观察器，以便在播放时更新滑块的值
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] time in
            self?.updateSliderValue()
        })
        // 监听 AVPlayerItem 的状态，并在准备好播放时获取视频的总时长
        player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .old], context: &playerItemContext)
        
        // 註冊觀察者，接收播放完成通知
        playerItemDidPlayToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] notification in
            self?.whenPlayCompleted()
        }
        
       
    }
    @IBAction func pickAudioVersion(){
        let vc = VCAudioVersion()
        vc.onPicker$.addCallback { sender, pData in
            if let pData = pData, let index = Int(pData) {
                if self.versionIdx != index {
                    self.versionIdx = index
                }
            }
        }
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        
        present(vc,animated: true,completion: nil)
    }
    @IBAction func pickPlayrate(){
        let vc = VCPlayrate()
        vc.onPicker$.addCallback { sender, pData in
            if let pData = pData, let index = Int(pData) {
                self.selectedSpeed = VCPlayrate.speed[index]
            }
        }
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        
        present(vc,animated: true,completion: nil)
    }
    @IBAction func switchLoopMode(){
        if loopMode == .All {
            loopMode = .Book
        } else if loopMode == .Book {
            loopMode = .Chap
        } else if loopMode == .Chap {
            loopMode = .All
        }
    }
    private func dePlayer (){
        player?.pause()
        
        // 移除时间观察器
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        if playerItemContext != 0 {
            player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext) // 切換版本時，會當掉，可能是還沒新增吧
            playerItemContext = 0;
        }
        
        if let observer = playerItemDidPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
        }

    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playerItemContext {
            if  let change = change,
                let newValue = change[.newKey] as? Int,
                let oldValue = change[.oldKey] as? Int,
                newValue != oldValue,
                let status = AVPlayerItem.Status(rawValue: newValue){
                    switch status {
                    case .readyToPlay:
                        // 获取视频的总时长，并将其设置为滑块的最大值
                        DispatchQueue.main.async {
                            if let duration = self.player?.currentItem?.duration {
                                let totalSeconds = CMTimeGetSeconds(duration)
                                self.sliderProcess.maximumValue = Float(totalSeconds)
                                self.updateSliderValue()
                            }
                        }
                        break
                    case .unknown:
                        break
                    case .failed:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        
    }
    
    @IBAction func clickNext(){
        assert( self.mp3Next != nil )
        let isPlaying = player!.rate > 0 // 原本在播放，更換後，就繼續播放
        player!.rate = 0 // 停下
        
        bookPrev = book
        chapPrev = chap
        mp3Prev = mp3
        
        book = bookNext
        chap = chapNext
        mp3 = mp3Next
        
        self.btnPlay.isEnabled = true
        self.dePlayer()
        self.initPlayer(self.mp3!)
        if isPlaying { player!.rate = Float(self.selectedSpeed) }
        
        self.btnNext.isEnabled = false
        self.findNextPrevAsync(isFindNext: true, isFindPrev: false)
    }
    @IBAction func clickPrev(){
        assert( self.mp3Prev != nil )
        let isPlaying = player!.rate > 0 // 原本在播放，更換後，就繼續播放
        player!.rate = 0 // 停下
        
        bookNext = book
        chapNext = chap
        mp3Next = mp3
        
        book = bookPrev
        chap = chapPrev
        mp3 = mp3Prev
        
        self.btnPlay.isEnabled = true
        self.dePlayer()
        self.initPlayer(self.mp3!)
        if isPlaying { player!.rate = Float(self.selectedSpeed) }
        
        self.btnPrev.isEnabled = false
        self.findNextPrevAsync(isFindNext: false, isFindPrev: true)
    }

    func setupBackgroundPlayer(){
        return ; // 第1個版本，還不要處理後台播放，因為還有許多不穩定 bug
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
       let commandCenter = MPRemoteCommandCenter.shared()
               
       // play command
       commandCenter.playCommand.addTarget { [weak self] event in
           self?.player?.play()
           return .success
       }
       
       // pause command
       commandCenter.pauseCommand.addTarget { [weak self] event in
           self?.player?.pause()
           return .success
       }
       
       // next track command
       commandCenter.nextTrackCommand.addTarget { [weak self] event in
           // play next track here
           return .success
       }
       
       // previous track command
       commandCenter.previousTrackCommand.addTarget { [weak self] event in
           // play previous track here
           return .success
       }
       
       // set the now playing info
       let nowPlayingInfo: [String : Any] = [
           MPMediaItemPropertyTitle: "有聲聖經",
           MPMediaItemPropertyArtist: "",
           MPMediaItemPropertyPlaybackDuration: player?.currentItem?.duration.seconds ?? 0,
           MPNowPlayingInfoPropertyPlaybackRate: player?.rate ?? 0
       ]
       MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
