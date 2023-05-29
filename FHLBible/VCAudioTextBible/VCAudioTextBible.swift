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
    override func viewDidLoad() {
        super.viewDidLoad()
        // 還沒開發，先 mark 起來
        btnNext.isEnabled = false
        btnPrev.isEnabled = false
        btnPlayrate.isEnabled = false
        btnLoopMode.isEnabled = false
        btnTimerStop.isEnabled = false
        
        let addrStr = VerseRangeToString().main(addr.verses)
        self.addrBarItem.title = addrStr
        
        ttsCore.setVersions(self.vers)
        dataReader = ReadDataQ()
        dataReader.qDataForRead$.addCallback {[weak self] sender, pData in
            if let pData = pData {
                // pData!.0 title row
                // pData.1 data row array
                // assert all version is support TTS
                
                // string [][] , [verse count][version count]
                var dataForReadEachVerse: [[String]] = []
                for a1 in pData.1 {
                    var dataOneVerse: [String] = []
                    for a2 in a1.datas {
                        if a2.count == 0 {
                            dataOneVerse.append("")
                        } else {
                            let r3 = a2.filter({$0.sn == nil}).map({$0.w ?? ""}).joined()
                            dataOneVerse.append(r3)
                        }
                    }
                    dataForReadEachVerse.append(dataOneVerse)
                }
                
                // prepare for read
                self?.ttsCore.setData(dataForReadEachVerse)
            }
        }
        dataReader.qDataForReadAsync(addrStr, ttsCore.versionsValid ) // 此處的聖經版本，已經過濾，都是支援的
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
}

