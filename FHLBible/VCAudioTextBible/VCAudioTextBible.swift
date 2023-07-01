//
//  VCAudioTextBible.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/27.
//

import Foundation
import UIKit
import AVFoundation

class VCAudioTextBible : UIViewController {
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnPrev: UIButton!
    @IBOutlet weak var btnPlayrate: UIButton!
    @IBOutlet weak var btnLoopMode: UIButton!
    @IBOutlet weak var labelTimeRemain: UILabel!
    @IBOutlet weak var labelTime1: UILabel!
    @IBOutlet weak var sliderProcess: UISlider!
    @IBOutlet weak var addrBarItem: UIBarItem!
    @IBOutlet weak var btnTimerStop: UIButton!
    @IBOutlet weak var btnInfo: UIButton!
    @IBOutlet weak var btnInfo2: UIButton!
    
    var addr: VerseRange!
    var vers: [String]!
    
    var dataReader: ReadDataQ!
    // tts: text-to-speech
    var ttsCore: AudioTextBibleTTSCore { get { AudioTextBibleTTSCore.s } }
    var eventKey: String!
    var evAppBackForeSwitch = EasyEventAppBackgroundForegroundSwitch()
    override func viewDidLoad() {
        func localizeUI(){
            btnInfo.setTitle(NSLocalizedString("聖經中的希臘文是古希臘文，而文字發音系統(TTS) 是現代希臘文，希伯來文亦同，自行斟酌使用。", comment: "聖經中的希臘文是古希臘文，而文字發音系統(TTS) 是現代希臘文，希伯來文亦同，自行斟酌使用。"), for: .normal)
            btnInfo2.setTitle(NSLocalizedString("當鎖定畫面播放時，進度列時間僅供參考，堪用堪用。", comment: "當鎖定畫面播放時，進度列時間僅供參考，堪用堪用。"), for: .normal)
            title = NSLocalizedString("有聲文字", comment: "有聲文字")
        }
        func addCallbacksForStopTimer(){
            // 倒數時間播放，每秒更新剩餘時間；完成時，播放按鈕要變成「播放」
            AudioBibleTextStopTimer.s.evTick.addCallback({[weak self]sender, pData in
                DispatchQueue.main.async {
                    let str = ctime2dashdashformat(AudioBibleTextStopTimer.s.secondRemain)
                    self?.btnTimerStop.setTitle(str, for: .normal)
                }
            }, eventKey)
            AudioBibleTextStopTimer.s.evCompleted.addCallback({[weak self]sender, pData in
                DispatchQueue.main.async {
                    self?.btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
                    self?.btnTimerStop.setTitle("-- : --", for: .normal)
                }
            }, eventKey)
        }
        super.viewDidLoad()
       
        self.eventKey = "VCAudioBibleEvents\(ObjectIdentifier(self).hashValue)"
        
        ttsCore.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(self.addr)
        ttsCore.setVersions(self.vers)

        self.addrBarItem.title =  ttsCore.addrStr
        self.loopMode = ttsCore.loopMode
        self.updatePlayButtonImageBasedOnPlayingState()
        
        // 核心播放，若已經換章了，身為 ui 要更新一下章節。
        ttsCore.addrChanged$.addCallback({[weak self] sender, pData in
            self?.addrBarItem.title =  self?.ttsCore.addrStr
            self?.addr = self?.ttsCore.addr
        }, self.eventKey)
        
        // 倒數時間播放，每秒更新剩餘時間；完成時，播放按鈕要變成「播放」
        addCallbacksForStopTimer()
        
        // 從主畫面切回來時，要設定一下 play 按鈕。
        evAppBackForeSwitch.evBecomeActive.addCallback { [weak self]sender, pData in
            DispatchQueue.main.async {
                self?.updatePlayButtonImageBasedOnPlayingState()
            }
        }
        
        // 背景聲音，應該只要有一個，所以要有個全域變數，知道目前是 有聲聖經 還是 有聲文字
        DBackgroundMusic.s.tp = .bibleText // 避免中控中心按下播放，是兩個音源
    }
    deinit {
        ttsCore.addrChanged$.clearCallback(self.eventKey)
        AudioBibleTextStopTimer.s.evTick.clearCallback(self.eventKey)
        AudioBibleTextStopTimer.s.evCompleted.clearCallback(self.eventKey)
    }
    @IBAction func clickPlayOrPause(){
        if ttsCore.statePlaying == .stop {
            self.ttsCore.playAndSetPlayingState()
        } else {
            self.ttsCore.pauseAndSetPlayingState()
        }
        
        self.updatePlayButtonImageBasedOnPlayingState()
    }
    @IBAction func clickNext(){
        ttsCore.goNextForce()
        self.updatePlayButtonImageBasedOnPlayingState()
    }
    @IBAction func clickPrev(){
        ttsCore.goPrevForce() 
        self.updatePlayButtonImageBasedOnPlayingState()
    }
    @IBAction func clickSpeed(){
        let vc = self.gVCAudioTextSpeed()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickStopTimer(){
        let vc = VCAudioStopTimer()
        vc.onPicker$.addCallback {[weak self] sender, pData in
            if let pData = pData {
                if pData == "0" { // 取消計時
                    AudioBibleTextStopTimer.s.cancelTimer()
                    AudioBibleTextStopTimer.s.secondRemain = 0.0
                    self?.btnTimerStop.setTitle("-- : --", for: .normal)
                    self?.updatePlayButtonImageBasedOnPlayingState()
                } else {
                    // pData 是 min
                    let min = Double(pData) ?? 30
                    let sec = min * 60.0
                    
                    let str = ctime2dashdashformat(sec)
                    self?.btnTimerStop.setTitle(str, for: .normal)
                    
                    // start timer
                    AudioBibleTextStopTimer.s.stopPrevTimerAndStartNewTimer(sec)
                }
            }
        }
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        
        present(vc,animated: true,completion: nil)
    }
    @IBAction func clickLoopMode(){
        if loopMode == .All {
            loopMode = .Book
        } else if loopMode == .Book {
            loopMode = .Chap
        } else if loopMode == .Chap {
            loopMode = .All
        }
    }
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
            ttsCore.loopMode = loopMode
        }
    }
    private func updatePlayButtonImageBasedOnPlayingState(){
        if self.ttsCore.statePlaying == .stop {
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        } else {
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
}

