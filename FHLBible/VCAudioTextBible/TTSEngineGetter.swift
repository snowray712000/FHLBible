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
    
    // 按 speed 設定的順序，不要亂改，因為 ui 固定順序了
    static var ttsArray: [AVSpeechSynthesisVoice?] = [
        ManagerLangSet.s.curIsGb ? zhCN : zhTW ,
        enUS,
        hebrew,
        greek,
        jp,
        korean,
        viVN,
        ru
    ]
}

class TTSEngineSamples {
    static var enUS = "In the beginning, God created the heavens and the earth. The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters."
    static var zhTW = "起初，　神創造天地。地是空虛混沌，淵面黑暗；　神的靈運行在水面上。"
    static var zhCN = "起初，　神创造天地。地是空虚混沌，渊面黑暗；　神的灵运行在水面上。"
    static var hebrew = "בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ׃ וְהָאָרֶץ הָיְתָה תֹהוּ וָבֹהוּ וְחֹשֶׁךְ עַל-פְּנֵי תְהוֹם וְרוּחַ אֱלֹהִים מְרַחֶפֶת עַל-פְּנֵי הַמָּיִם׃"
    static var greek = "Ἐν ἀρχῇ ἐποίησεν ὁ θεὸς τὸν οὐρανὸν καὶ τὴν γῆν. ἡ δὲ γῆ ἦν ἀόρατος καὶ ἀκατασκεύαστος, καὶ σκότος ἐπάνω τῆς ἀβύσσου, καὶ πνεῦμα θεοῦ ἐπεφέρετο ἐπάνω τοῦ ὕδατος."
    static var jp = "はじめに神は天と地とを創造された。地は形なく、むなしく、やみが淵のおもてにあり、神の霊が水のおもてをおおっていた。"
    static var ru = "В начале сотворил Бог небо и землю. Земля же была безвидна и пуста, и тьма над бездною, и Дух Божий носился над водою."
    static var viVN = "Ban đầu Đức Chúa Trời dựng nên trời đất. Vả, đất là vô hình và trống không, sự mờ tối ở trên mặt vực; Thần Đức Chúa Trời vận hành trên mặt nước."
    static var korean = "태 초 에 하 나 님 이 천 지 를 창 조 하 시 니 라 ! 땅 이 혼 돈 하 고 공 허 하 며 흑 암 이 깊 음 위 에 있 고 하 나 님 의 신 은 수 면 에 운 행 하 시 니 라"
}
