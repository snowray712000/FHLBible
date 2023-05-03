//
//  VCAudioVersion.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/6.
//

import Foundation
// dialog of 語音聖經版本選擇
class VCAudioVersion : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        return title1data[i]
    }
    override var _ovTitle1: [String] {
        return title1data
    }
    override var _ovTitle2: [String] {
        return []
    }
    override var _ovIsLastRedForCancel: Bool { false }
    lazy var title1data:[String] = {
        return AudioBibleVersions.s.getNamesOrderById()
    }()
}

class AudioBibleVersions {
    init(){}
    static var s = AudioBibleVersions()
    private lazy var id2Name: [Int:String] = {
        let r1 = "0.和合本 1.台語 2.客家話 3.廣東話 4.現代中文譯本 5.台語新約(台灣長老教會傳播中心授權) 6.紅皮聖經 7.希伯來文 8.福州話 9.希臘文 10.spring台語 11.spring和合本 12.NetBible中文版 13.全民台語聖經 14.鄒語 15.台語南部腔 17.現代台語譯本"
        let r2 = NSLocalizedString(r1, comment: "")
        let tokens = r2.components(separatedBy: " ")
        var myDictionary = [Int: String]()
        // 將字串依照空格分割，取出每一個編號與對應的譯本名稱，加入 Dictionary 中
        for token in tokens {
            let parts = token.components(separatedBy: ".")
            if parts.count == 2, let key = Int(parts[0]), let value = parts.last {
                myDictionary[key] = value
            }
        }
        return myDictionary
    }()
    // for getIdWhereName func
    private lazy var name2Id: [String:Int] = {
        let reversedDict = id2Name.reduce(into: [String:Int]()) { (result, element) in
            let (key, value) = element
            result[value] = key
        }
        return reversedDict
    }()
    // 為了 VCAudioVersion 而存在
    func getNamesOrderById() -> [String]{
        let r1 = AudioBibleVersions.s.id2Name
        let r2 = r1.keys.sorted()
        return r2.map{ r1[$0]! }
    }
    // For VCAudioBible::pickAudioVersion
    func getIdWhereName(_ name:String)->Int? {
        return name2Id[name] 
    }
    // For 中控中心的 artist 資訊
    func getNameWhereId(_ id:Int)->String? {
        return id2Name[id]
    }
}
