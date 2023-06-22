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
    
    var addr: VerseRange!
    var vers: [String]!
    
    var dataReader: ReadDataQ!
    // tts: text-to-speech
    var ttsCore: AudioTextBibleTTSCore { get { AudioTextBibleTTSCore.s } }
    var eventKey: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.eventKey = "VCAudioBibleEvents\(ObjectIdentifier(self).hashValue)"
        
        ttsCore.setAddr(self.addr)
        ttsCore.setVersions(self.vers)

        self.addrBarItem.title =  ttsCore.addrStr
        if self.ttsCore.isPlayingOfUser == false{
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        } else {
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        }
        
        self.loopMode = ttsCore.loopMode
        
        ttsCore.addrChanged$.addCallback({[weak self] sender, pData in
            self?.addrBarItem.title =  self?.ttsCore.addrStr
            self?.addr = self?.ttsCore.addr
        }, self.eventKey)
        
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
    deinit {
        ttsCore.addrChanged$.clearCallback(self.eventKey)
        AudioBibleTextStopTimer.s.evTick.clearCallback(self.eventKey)
        AudioBibleTextStopTimer.s.evCompleted.clearCallback(self.eventKey)
    }
    @IBAction func clickPlayOrPause(){
        if self.ttsCore.isPlayingOfUser == false{
            self.ttsCore.play()
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            self.ttsCore.pause()
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    @IBAction func clickNext(){
        ttsCore.goNextForce()
    }
    @IBAction func clickPrev(){
        ttsCore.goPrevForce()
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
}

