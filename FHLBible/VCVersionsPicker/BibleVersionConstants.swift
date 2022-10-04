//
//  BibleVersionConstants.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/4.
//

import Foundation

class BibleVersionConstants {
    static var s: BibleVersionConstants = BibleVersionConstants()
    var datas: [OneGroup] { get {
        if _datas == nil {
            _datas = [
                OneGroup(na: .ch, vers: dataOfCht(), od: 1),
                OneGroup(na: .en, vers: dataOfEn(), od: 3),
                OneGroup(na: .hg, vers: dataOfHebrewGreek() , od: 5),
                OneGroup(na: .fo, vers: dataofForeign() ,od: 7),
                OneGroup(na: .mi, vers: dataOfMinnan(), od: 9),
                OneGroup(na: .ha, vers: dataOfHakka(), od: 11),
                OneGroup(na: .ind, vers: dataOfIna(), od: 13),
                OneGroup(na: .ot, vers: dataOfOther(), od: 15),
            ]
            
            var tmp: [One] = []
            _datas?.forEach({tmp.append(contentsOf: $0.vers!)})
            self._tryChangeCna(tmp)
        }
        return _datas!
    } }
    private var _datas: [OneGroup]? = nil
    private func dataOfCht() -> [One] {
        return [
            One( na: "cbol", cna: "原文直譯(參考用)", cds: [.yrnow, .pr, .officer] ),
            One( na: "tcv2019", cna: "現代中文譯本2019版", yr: 2019, cds: [.yrnow, .pr, .officer] ),
           One( na: "cccbst", cna: "聖經公會四福音書共同譯本", yr: 2015, cds: [.yrnow, .pr, .officer] ),
            One( na: "cnet", cna: "NET聖經中譯本", yr: 2011, cds: [.yrnow, .pr, .study] ),
           One( na: "rcuv", cna: "和合本2010", yr: 2010, cds:[.yrnow, .pr, .officer] ),
           One( na: "csb", cna: "中文標準譯本", yr: 2008, cds:[.yrnow, .pr, .officer] ),
           One( na: "recover", cna: "恢復本", yr: 2003, cds: [.yrnow, .pr, .officer] ),
           One( na: "tcv95", cna: "現代中文譯本1995版", yr: 1995, cds: [.yrnow, .pr, .officer] ),
           One( na: "ncv", cna: "新譯本", yr: 1992, cds: [.yrnow, .pr, .officer] ),
           One( na: "lcc", cna: "呂振中譯本", yr: 1970, cds: [.yrnow, .pr, .officer] ),
           One( na: "ofm", cna: "思高譯本", yr: 1968, cds: [.yrnow, .cc, .officer] ),
            One( na: "cwang", cna: "王元德官話譯本", yr: 1933, cds: [.pr, .yr1960, .officer] ),
           One( na: "cumv", cna: "官話和合本", yr: 1919, cds:[.pr, .yr1960, .officer]  ),
            One( na: "unv", cna: "和合本", yr: 1911, cds: [.pr, .yr1919, .officer] ),
            One( na: "orthdox", cna: "俄羅斯正教文理譯本", yr: 1910, cds: [.ro, .yr1919, .ccht]),
            One( na: "cuwv", cna: "文理和合本", yr: 1907, cds: [.pr, .yr1919, .ccht] ),
            One( na: "wlunv", cna: "深文理和合本", yr: 1906, cds: [.pr, .yr1960, .ccht] ),
            One( na: "cuwve", cna: "淺文理和合本", yr: 1906, cds: [.pr, .yr1919, .ccht] ),
            One( na: "ssewb", cna: "施約瑟淺文理譯本", yr: 1902, cds: [.pr, .yr1919, .ccht] ),
            One( na: "pmb", cna: "北京官話譯本", yr: 1878, cds: [.pr, .yr1919, .officer] ),
            One( na: "deanwb", cna: "粦為仁譯本", yr: 1870, cds: [.pr, .yr1919, .ccht] ),
            One( na: "hudsonwb", cna: "胡德邁譯本", yr: 1867, cds: [.pr, .yr1919, .ccht] ),
            One( na: "wdv", cna: "文理委辦譯本", yr: 1854, cds: [.pr, .yr1919, .ccht] ),
            One( na: "goddwb", cna: "高德譯本", yr: 1853, cds: [.pr, .yr1919, .ccht] ),
            One( na: "nt1864", cna: "新遺詔聖經", yr: 1840, cds: [.pr, .yr1850, .ccht] ),
            One( na: "mormil", cna: "神天聖書", yr: 1823, cds: [.pr, .yr1850, .ccht] ),
            One( na: "marwb", cna: "馬殊曼譯本", yr: 1822, cds: [.pr, .yr1850, .ccht] ),
            One( na: "basset", cna: "白日昇徐約翰文理譯本", yr: 1707, cds: [.pr, .yr1800, .ccht] ),
            One( na: "cmxuhsb", cna: "徐匯官話新譯福音", yr: 1948, cds: [.pr, .yr1960, .officer] ),
            One( na: "cwangdmm", cna: "王多默聖史宗徒行實", yr: 1875, cds: [.pr, .yr1919, .ccht] ),
            One( na: "cwhsiaosb", cna: "蕭舜華官話", yr: 1949, cds: [.pr, .yr1960, .officer] ),
            One( na: "cwmgbm", cna: "四人小組譯本", yr: 1837, cds: [.pr, .yr1850, .ccht] ),
            One( na: "cwfaubsb", cna: "聖保祿書翰並數位宗徒涵牘", yr: 0, cds: [.cc] ),
            One( na: "cwjdsb", cna: "德如瑟四史聖經譯註", yr: 0, cds: [.cc] ),
            One( na: "cwkfag", cna: "郭實臘新遺詔書和舊遺詔聖書", yr: 1838, cds: [.pr, .yr1850, .ccht] ),
            One( na: "cwliwysb", cna: "宗徒大事錄和新經譯義", yr: 1875, cds: [.pr, .yr1919, .ccht] ),
            One( na: "cwmxb", cna: "馬相伯救世福音", yr: 1937, cds: [.pr, .yr1919, .ccht] ),
            One( na: "cwont", cna: "俄羅斯正教新遺詔聖經", yr: 0, cds: [.ro] ),
            One( na: "cwplbsb", cna: "卜士傑新經公函與默示錄", yr: 0, cds: [.cc] ),
            One( na: "cwtaiping", cna: "太平天國文理譯本", yr: 1853, cds: [.pr, .yr1919, .ccht] ),
            One( na: "cwwuchsb", cna: "吳經熊新經全集聖詠譯義", yr: 1946, cds: [.pr, .yr1960, .ccht] ),
            One( na: "cxubinwsb", cna: "許彬文四史全編", yr: 1899, cds: [.pr, .yr1919, .ccht] ),
            One( na: "cogorw", cna: "高連茨基聖詠經", yr: 0, cds: [.ro] ),
        ]
    }
    private func _tryChangeCna(_ data:[One]){
        // 繁體、簡體
        let abvRe = ManagerLangSet.s.curIsGb ? AutoLoadDUiabv.s.recordGb : AutoLoadDUiabv.s.record
        abvRe.forEach { a1 in
            let r1 = data.ijnFirstOrDefault({$0.na == a1.book})
            if r1 != nil && a1.cname != nil {
                r1!.cna = a1.cname!
            }
        }
    }
    private func dataOfEn()->[One] {
        return [
            One( na: "kjv", cna: "KJV", yr: 1611, od: 1 ),
            One( na: "darby", cna: "Darby", yr: 1890, od: 3 ),
            One( na: "bbe", cna: "BBE", yr: 1965, od: 5 ),
            One( na: "erv", cna: "ERV", yr: 1987, od: 7 ),
            One( na: "asv", cna: "ASV", yr: 1901, od: 9 ),
            One( na: "web", cna: "WEB", yr: 2000, od: 11 ),
            One( na: "esv", cna: "ESV", yr: 2001, od: 13 )
        ]
    }
    private func dataOfHebrewGreek()->[One]{
        return [
            One( na: "bhs", cna: "舊約馬索拉原文", od: 1 ),
            One( na: "fhlwh", cna: "新約原文", od: 3 ),
            One( na: "lxx", cna: "七十士譯本", od: 5 ),
        ]
        
    }
    private func dataofForeign()->[One]{
        return [
            One( na: "vietnamese", cna: "越南聖經", od: 1 ),
            One( na: "russian", cna: "俄文聖經", od: 3 ),
            One( na: "korean", cna: "韓文聖經", od: 5 ),
            One( na: "jp", cna: "日語聖經", od: 7 ),
        ]
    }
    private func dataOfMinnan()->[One]{
        return [
            One( na: "tte", cna: "現代台語2013版全羅", od: 1 ),
            One( na: "ttvh", cna: "現代台語2013版漢字", od: 3 ),
            One( na: "ttvcl2021", cna: "現代台語2021版全羅", od: 5 ),
            One( na: "ttvhl2021", cna: "現代台語2021版漢字", od: 5 ),
            One( na: "apskcl", cna: "紅皮聖經全羅", od: 9 ),
            One( na: "apskhl", cna: "紅皮聖經漢羅", od: 11 ),
            One( na: "bklcl", cna: "巴克禮全羅", od: 13 ),
            One( na: "bklhl", cna: "巴克禮漢羅", od: 15 ),
            One( na: "tghg", cna: "聖經公會巴克禮台漢本", od: 17 ),
            One( na: "prebklcl", cna: "馬雅各全羅", od: 19 ),
                            // {na:'prebklhl',od:20,cna:'馬雅各漢羅'}, // 要廢棄的，因為目前漢羅轉換差異，沒辦法順利轉換
            One( na: "sgebklcl", cna: "全民台語聖經全羅", od: 23 ),
            One( na: "sgebklhl", cna: "全民台語聖經漢羅", od: 25 ),
        ]
    }
    private func dataOfHakka()->[One]{
        return [
            One( na: "thv2e", cna: "聖經公會現代客語全羅", od: 5 ),
            One( na: "thv12h", cna: "聖經公會現代客語漢字", od: 7 ),
            One( na: "hakka", cna: "汕頭客語聖經", od: 21 )
        ]
        
    }
    private func dataOfIna()->[One]{
        return [
            One( na: "rukai", cna: "聖經公會魯凱語聖經", od: 1 ),
            One( na: "tsou", cna: "聖經公會鄒語聖經", od: 3 ),
            One( na: "ams", cna: "聖經公會阿美語1997", od: 5 ),
            One( na: "amis2", cna: "聖經公會阿美語2019", od: 7 ),
            One( na: "ttnt94", cna: "聖經公會達悟語新約聖經", od: 9 ),
            One( na: "sed", cna: "賽德克語", od: 11 ),
            One( na: "tru", cna: "聖經公會太魯閣語聖經", od: 13 )
        ]
    }
    private func dataOfOther()->[One]{
        return [
            One( na: "tibet", cna: "藏語聖經", od: 1 )
        ]
    }
    class One {
        init(na: String, cna: String, yr: Int? = nil, cds: [TpChtSub]? = nil,  od: Int? = nil) {
            self.na = na
            self.cna = cna
            self.cds = cds
            self.yr = yr
            self.od = od
        }
        var na: String // cbol
        var cna: String // 原文直譯
        var cds: [TpChtSub]? // conditions
        var yr: Int?
        var od: Int? // order
    }
    class OneGroup {
        init(na: BibleVersionConstants.TpGroup, vers: [BibleVersionConstants.One]? = nil, od: Int? = nil) {
            self.na = na
            self.cna = _tp2cna[na]!
            self.vers = vers
            self.od = od
        }
        
