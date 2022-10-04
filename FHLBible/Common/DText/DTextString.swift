import Foundation

/// 方便的小東西
public class DTextString : IDTextTestGetter {
    var str: String
    public init(_ str:String){
        self.str = str
    }
    public func main() -> DOneLine {
        return gBaseTest ([DText(str)], "", "" )
}}
