// 已重構至 FHLCommon，隨著 class StringToVerseRange
// class class GetAddresses


//import Foundation
//import FHLCommon
//
///// 開發 GetAddresses 而需求的
//public protocol IBookNameTryGetBookIdResult {
//    var descript: String {get}
//    var idBook: Int {get}
//}
//open class BookNameTryGetBookIdResult : IBookNameTryGetBookIdResult{
//    init(_ descript: String,_ idBook: Int) {
//        self.descript = descript
//        self.idBook = idBook
//    }
//    public var descript: String
//    public var idBook: Int
//}
///// 開發 GetAddresses 而需求的
//public protocol IGetAddressesType {
//    /** 1:32-2:31 (tp:0) 1:2-32 (tp:1) 23 (23節 或 23章 tp:2) */
//    var tp: Int {get}
//    var ch1: Int {get}
//    var vr1: Int {get}
//    var ch2: Int {get}
//    var vr2: Int {get}
//}
//open class GetAddressesType : IGetAddressesType{
//    internal init(tp: Int, ch1: Int, vr1: Int, ch2: Int, vr2: Int) {
//        self.tp = tp
//        self.ch1 = ch1
//        self.vr1 = vr1
//        self.ch2 = ch2
//        self.vr2 = vr2
//    }
//    
//    public var tp: Int
//    public var ch1: Int
//    public var vr1: Int
//    public var ch2: Int
//    public var vr2: Int
//    
//}
