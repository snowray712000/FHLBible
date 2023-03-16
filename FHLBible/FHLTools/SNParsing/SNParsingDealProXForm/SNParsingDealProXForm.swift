//
//  ParsingProWformConvertor.swift
//  FHLBible
//
//  Created by littlesnow on 2023/3/17.
//

import Foundation

class SNParsingDealProXForm{
    private var proid: String!
    func main(_ pro:String?,_ wform:String?)-> (String,String) {
        
        self.proid = pro == nil ? "" : pro!.trimmingCharacters(in: .whitespacesAndNewlines)
        let pt2 = wform == nil ? "" : wform!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let proName = getPartOfSpeech(from: proid) ?? "" // "未知詞性"
        if isN() {
            return (proName,DoN().main(wform: pt2))
        } else if isV(){
            return (proName,DoV().main(from: pt2))
        } else if isA(){
            return (proName,DoA().main(wform: pt2))
        } else {
            return (proName,"")
        }
    }
    
    static var TP = [
        "n": "名詞",
        "v": "動詞",
        "a": "形容詞",
        "r": "代名詞",
        "rp": "人稱代名詞",
        "rd": "指示代名詞",
        "ri": "疑問代名詞",
        "ai": "疑問形容詞",
        "rr": "關係代名詞",
        "ru": "不定代名詞",
        "ra": "冠詞",
        "c": "連接詞",
        "x": "連接詞，助語字",
        "i": "感嘆詞",
        "p": "介系詞",
        "t": "質詞",
        "d": "副詞",
        "dr": "關係副詞",
        "drp": "副詞加人稱代名詞",
        "crp": "連接詞加人稱代名詞",
        "rre": "相互代名詞",
        "rf": "反身代名詞"
    ]
    func getPartOfSpeech(from proid: String) -> String? {
        return SNParsingDealProXForm.TP[proid]
    }
    
    private func isN()->Bool{
        return proid == "n" ||
           proid.hasPrefix("r") ||
           proid.hasSuffix("ai") ||
           proid == "drp" ||
           proid == "crp"
    }
    private func isV()->Bool{ return proid == "v" }
    private func isA()->Bool{return proid == "a"}

    class DoN{
        private var pt2:String!
        func main(wform:String)->String{
            self.pt2 = wform
            return [doN0(),doN1(),doN2(),doN3()].filter({!$0.isEmpty}).joined(separator: " ")
        }
        private func doN0()->String{
            let c1 = String(pt2.prefix(1)) // 取得第一個字元
            switch c1 {
                case "n": return "主格"
                case "g": return "所有格"
                case "d": return "間接受格"
                case "a": return "直接受格"
                case "v": return "呼格"
                default : return "\(c1)"
            }
        }
        private func doN1()->String{
            let c2 = String(pt2.dropFirst().prefix(1))
            switch c2 {
            case "s":
                return "單數"
            case "p":
                return "複數"
            case "d":
                return "雙數"
            default:
                return "\(c2)"
            }
        }
        private func doN2()->String{
            let c3 = String(pt2.dropFirst(2).prefix(1))
            switch c3 {
            case "m":
                return "陽性"
            case "f":
                return "陰性"
            case "n":
                return "中性"
            default:
                return "\(c3)"
            }
        }
        private func doN3()->String{
            let c4 = String(pt2.dropFirst(3).prefix(1))
            switch c4 {
            case "1":
                return "第一人稱"
            case "2":
                return "第二人稱"
            case "3":
                return "第三人稱"
            default:
                return "\(c4)"
            }
        }
    }
    
