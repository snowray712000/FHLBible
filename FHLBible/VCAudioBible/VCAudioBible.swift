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
    var book = 40
    var chap = 1
    
    var loopMode: DAudioBible.LoopMode = .All {
        didSet {
            switch loopMode {
            case .Chap:
                btnLoopMode.setImage( UIImage(systemName: "repeat.1"), for: .normal)
            case .Book:
                btnLoopMode.setImage( UIImage(systemName: "repeat"), for: .normal)
            case .All:
                btnLoopMode.setImage( UIImage(systemName: "goforward"), for: .normal)
            }
            AudioBibleSetter.s.findWhenSetLoopMode(loopMode, DAudioBible.s.loopMode)
            DAudioBible.s.loopMode = loopMode
        }
    }
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnPrev: UIButton!
    @IBOutlet weak var btnPlayrate: UIButton!
    @IBOutlet weak var btnLoopMode: UIButton!
    @IBOutlet weak var btnVersion: UIButton!
    
    @IBOutlet weak var labelTimeRemain: UILabel!
    @IBOutlet weak var labelTime1: UILabel!
    @IBOutlet weak var sliderProcess: UISlider!
    @IBOutlet weak var addrBarItem: UIBarItem!
    @IBOutlet weak var btnTimerStop: UIButton!

   
    var player : EasyAVPlayer { EasyAVPlayer.s }
    var selectedSpeed:Float {
        set {
            if let player = AVPlayer.s, player.rate > 0 {
                if newValue != selectedSpeed {
                    player.rate = newValue
                }
            }
            DAudioBible.s.speed = newValue
        }
        get {
            return DAudioBible.s.speed
        }
    }
    var versionIdx: Int {
        set {
            if newValue != versionIdx {
                DispatchQueue.main.async { [self] in
                    AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book,chap,1), newValue)
                }
                DAudioBible.s.versionIndex = newValue
            }
        }
        get {
            return DAudioBible.s.versionIndex ?? 1
        }
    }
    var events: IVCAudioBibleEvents = VCAudioBibleEvents()
    var eventsOfAppBackForeSwitch = EasyEventAppBackgroundForegroundSwitch()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 版本文字，顯示在 button 上
        self.btnVersion.setTitle(AudioBibleVersions.s.getNameWhereId(versionIdx), for: .normal)
        
        // 目前章節，顯示
        self.updateAddrTitle()
        
        // 目前倒數，更新
        self.updateTimerStopTitle()
        
        self.loopMode = DAudioBible.s.loopMode
        self.add_seek_using_sliderBar()
        eventsOfAppBackForeSwitch.evEnteredBackground.addCallback { [weak self] sender, pData in
            self?.events.releaseEvents()
        }
        eventsOfAppBackForeSwitch.evEnteredForeground.addCallback {  [weak self] sender, pData in
            // 目前章節，更新
            self?.book = DAudioBible.s.addr?.book ?? 40
            self?.chap = DAudioBible.s.addr?.chap ?? 1
            self?.updateAddrTitle()
            
            // 目前倒數，更新
            self?.updateTimerStopTitle()
            
            self?.add_11_callbacks()
        }

        // 第2次進入此 VC
        if AVPlayer.s != nil {
            // 非第1次
            let isTheSameAddr = book == DAudioBible.s.addr!.book && chap == DAudioBible.s.addr!.chap
            if isTheSameAddr {
                let totalSeconds = CMTimeGetSeconds(AVPlayer.s!.currentItem!.duration)
                self.sliderProcess.maximumValue = Float(totalSeconds)
                
                self.btnPrev.isEnabled = true
                self.btnNext.isEnabled = true
                
                self.setPlayImage(DAudioBible.s.isPlaying == false)
                
                self.updateSliderValue()
            } else {
                self.sliderProcess.value = 0
                self.sliderProcess.maximumValue = 1.0
                self.btnPrev.isEnabled = false
                self.btnNext.isEnabled = false
                AVPlayer.s?.rate = 0
                self.setPlayImage(true)
            }
            
            self.add_11_callbacks()
            if isTheSameAddr==false{
                AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book,chap,1), versionIdx)
            }
        } else { // 第1次初始化
            self.add_11_callbacks()
            AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book,chap,1), versionIdx)
        }
    }
    // viewDidLoad
    // clickNext clickPrev (有下面那個就可以了)
    // addCallbackOfCanSetSliderMax，準備好播放下一首了(不論是按下next 或是 prev)
    private func updateAddrTitle(){
        let bookName = BibleBookNames.getBookName(book, ManagerLangSet.s.curTpBookNameLang)
        let title = "\(bookName)-\(chap)"
        self.addrBarItem.title = title
    }
    private func setPlayImage(_ isPlayFill:Bool){
        if isPlayFill{
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        } else {
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    private func add_seek_using_sliderBar(){
        // 在滑块上添加一个 target-action，以便在滑块值变化时更新播放进度，不需要釋放，因為 slider 放釋放時就會自動
        sliderProcess.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    private func add_11_callbacks(){
        // 一開始
        events.addCallbackOfCheckingCurrentOfAddressOfVersion {[weak self] sender, pData in
            DispatchQueue.main.async {
                self?.setPlayImage(true)
                self?.btnPlay.isEnabled = false
                // 下面按了，都會重新搜尋。若正在搜尋，又新的搜尋，執行緒會很亂
                self?.btnVersion.isEnabled = false
                self?.btnLoopMode.isEnabled = false
                self?.btnNext.isEnabled = false
                self?.btnPrev.isEnabled = false
            }
        }
        // 此章節可以 或 不行
        events.addCallbackOfCheckedCurrentOfAddressOfVersion {[weak self] sender, pData in
            DispatchQueue.main.async {
                self?.btnVersion.isEnabled = true
                if DAudioBible.s.mp3 != nil{
                    self?.labelTimeRemain.text = NSLocalizedString("-- : --", comment: "")
                    // self?.btnPlay.isEnabled = true // 取代從 ready status 才可以
                    self?.book = DAudioBible.s.addr!.book
                    self?.chap = DAudioBible.s.addr!.chap
                    self?.player.replacePlayer(DAudioBible.s.mp3!)
                    
                } else {
                    self?.btnPlay.isEnabled = false
                    self?.btnLoopMode.isEnabled = false
                    self?.btnNext.isEnabled = false
                    self?.btnPrev.isEnabled = false
                    self?.labelTimeRemain.text = NSLocalizedString("無此章節", comment: "")
                }
            }
        }
        // 搜尋 next 前。
        events.addCallbackOfSearchingNext {[weak self] sender, pData in
            print("vcaudiobible searching next")
            DispatchQueue.main.async {
                self?.btnNext.isEnabled = false
                self?.btnLoopMode.isEnabled = false
                self?.btnVersion.isEnabled = false
            }
        }
        // 搜尋 next 後。
        events.addCallbackOfSearchedNext {[weak self] sender, pData in
            print("vcaudiobible searched next")
            DispatchQueue.main.async {
                self?.btnNext.isEnabled = true
                self?.btnLoopMode.isEnabled = true
                self?.btnVersion.isEnabled = true
            }
        }
        // 搜尋 prev 前
        events.addCallbackOfSearchingPrev {[weak self] sender, pData in
            DispatchQueue.main.async {
                self?.btnPrev.isEnabled = false
                self?.btnLoopMode.isEnabled = false
                self?.btnVersion.isEnabled = false
            }
        }
        // 搜尋 prev 後
        events.addCallbackOfSearchedPrev {[weak self] sender, pData in
            DispatchQueue.main.async {
                self?.btnPrev.isEnabled = true
                self?.btnLoopMode.isEnabled = true
                self?.btnVersion.isEnabled = true
            }
        }
        // 準備播放後，已經成功取得歌曲資訊
        events.addCallbackOfCanSetSliderMax { [weak self] sender, pData in
            DispatchQueue.main.async {
                if let duration = AVPlayer.s?.currentItem?.duration {
                    self?.book = DAudioBible.s.addr!.book
                    self?.chap = DAudioBible.s.addr!.chap
                    self?.updateAddrTitle()
                    
                    self?.btnPlay.isEnabled = true

                    self?.sliderProcess.value = 0.0
                    let totalSeconds = CMTimeGetSeconds(duration)
                    self?.sliderProcess.maximumValue = Float(totalSeconds)
                    self?.updateSliderValue()

                    if DAudioBible.s.isPlaying && AVPlayer.s!.rate == 0 {
                        self?.clickPlay()
                    }
                }

            }
        }
        // 播放中，每經過 0.5 秒
        events.addCallbackOfTickOfPlaying { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateSliderValue()
            }
        }
        // 倒數功能，倒數中，每經過1秒
        events.addCallbackOfTickStopTimer {  [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateTimerStopTitle()
            }
        }
        // 倒數功能，倒數結束了，經過 30 min 鐘了
        events.addCallbackOfCompletedStopTimer { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateTimerStopTitle()
                self?.setPlayImage(true)
            }
        }
    }
    
    private func updateTimerStopTitle(){
        if DAudioBible.s.secondRemainForStopTimer <= 0.0 {
            self.btnTimerStop.setTitle("-- : --", for: .normal)
        } else {
            let str = ctime2dashdashformat(DAudioBible.s.secondRemainForStopTimer)
            self.btnTimerStop.setTitle(str, for: .normal)
        }
    }
    
    deinit {
        events.releaseEvents()
    }
    @objc func sliderValueChanged() {
        // 获取滑块的当前值，并将播放进度更改为相应的时间
        let value = sliderProcess.value
        let time = CMTime(seconds: Double(value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        AVPlayer.s?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    func updateSliderValue() {
        // 更新滑块的值为当前播放时间
        if let player = AVPlayer.s {
            let time = player.currentTime()
            
            let value = Float(time.seconds)
            sliderProcess.setValue(value, animated: true)
            self.labelTime1.text = ctime2dashdashformat(time)
            self.labelTimeRemain.text = ctime2dashdashformat(player.currentItem!.duration - time)
        }
    }

    @IBAction func pickAudioVersion(){
        let vc = VCAudioVersion()
        vc.onPicker$.addCallback {[weak self] sender, pData in
            if let pData = pData {
                self?.btnVersion.setTitle(pData, for: .normal)
                
                let idx = AudioBibleVersions.s.getIdWhereName(pData)
                if let idx = idx {
                    if self?.versionIdx != idx {
                        self?.versionIdx = idx
                    }
                }
            }
        }
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        
        present(vc,animated: true,completion: nil)
    }
    @IBAction func clickTimerStop(){
        let vc = VCAudioStopTimer()
        vc.onPicker$.addCallback {[weak self] sender, pData in
            if let pData = pData {
                if pData == "0" { // 取消計時
                    AudioBibleStopTimer.s.cancelTimer()
                    
                    DAudioBible.s.secondRemainForStopTimer = 0.0
                    self?.updateTimerStopTitle()
                } else {
                    // pData 是 min
                    let min = Double(pData) ?? 30
                    let sec = min * 60.0
                    
                    let str = ctime2dashdashformat(sec)
                    self?.btnTimerStop.setTitle(str, for: .normal)
                    
                    // start timer
                    AudioBibleStopTimer.s.stopPrevTimerAndStartNewTimer(sec)
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
    @IBAction func clickNext(){
        EasyAVPlayer.s.goNext()
        book = DAudioBible.s.addr!.book
        chap = DAudioBible.s.addr!.chap
    }
    @IBAction func clickPrev(){
        EasyAVPlayer.s.goPrev()
        book = DAudioBible.s.addr!.book
        chap = DAudioBible.s.addr!.chap
    }
    @IBAction func clickPlay(){
        print("clicked Play")
        guard let player = AVPlayer.s else {
            assert ( DAudioBible.s.mp3 != nil )
            EasyAVPlayer.s.replacePlayer(DAudioBible.s.mp3!)
            AVPlayer.s!.rate = selectedSpeed
            setPlayImage(false)
            return
        }
        if player.rate > 0 {
            player.pause()
            setPlayImage(true)
            DAudioBible.s.isPlaying = false
        } else {
            setPlayImage(false)
            // 設定 rate 等同於呼叫 play, 但呼叫 play 等於 設定為 1.0
            player.rate = selectedSpeed
            DAudioBible.s.isPlaying = true
        }
    }
}
