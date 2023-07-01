//
//  AudioTextBibleTTSCore.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/29.
//

import Foundation
import AVFoundation
import CoreMedia
import UIKit
import MediaPlayer

// 技術: 必需能發音(基本)。在情境`關閉畫面`下，仍要繼續播放，所以必須要有目前章節，才能搜尋下一個章節，也因此，取得經文過程，也會在這裡面作。
// 以下是使用self:
// 首先，會先呼叫 setVersions 與 setAddr 一次
// 接著，因為self會切換章節，所以會提到一個 event$，通常事件會綁定
// ui 會用到 addrStr (來設定ui)， statePlaying (來決定按下按鈕時，是play還是pause)， loopMode 決定長相，
// play pause goNextForce goPrevForce 則是要按下的時候
class AudioTextBibleTTSCore : NSObject, AVSpeechSynthesizerDelegate {
    static var s: AudioTextBibleTTSCore = AudioTextBibleTTSCore()

    // 下面 5 個變數，與背景播放，中控中心有關。
    private var evAppBackForeSwitch = EasyEventAppBackgroundForegroundSwitch()
    private var targetPlayCallback: Any?
    private var targetPauseCallback: Any?
    private var targetNextCallback: Any?
    private var targetPreviousCallback: Any?
    
    // 0: 未播放 1: 播放中 2: 播放中，但切換中(沒播放)
    var statePlaying: TpPlayingState = .stop
    
    // TTS 核心。 會用到 .isSpeaking .stopSpeaking .speak
    private var synthesizer = AVSpeechSynthesizer()

    var addr: VerseRange!
    var addrStr: String! // 供 queryData 用，也給外部用
    private var versions: [String] = []
    var addrChanged$: IjnEventAdvancedAny = IjnEventAdvancedAny()
    
    private var idxRow = 0
    private var idxCol = 0
    private var data: [[String]]! = []
    
    private var ttsOneLang : [AVSpeechSynthesisVoice] = []
    private var versionsValid: [String] = []
    
    var loopMode: DAudioBible.LoopMode = .All

    // queryDataAsync 用的，而且每次是一個新實體
    private var dataReader: ReadDataQ!
    
    var stateControlCenter: TpStateControlCenter = .noset
    
    override init(){
        super.init()
        synthesizer.delegate = self
        
        DBackgroundMusic.s.evChanged.addCallback {[weak self] pNew, pOld in
            // 從自己，變成別的
            if pOld == .bibleText && pNew != .bibleText {
                self?.stopBackgroundMusic()
                self?.pauseAndSetPlayingState()
                self?.cleanData()
            }
            // 從別的，變成自己，目前好像不用加什麼
        }// 這個 addCallback 不用加 key, 因為它不可能移除，是 static 的
        
        AudioBibleTextStopTimer.s.evCompleted.addCallback {[weak self] sender, pData in
            self?.pauseAndSetPlayingState()
        }
        
        evAppBackForeSwitch.evResignActive.addCallback {[weak self] sender, pData in
            if self?.stateControlCenter == .noset {
                self?.startBackgroundMusic()
            }
            self?.updateInfoOfControlCenter() // 要放在外面，因為會快速觸發兩次，其中第二次還要設定，不然就播放中的狀態會是錯的(正在播放，卻是還沒正在播放)
        }
        evAppBackForeSwitch.evBecomeActive.addCallback {[weak self] sender, pData in
            self?.stopBackgroundMusic()
        }
    }
    
    private func setDataAndResetRowColumnIndex(_ data: [[String]]){
        idxRow = 0
        idxCol = 0
        self.data = data
    }