    class DoV{
        func main(from wform:String)->String {
            // assert is verbe
            let re3 = step2_getMoodAndIsParticipleFirstPerson(from: wform)
            if re3.1 { // 分詞
                return [step0_getTense(from: wform),step1_getVoice(from: wform),re3.0,step3a_getCase(from: wform), step4a_getNumberType(from: wform), step5a_getGender(from: wform)].filter({!$0.isEmpty}).joined(separator: " ")
            } else {
                return [step0_getTense(from: wform),step1_getVoice(from: wform),re3.0,step3b_getPersonType(from: wform), step4b_getNumberType(from: wform)].filter({!$0.isEmpty}).joined(separator: " ")
            }
        }
        private func step0_getTense(from pt2: String) -> String {
            let c1 = String(pt2.prefix(1))
            switch c1 {
            case "p":
                return "現在"
            case "i":
                return "不完成"
            case "f":
                return "第一未來"
            case "a":
                return "第一簡單過去"
            case "b":
                return "第二簡單過去"
            case "e":
                return "過去"
            case "x":
                return "第一完成"
            case "c":
                return "第二完成"
            case "y":
                return "過去完成"
            case "d":
                return "完成"
            case "g":
                return "第二未來"
            default:
                return "\(c1)"
            }
        }
        private func step1_getVoice(from pt2: String) -> String {
            let c2 = String(pt2.dropFirst(1).prefix(1))
            switch c2 {
            case "a":
                return "主動"
            case "m":
                return "關身"
            case "p":
                return "被動"
            case "n":
                return "關身形主動意"
            case "o":
                return "被動形主動意"
            case "q":
                return "關身或被動"
            case "r":
                return "關身或被動形主動意"
            default:
                return "\(c2)"
            }
        }
        private func step2_getMoodAndIsParticipleFirstPerson(from pt2: String) -> (String, Bool) {
            var mood = ""
            var isParticipleFirstPerson = false
            let c3 = String(pt2.dropFirst(2).prefix(1))
            switch c3 {
            case "i":
                mood = "直說語氣"
            case "d":
                mood = "命令語氣"
            case "s":
                mood = "假設語氣"
            case "o":
                mood = "期望語氣"
            case "n":
                mood = "不定詞"
            case "p":
                mood = "分詞"
                if pt2.count == 6 {
                    isParticipleFirstPerson = true
                    //mood += "第一人稱"
                }
            default:
                mood = "\(c3)"
            }
            return (mood, isParticipleFirstPerson)
        }
        /// a 系列，若是分詞
        private func step3a_getCase(from pt2: String) -> String {
            let c4 = String(pt2.dropFirst(3).prefix(1))
            switch c4 {
            case "n":
                return "主格"
            case "g":
                return "所有格"
            case "d":
                return "間接受格"
            case "a":
                return "直接受格"
            case "v":
                return "呼格"
            default:
                return "\(c4)"
            }
        }
        private func step4a_getNumberType(from pt2: String) -> String {
            let c5 = String(pt2.dropFirst(4).prefix(1))
            switch c5 {
            case "s":
                return "單數"
            case "p":
                return "複數"
            case "d":
                return "雙數"
            default:
                return "\(c5)"
            }
        }
        private func step5a_getGender(from pt2:String) ->String{
            let c6 = String(pt2.dropFirst(5).prefix(1))
            switch c6 {
            case "m":
                return "陽性"
            case "f":
                return "陰性"
            case "n":
                return "中性"
            default:
                return "\(c6)"
            }
        }
        private func step3b_getPersonType(from pt2: String) -> String {
            let c4 = String(pt2.dropFirst(3).prefix(1))
            switch c4 {
            case "1":
                return "第一人稱"
            case "2":
                return "第二人稱"
            case "3":
                return "第三人稱"
            default:
                return "\(c4)"
            }
        }
        private func step4b_getNumberType(from pt2: String) -> String {
            return step4a_getNumberType(from: pt2)
        }

    }
    class DoA{
        func main(wform:String)->String{
            let re: [String] = [
                step0(wform.prefix(1)),
                step1(wform.dropFirst(1).prefix(1)),
                step2(wform.dropFirst(2).prefix(1)),
                step3(wform.dropFirst(3).prefix(1)),
            ]
            return sinq(re).whereTrue({!$0.isEmpty}).toArray().joined(separator: " ")
            
        }
        private func step0(_ c1:Substring)->String{
            switch c1 {
            case "n": return "主格"
            case "g": return "所有格"
            case "d": return "間接受格"
            case "a": return "直接受格"
            case "v": return "呼格"
            default : return "\(c1)"
            }
        }
        private func step1(_ c2:Substring)->String{
            switch c2 {
            case "s": return "單數"
            case "p": return "複數"
            case "d": return "雙數"
            default:  return "\(c2)"
            }
        }
        private func step2(_ c2:Substring)->String{
            switch c2 {
            case "m": return "陽性"
            case "f": return "陰性"
            case "n": return "中性"
            default:  return "\(c2)"
            }
        }
        private func step3(_ c3:Substring)->String{
            switch c3 {
            case "c": return "比較級"
            case "s": return "最高級"
            default:  return "\(c3)"
            }
        }
    }
}
