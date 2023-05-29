//
//  AudioTextBibleTTSCore.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/29.
//

import Foundation
import AVFoundation

// 技術: 必需能發音(基本)。在情境`關閉畫面`下，仍要繼續播放，所以必須要有目前章節，才能搜尋下一個章節，也因此，取得經文過程，也會在這裡面作。
class AudioTextBibleTTSCore : NSObject, AVSpeechSynthesizerDelegate {
    static var s: AudioTextBibleTTSCore = AudioTextBibleTTSCore()
    override init(){
        super.init()
        synthesizer.delegate = self
    }
    var idxRow = 0
    var idxCol = 0
    var data: [[String]]!
    func setData(_ data: [[String]]){
        idxRow = 0
        idxCol = 0
        self.data = data
    }
    
    var ttsOneLang : [AVSpeechSynthesisVoice] = []
    var versions: [String] = []
    var versionsValid: [String] = []
    // set 後，會設定好 utterances 與 version 與 versionValid
    func setVersions(_ vers:[String]){
        self.versions = vers
        let ver_uttes = vers.map({($0,TTSEngineGetter().main($0))}).filter({$0.1 != nil})
        self.versionsValid = ver_uttes.map({$0.0})
        self.ttsOneLang = ver_uttes.map({$0.1!})
    }
    
    // synthesizer.isSpeaking = false 時，可能是在切換中，而非使用者的切換
    var isPlayingOfUser: Bool = false
    
    let synthesizer = AVSpeechSynthesizer()
    func play(){
        playData()
        isPlayingOfUser = true
    }
    func pause(){
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlayingOfUser = false
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isPlayingOfUser == false { return }
        
        goNext_SetRowCol()
        
        if idxRow < data.count {
            self.playData()
        } else {
        }
    }
    private func goNext_SetRowCol(){
        idxCol = idxCol + 1
        if idxCol >= ttsOneLang.count {
            idxCol = 0
            idxRow = idxRow + 1
        }
    }
    private func playData(){
        let r1 = AVSpeechUtterance(string: data[idxRow][idxCol])
        r1.voice = ttsOneLang[idxCol]
        r1.rate = 0.5
        synthesizer.speak(r1)
    }
}