    // set 後，會設定好 utterances 與 version 與 versionValid
    func setVersions(_ vers:[String]){
        if vers.count != self.versions.count || sinq(zip(self.versions,vers)).any({$0.0 != $0.1}) {
            assert ( statePlaying == .stop )
            
            self.versions = vers
            
            // filter valid
            let resultValid = self.getValidVersions(vers)
            self.versionsValid = resultValid.0
            self.ttsOneLang = resultValid.1
            
            // version or address change
            self.cleanData()
        }
    }
    private func cleanData(){
        self.setDataAndResetRowColumnIndex([])
    }
    private func getValidVersions(_ vers:[String]) -> ([String],[AVSpeechSynthesisVoice]){
        let ver_uttes = vers.map({($0,TTSEngineGetter().main($0))}).filter({$0.1 != nil})
        let versionsValid = ver_uttes.map({$0.0})
        let ttsOneLang = ver_uttes.map({$0.1!})
        return (versionsValid,ttsOneLang)
    }
    func setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(_ addr:VerseRange){
        if self.addr != addr {
            self.addr = addr
            self.addrStr = VerseRangeToString().main(addr.verses, ManagerLangSet.s.curTpBookNameLang )
            
            self.stopSpeackingIfNeeded()
            
            self.setDataAndResetRowColumnIndex([])// 使重新搜尋，當程式再次呼叫叫 play 時，就會重新搜尋流程
            
            self.addrChanged$.trigger() // 供外部 ui 更新 目前章節
        }
    }
    
    
    func playAndSetPlayingState(){
        if data.isEmpty {
            self.statePlaying = .playingButStopForQueryingData
            
            queryDataAsync()
        } else {
            self.statePlaying = .playing
            
            playData()
        }
    }
    private func stopSpeackingIfNeeded(){
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    func pauseAndSetPlayingState(){
        self.stopSpeackingIfNeeded()
        
        self.statePlaying = .stop
        
    }
    // 它會更新 .addr .addrStr .data清空 ， 在行為上，會暫停播放
    private func goNextPrevCore(_ fnGetNext: ()->VerseRange){
        if loopMode == .All {
            let addr2 = fnGetNext()
            self.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(addr2)
        } else if loopMode == .Book {
            let book = addr.verses[0].book
            let addr2 = fnGetNext()
            let book2 = addr2.verses[0].book
            if (book2 != book ){
                if book2 > book {
                    self.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(VerseRange(DAddress(book,1,1).generateEntireThisChap()))
                } else {
                    self.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(VerseRange(DAddress(book+1,1,1).goPrevChap()))
                }
            } else {
                self.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(addr2)
            }
        } else if loopMode == .Chap {
            self.idxRow = 0
            self.idxCol = 0
        }
    }
    func goNextForce(){
        let stateOld = statePlaying
        
        // 它會更新 .addr .addrStr .data清空 ， 在行為上，會暫停播放
        goNextPrevCore({self.addr.goNext()})
        
        if stateOld != .stop {
            self.playAndSetPlayingState()
        }
    }
    func goPrevForce(){
        let stateOld = statePlaying
        
        goNextPrevCore({self.addr.goPrev()})
        
        if stateOld != .stop {
            self.playAndSetPlayingState()
        }
    }
    // callback function, when tts complete
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // 注意，還沒閱讀完，以指令 synthesizer.stopSpeaking(at: .immediate) 還是會呼叫
        if self.statePlaying != .playing { return } // 就不繼續往下了
        
        goNextSectionOfTTS_SetRowCol()
        
        if idxRow < data.count {
            self.playData()
        } else {
            self.goNextForce()
        }
        
        // 更新 ui, 因為 idxRow idxCol 更新了
        self.updateInfoOfControlCenter()
    }
    private func goNextSectionOfTTS_SetRowCol(){
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
   
    private func queryDataAsync(){
        func gErrorInformationForSpeech()->[[String]]{
            let info = NSLocalizedString("取得資料失敗", comment: "取得資料失敗")
            
            var dataForReadEachVerse: [[String]] = []
            dataForReadEachVerse.append([info])
            dataForReadEachVerse.append([""])
            
            return dataForReadEachVerse
        }
        func cvtData2Speech(_ data: [ReadDataQ.OneRow])->[[String]]{
            // string [][] , [verse count][version count]
            var dataForReadEachVerse: [[String]] = []
            for a1 in data {
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
            return dataForReadEachVerse
        }
        
        assert ( self.statePlaying == .playingButStopForQueryingData )
        
        // 取得資料 Async
        dataReader = ReadDataQ()
        dataReader.qDataForRead$.addCallback {[weak self] sender, pData in
            if let pData = pData {
                self?.setDataAndResetRowColumnIndex(cvtData2Speech(pData.1))
            } else {
                self?.setDataAndResetRowColumnIndex(gErrorInformationForSpeech())
            }
            
            // 上面設定好 Data，可以播放了
            self?.playAndSetPlayingState()
            
            // 取得新章數，節數
            if DBackgroundMusic.s.tp == .bibleText {
                self?.updateInfoOfControlCenter()
            }
        }
        
        dataReader.qDataForReadAsync(addrStr, versionsValid ) // 此處的聖經版本，已經過濾，都是支援的
    }

    
    
    private func updateInfoOfControlCenter(){
        let artist = NSLocalizedString("有聲文字", comment: "有聲文字")
        let total_current = self.getProcessInfo()
        setPlayingCenterInfo(self.addrStr ?? artist, artist, total_current.0, total_current.1)
    }
    private func startBackgroundMusic(){
        if DBackgroundMusic.s.tp != .bibleText { return }
        
        // 使背景播放不會被中斷(甚至沒中控中心，還是會自動切換下一首)
        activeBackgroundAudio(true)
        
        // 中控中心設定
        let commandCenter = MPRemoteCommandCenter.shared()
        // play command
        targetPlayCallback = commandCenter.playCommand.addTarget {[weak self] event in
            if DBackgroundMusic.s.tp != .bibleText { return .success}
            
            self?.playAndSetPlayingState()
            return .success
        }
        // pause command
        targetPauseCallback = commandCenter.pauseCommand.addTarget {[weak self] event in
            if DBackgroundMusic.s.tp != .bibleText { return .success}
            
            self?.pauseAndSetPlayingState()
            return .success
        }
        // next track command
        targetNextCallback = commandCenter.nextTrackCommand.addTarget {[weak self] event in
            if DBackgroundMusic.s.tp != .bibleText { return .success}
            
            self?.goNextForce()
            self?.updateInfoOfControlCenter()
            return .success
        }
        // previous track command
        targetPreviousCallback = commandCenter.previousTrackCommand.addTarget {[weak self] event in
            if DBackgroundMusic.s.tp != .bibleText { return .success}
            
            self?.goPrevForce()
            self?.updateInfoOfControlCenter()
            return .success
        }
                
        self.updateInfoOfControlCenter()
        
        self.stateControlCenter = .set
    }
    private func stopBackgroundMusic(){
        let commandCenter = MPRemoteCommandCenter.shared()
        
        if targetPlayCallback != nil {
            commandCenter.playCommand.removeTarget(targetPlayCallback)
        }
        if targetPauseCallback != nil {
            commandCenter.pauseCommand.removeTarget(targetPauseCallback)
        }
        if targetNextCallback != nil {
            commandCenter.nextTrackCommand.removeTarget(targetNextCallback)
        }
        if targetPreviousCallback != nil {
            commandCenter.previousTrackCommand.removeTarget(targetPreviousCallback)
        }
        
        targetNextCallback = nil
        targetPlayCallback = nil
        targetPauseCallback = nil
        targetPreviousCallback = nil
        
        self.stateControlCenter = .noset
    }
    
    // 進度列用的，自己也會用到，參考用，不會太準確。 (總時間-秒數)，目前秒數)
    // 若是 `取得資料中` 則是7分鐘。
    func getProcessInfo()-> (Double,Double) {
        if data.count == 0 || versionsValid.count == 0 {
            return (7.0*60.0 , 0.0) // 7分鐘
        } else {
            let oneVerseSecond = 10.0
            let cnt = oneVerseSecond * Double( data.count * versionsValid.count )
            let idx = oneVerseSecond * Double( versionsValid.count * idxRow + idxCol )
            return ( cnt , idx )
        }
    }
}

enum TpPlayingState : Int {
    case stop = 0
    case playing
    case playingButStopForQueryingData
}

enum TpStateControlCenter : Int {
    case set = 0
    case noset
}
