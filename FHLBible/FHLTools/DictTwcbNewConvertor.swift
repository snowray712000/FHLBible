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
class CommentDataStrToDText : IStr2DTextArray{
    func main(_ str:String) -> [DText] {
        var r1 = [DText(str)]
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




