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
        
        // 還沒開發，先 mark 起來
        btnPlayrate.isEnabled = false
        btnLoopMode.isEnabled = false
        btnTimerStop.isEnabled = false
        
        ttsCore.setAddr(self.addr)
        ttsCore.setVersions(self.vers)

        self.addrBarItem.title =  ttsCore.addrStr
        if self.ttsCore.isPlayingOfUser == false{
            btnPlay.setImage( UIImage(systemName: "play.fill"), for: .normal)
        } else {
            btnPlay.setImage( UIImage(systemName: "pause.fill"), for: .normal)
        }
        
        ttsCore.addrChanged$.addCallback({[weak self] sender, pData in
            self?.addrBarItem.title =  self?.ttsCore.addrStr
            self?.addr = self?.ttsCore.addr
        }, self.eventKey)
    }
    deinit {
        ttsCore.addrChanged$.clearCallback(self.eventKey)
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
}

