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
    var addr: VerseRange!
    var versions: [String] = []
    var addrChanged$: IjnEventAdvancedAny = IjnEventAdvancedAny()
    
    var idxRow = 0
    var idxCol = 0
    var data: [[String]]! = []
    private func setData(_ data: [[String]]){
        idxRow = 0
        idxCol = 0
        self.data = data
    }
    
    var ttsOneLang : [AVSpeechSynthesisVoice] = []
    var versionsValid: [String] = []
    // set 後，會設定好 utterances 與 version 與 versionValid
    func setVersions(_ vers:[String]){
        if vers.count != self.versions.count || sinq(zip(self.versions,vers)).any({$0.0 != $0.1}) {
            self.versions = vers
            let ver_uttes = vers.map({($0,TTSEngineGetter().main($0))}).filter({$0.1 != nil})
            self.versionsValid = ver_uttes.map({$0.0})
            self.ttsOneLang = ver_uttes.map({$0.1!})
            
            self.pause()
            self.data = [] // 使重新搜尋
        }
    }
    var addrStr: String! // 供 queryData 用，也給外部用
    func setAddr(_ addr:VerseRange){
        if self.addr != addr {
            self.addr = addr
            addrStr = VerseRangeToString().main(addr.verses)
            
            self.pause()
            self.data = [] // 使重新搜尋，當程式再次呼叫叫 play 時，就會重新搜尋流程
            
            self.addrChanged$.trigger() // 供外部 ui 更新 目前章節
        }
    }
    
    // synthesizer.isSpeaking = false 時，可能是在切換中，而非使用者的切換
    var isPlayingOfUser: Bool = false
    
    let synthesizer = AVSpeechSynthesizer()
    func play(){
        if data.isEmpty {
            queryDataAsync()
        } else {
            playData()
            isPlayingOfUser = true
        }
    }
    func pause(){
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlayingOfUser = false
    }
    private func goNextPrevCore(_ fnGetNext: ()->VerseRange){
        if loopMode == .All {
            let addr2 = fnGetNext()
            self.setAddr(addr2)
            self.play()
        } else if loopMode == .Book {
            let book = addr.verses[0].book
            let addr2 = fnGetNext()
            let book2 = addr2.verses[0].book
            if (book2 != book ){
                if book2 > book {
                    self.setAddr(VerseRange(DAddress(book,1,1).generateEntireThisChap()))
                } else {
                    self.setAddr(VerseRange(DAddress(book+1,1,1).goPrevChap()))
                }
            } else {
                self.setAddr(addr2)
            }
            self.play()
        } else if loopMode == .Chap {
            self.idxRow = 0
            self.idxCol = 0
            self.play()
        }
    }
    func goNextForce(){
        goNextPrevCore({self.addr.goNext()})
    }
    func goPrevForce(){
        goNextPrevCore({self.addr.goPrev()})
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isPlayingOfUser == false { return }
        
        goNext_SetRowCol()
        
        if idxRow < data.count {
            self.playData()
        } else {
            self.goNextForce()
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
        let voice = ttsOneLang[idxCol]
        r1.voice = voice
        r1.rate = 0.5 * getSpeedWhereTTSEngine(voice)
        synthesizer.speak(r1)
    }
    private func getSpeedWhereTTSEngine(_ tts: AVSpeechSynthesisVoice)->Float{
        let ttss = TTSEngineGetter.ttsArray
        for idx in ijnRange(0, ttss.count){
            if ttss[idx] != nil && ttss[idx] == tts {
                return ManagerAudioTextSpeed.s.curSpeed[idx]
            }
        }
        return 1.0
    }
    var dataReader: ReadDataQ!
    private func queryDataAsync(){
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
                self?.setData(dataForReadEachVerse)
            } else {
                var dataForReadEachVerse: [[String]] = []
                dataForReadEachVerse.append(["取得資料失敗."])
                dataForReadEachVerse.append([""])
                self?.setData(dataForReadEachVerse)
            }
            
            self?.play()
        }
        
        dataReader.qDataForReadAsync(addrStr, versionsValid ) // 此處的聖經版本，已經過濾，都是支援的
    }
    var loopMode: DAudioBible.LoopMode = .All
}