        var na: TpGroup
        var cna: String
        var vers: [One]?
        var od: Int?
        
        // 中文 英文 希伯來、希臘文 其它外語 台語 客家語 台灣原住民語 其它
        // 中文 英文 希伯来、希腊文 其它外语 台语 客家语 台湾原住民语 其它
        private var _tp2cna: [TpGroup:String] = [
            .ch:"中文",
            .en:"英文",
            .hg:NSLocalizedString("希伯來、希臘文", comment: ""),
            .fo:NSLocalizedString("其它外語", comment: ""),
            .mi:NSLocalizedString("台語", comment: ""),
            .ha:NSLocalizedString("客家語", comment: ""),
            .ind:NSLocalizedString("台灣原住民語", comment: ""),
            .ot:"其它"
        ]
    }

    enum TpGroup: String {
        /// chinese
        case ch = "ch" // = "中文"
        /// english
        case en = "en" // = "英文"
        /// hebrew greek
        case hg = "hg" // = "希伯來、希臘文"
        /// foregin
        case fo = "fo" // = "其它外語"
        /// minnan
        case mi = "mi" // = "台語"
        /// hakka
        case ha = "ha"// = "客家語"
        /// indigenous
        case ind = "ind" // = "台灣原住民語"
        /// other
        case ot = "ot" // = "其它"
    }

    // 基督新教 羅馬天主教 俄羅斯正教 官話(白話文) 文理(文言文) 研讀本 1800前 近代
    // 基督新教 罗马天主教 俄罗斯正教 官话(白话文) 文理(文言文) 研读本 1800前 近代
    enum TpChtSub: String {
        /// "基督新教" 1 (若使用 view 的 tag)
        case pr = "基督新教"
        /// "羅馬天主教" 2
        case cc = "羅馬天主教"
        ///  "俄羅斯正教" 3
        case ro = "俄羅斯正教"
        ///  "官話(白話文)" 11
        case officer =  "官話(白話文)"
        /// "文理(文言文)" 12
        case ccht =  "文理(文言文)"
        /// "研讀本" 13
        case study = "研讀本"
        /// "1800前" 21
        case yr1800 =  "1800前"
        /// "1800-50" 22
        case yr1850 = "1800-50"
        /// "1850-1918" 23
        case yr1919 = "1850-1918"
        /// "1919-60" 24
        case yr1960 = "1919-60"
        /// "近代" 25
        case yrnow = "近代"
    }
}
