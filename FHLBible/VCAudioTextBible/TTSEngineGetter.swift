//
//  TTSEngineGetter.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/29.
//

import AVFoundation
// TTS: Text-To-Speech
class TTSEngineGetter {
    func main(_ version:String)->AVSpeechSynthesisVoice? {
        
        // hrbrew and greek
        if version == "lxx" || version == "fhlwh" {
            return Self.greek
        }
        if version == "bhs" {
            return Self.hebrew
        }
        
        // not english foregion
        if version == "jp" {
            return Self.jp
        }
        if version == "korean" {
            return Self.korean
        }
        if version == "russian"{
            return Self.ru
        }
        if version == "vietnamese"{
            return Self.viVN
        }
        
        // english
        let enGroup = sinq(BibleVersionConstants.s.datas).first({$0.na == .en})
        if sinq(enGroup.vers!).select({$0.na}).contains(version){
            return Self.enUS
        }
        
        for a1 in BibleVersionConstants.s.datas {
            // ind 原住民語，還沒有 ... 客家話，還沒有 ... 閩南語，還沒有
            if a1.na == .ind || a1.na == .mi || a1.na == .ha {
                if sinq(a1.vers!).contains(where: {$0.na == version}){
                    return nil
                }
            }
        }
        
        // chinese (其它都用 chinese, 反正頂多唸不出)
        return ManagerLangSet.s.curIsGb ? Self.zhCN : Self.zhTW
        
    }
    static var enUS = AVSpeechSynthesisVoice(language: "en-US")
    static var zhTW = AVSpeechSynthesisVoice(language: "zh-TW")
    static var zhCN = AVSpeechSynthesisVoice(language: "zh-CN")
    static var hebrew = AVSpeechSynthesisVoice(language: "he-IL")
    static var greek = AVSpeechSynthesisVoice(language: "el-GR")
    static var jp = AVSpeechSynthesisVoice(language: "ja-JP")
    static var ru = AVSpeechSynthesisVoice(language: "ru-RU")
    static var viVN = AVSpeechSynthesisVoice(language: "vi-VN")
    static var korean = AVSpeechSynthesisVoice(language: "ko-KR")
}
