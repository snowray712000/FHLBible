import Foundation


class DictTwcbNewConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = doDivIdt([DText(str)])
        r1 = ssDtNewLine(r1)
        r1 = ssDtParentheses(r1)
        r1 = ssDtSpanBibtext(r1) // 這必需在 Exp 前
        r1 = ssDtSpanExp(r1)
        r1 = ssDtReference(r1)
        r1 = ssDtGreek(r1)
        r1 = ssDtHebrew(r1)
        return r1
    }
}
class DictTwcbOldConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = doDivIdt([DText(str)])
        r1 = ssDtParentheses(r1)
        r1 = ssDtSpanBibtext(r1) // 這必需在 Exp 前
        r1 = ssDtSpanExp(r1)
        
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtReference(r1)
        r1 = ssDtHebrew(r1)
        r1 = ssDtGreek(r1)
        return r1
    }
}

class DictCbolOldConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = [DText(str)]
        r1 = ssDtParentheses(r1)
        r1 = ssDtReference(r1)
        
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtSNH(r1)
        r1 = ssDtSNG(r1)
        return r1
    }
    
    
}
class DictCbolNewConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = [DText(str)]
        r1 = ssDtParentheses(r1)
        r1 = ssDtReference(r1)
        
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtSNH(r1)
        r1 = ssDtSNG(r1)
        return r1
    }
}
class DictCbolOldEnConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = [DText(str)]
        r1 = ssDtParentheses(r1)
        r1 = ssDtReference(r1)
        
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtSNH(r1)
        r1 = ssDtSNG(r1)
        return r1
    }
    
    
}
class DictCbolNewEnConvertor : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        var r1 = [DText(str)]
        r1 = ssDtParentheses(r1)
        r1 = ssDtReference(r1)
        
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtSNH(r1)
        r1 = ssDtSNG(r1)
        return r1
    }
}

fileprivate func removeAdditionalSpace(_ str:String)->String{
    // 每行，若以下面任何作為字首，則處理空白數量；反之，將其加在上面一行
    let itemData =  NSLocalizedString("零、,壹、,貳、,參、,肆、,伍、,陸、,柒、,捌、,玖、,拾,一、,二、,三、,四、,五、,六、,七、,八、,九、,十、,（一）,（二）,（三）,（四）,（五）,（六）,（七）,（八）,（九）,（十,1.,2.,3.,4.,5.,6.,7.,8.,9.,10.,11.,12.,13.,14.,15.,16.,17.,18.,19.,20.,(1,(2,(3),(4),(5),(6),(7),(8),(9),●,◎,┌,│,├,└,☆,○,a.,b.,c.,d.,e.,f.,g.,h.,i.,j.,k.,A.,B.,C.,D.,E.,F.,G.,H.,I.,J.,K.", comment: "").components(separatedBy: ",")
    
    // 空白隔開
    var dataArray = str.replacingOccurrences(of: "\r\n", with: "\n") // 離線版是\n，線上版是\r\n
        .components(separatedBy: "\n")
    if dataArray.count == 0 { return str }
    
    // 假設: 第1行的空白數量一定是最少的，下面縮排，都減掉這個空白
    let leadingWhitespaceCount0 = dataArray[0].prefix(while: { $0.isWhitespace }).count

    // 從後面到前面，因為會 remove 某行，反過來處理較簡單
    for i in ijnRange(dataArray.count - 1,dataArray.count,-1 ){
        let lineStr = dataArray[i]
        let trimmedStr = lineStr.trimmingCharacters(in: .whitespaces)
        if trimmedStr.isEmpty { continue }
        if sinq(itemData).any({trimmedStr.hasPrefix($0)}){
            let leadingWhitespaceCount = lineStr.prefix(while: { $0.isWhitespace }).count
            if leadingWhitespaceCount > leadingWhitespaceCount0 {
                let startIndex = lineStr.index(lineStr.startIndex, offsetBy: leadingWhitespaceCount0)
                    dataArray[i] = String(lineStr[startIndex...])
            }
        } else {
            if i != 0 {
                dataArray[i-1].append(trimmedStr)
                dataArray.remove(at: i)
            }
        }
    }
    
    return dataArray.joined(separator: "\r\n")
}

class CommentDataStrToDText : IStr2DTextArray{
    func main(_ str:String) -> [DText] {
        let str2 = removeAdditionalSpace(str)
        
        var r1 = [DText(str2)]
        r1 = ssDtParentheses(r1)
        r1 = ssDtReference(r1)
        r1 = ssDtNewLine(r1)
        
        r1 = ssDtSNH(r1)
        r1 = ssDtSNG(r1)
        r1 = ssDtHebrew(r1)
        r1 = ssDtGreek(r1)
        return r1
    }
}




