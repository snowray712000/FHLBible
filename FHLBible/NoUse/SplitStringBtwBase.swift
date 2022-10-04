//
//  SplitStringBtwBase.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/8.
//

import Foundation

/// 這是重構 test05a_dev 與 test05b_dev
/// test05a_dev 是處理 <h1> </h1> 這類的夾擊
/// test05b_dev 是處理括號
/// 有許多這樣要處理的，因為 regexp 只有 firstMatch 沒有 lastMatch
/// 而 string 卻是 char 沒有 string
/// 因此最後就開發了這個東西了
/// Split String Between 系列，這個是處理 <h1> </h1> 這類的夾擊，任何數字，例如 <h21></h21> 也會
/// 雖本用在 BibleText 轉換為 DText，但預期將來還有別處會用到
/// 因為屬文字處理，所以放在 Tool 資料夾中，與 SplitByRegex 類似
//public class SplitStringBtwBase {
//    /// override 這個
//    func generateLastRegepx()->NSRegularExpression {
//        return try! NSRegularExpression(pattern: "</(h\\d+)>", options: [.caseInsensitive])
//    }
//    func getMinStepWhenReverseFind()->Int {
//        // minStep 是後來加的，原本是 -1，其實沒必要1格1格往前，像 </h3> 最短也需要5字元，
//        return -5 // </h1> ... 長度 5
//    }
//    func generateSubStringWhenReverseFound(_ re: NSTextCheckingResult,_ str: String)->Substring{
//        return str[ Range(re.range(at: 1), in:str)! ] // h3
//    }
//    func generateFirstRegexp(_ tp:Substring)->NSRegularExpression {
//        return try! NSRegularExpression(pattern: "<" + tp + ">", options: [.caseInsensitive])
//    }
//    func get3String(_ str:String,_ r1:(idx2:Int,tp:Substring,idx1:Int))->(String,String,String){
//        let str1 = String(ijnSubString(str, len: r1.idx1))
//        
//        // <h2> 的 <> 字元是 +2, h2 是 tp.count
//        let str2 = String(ijnSubString(str, pos: r1.idx1 + r1.tp.count + 2, to: r1.idx2))
//        
//        // </h2> 的</> 字元是 +3, h2 是 tp.count
//        let str3 = String(ijnSubString(str, pos: r1.idx2 + r1.tp.count + 3))
//        
//        return (str1,str2,str3)
//    }
//    public func main(_ rr1:String)->[(w:String,tp:String?,dp:Int)]?{
//        // let rr1 = "abc<h1>bdkjsdf<h2>akjgioihag</h2>aohbioasd</h1>asdf"
//        let reg1 = self.generateLastRegepx()
//  
//        func lastFit(_ rr1:String) -> (idx2:Int,tp:Substring)?{
//            let minStep = self.getMinStepWhenReverseFind()
//            // minStep 是後來加的，原本是 -1，其實沒必要1格1格往前，像 </h3> 最短也需要5字元，
//            for i in stride(from: rr1.count+minStep, through: 0, by: minStep){
//                let len = rr1.count - i
//                let rr2 = reg1.firstMatch(in: rr1, options: [], range: NSRange(location: i, length: len))
//                if ( nil != rr2){
//                    let reStr = self.generateSubStringWhenReverseFound(rr2!, rr1)
//                    let rr3a = rr2!.range(at: 0)
//                    return (rr3a.location, reStr)
//                }
//            }
//            return nil
//        }
//        
//        func corresponseFit(_ rr1:String, _ rrr2: (idx2:Int,tp:Substring))->Int?{
//            let reg2 = self.generateFirstRegexp(rrr2.tp)
//            let rr7 = reg2.firstMatch(in: rr1, options: [], range: NSRange(location: 0, length: rr1.count))
//            if ( rr7 != nil ){
//                return rr7!.range(at: 0).location
//            } else {
//                return nil
//            }
//        }
//        
//        func tryFit(_ rr1:String)->(idx2:Int,tp:Substring,idx1: Int)?{
//            let rrr2 = lastFit(rr1)
//            if (rrr2 != nil ){
//                let rrr3 = corresponseFit(rr1, rrr2!)
//                if ( rrr3 != nil ){
//                    return (rrr2!.idx2,rrr2!.tp,rrr3!)
//                }
//            }
//            return nil
//        }
//        
//        func doOne(_ str:String,_ deep: Int,_ tpParent: String?)->[(w:String,tp:String?,dp:Int)]? {
//            let r1 = tryFit(str)
//            if ( r1 == nil ){
//                return nil
//            }
//            
//            let tp = String(r1!.tp)
//            
//            let strs = self.get3String(str, r1!)
//            
//            var re: [(w:String,tp:String?,dp:Int)] = []
//            if (strs.0.count != 0 ){
//                re.append((w:strs.0,tp: tpParent,dp: deep))
//            }
//            let nextTpParent = tpParent == nil ? tp : tp + " " + tpParent!
//            var re2 = doOne(strs.1, deep + 1, nextTpParent)
//            if (re2 == nil ){
//                if ( strs.1.count != 0 ){
//                    if ( tpParent == nil ){
//                        re.append((strs.1, tp, deep + 1))
//                    } else {
//                        re.append((strs.1, tp + " " + tpParent!, deep + 1))
//                    }
//                }
//            } else {
//               re.append(contentsOf: re2!)
//            }
//            if (strs.2.count != 0){
//                re.append((w:strs.2,tp: tpParent,dp: deep))
//            }
//            
//            return re
//        }
//        
//        return doOne(rr1, 0, nil)
//    }
//}

