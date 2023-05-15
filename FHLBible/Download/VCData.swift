//
//  VCData.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation
import UIKit
import ZIPFoundation
import IJNSwift
import zlib

class VCData : VCOptionListViaTableViewControllerBase{
    override func viewDidLoad() {
        super.viewDidLoad()
        _onClickRow$.addCallback { sender, pData in
            self._doClickRow(pData!)
        }
        
        self.makeSureMainDbExistAsync()
        
        self.initial_title1_row2version()

        self.ver2date = getVersion2Date()
        
        self.reloadStatesUsingCheckingFile()
        self.updateTitle2DataAndColorFromStates()
    }
    func _doClickRow(_ row: Int) {
        let ver = self.row2version[row]
        if ( ver != nil ){
            let st = self.states[row]
            if st == nil {
                return
            }
            if st!.state == .inUse {
                // delete?
                MessageBox.presentDeletionAlert(self, "確定要刪除嗎?") { _ in
                    self.do_delete_bible(ver!)
                    self.reloadStatesUsingCheckingFile()
                    self.updateTitle2DataAndColorFromStates()
                    self.tableView.reloadData()
                }
            } else if st!.state == .downloading {
                //
            } else if st!.state == .readyUpdate {
                // not implement yet
                self.do_delete_bible(ver!)
                self.do_one_bible(ver!)
            } else {
                if isReadyMainDb() {
                    // 處理它 (原本)
                    self.do_one_bible(ver!)
                } else {
                    // 丟到排隊，等 main.db 好了，會自動開始
                    queueWaitMainDbCompleted.fnDoOneBible = self.do_one_bible
                    queueWaitMainDbCompleted.mainAddToQueueNeverRepeatAdded(ver!)
                }
            }
            return
        }
    }
    
    /// `顯示於 tableview 的資料 _ title`
    override var _ovTitle1: [String] { get {return _ovTitle1Data} }
    /// `顯示於 tableview 的資料 _ 小字 sub title`
    override var _ovTitle2: [String]? { get{ return _ovTitle2Data.count != 0 ? _ovTitle2Data : []}}
    /// `顯示於 tableview 的資料 _ 顏色`
    override var _ovColors: [UIColor]? { get{return self._ovColorsData }}

    /// 由 initial_title1_row2version 產生一次
    /// - SeeAlso: initial_title1_row2version()
    var _ovTitle1Data: [String] = ["和合本","和合本(簡體)","KJV"]
    /// 由 initial_title1_row2version 產生一次
    /// - SeeAlso: initial_title1_row2version()
    private var row2version = [0:"unv",1:"unv_gb",2:"kjv"]
    /// 下面4個，主要由 `每個譯本的state決定`
    /// reloadStatesUsingCheckingFile updateTitle2DataAndColorFromStates 是更新的關鍵流程
    var _ovTitle2Data: [String] = []
    var _ovColorsData: [UIColor] = []
    var states: [Int:CheckInitialState.DownloadState] = [:]
    var ver2date: [String:Date?] = [:]
    
    
    /// `因為main.db存在，大約需4秒，它於 下載譯本後 正規化過程時 會需要用到`
    /// 但那時候再下載就不好了，所以先下載
    /// 只要程式沒重灌，這8kb大小的 main.db 會一直存在
    private func makeSureMainDbExistAsync(){
        MainDbMakeSureExist().main()
    }
    /// `讓 _ovTitle1 變數的內容，自動產生，取代寫死的內容`
    /// 只需在 viewDidLoad 呼叫一次
    /// 來源是 uiabv.php 的 candownload == 1 的譯本
    /// 排序是來自 譯本選擇ui 的大分類，也就是 會用到 BibleVersionConstants class
    /// 並且，有的譯本不需要譯本，就不會加 _gb
    private func initial_title1_row2version(){
        // reset
        _ovTitle1Data = [] // 和合本 ...
        row2version = [:] // [1: unv]
        
        // TODO: manual
        if ManagerLangSet.s.curIsGb {
            _ovTitle1Data.append("注释")
            _ovTitle1Data.append("Parsing")
            _ovTitle1Data.append("CBOL字典")
            row2version[0] = "comm_gb"
            row2version[1] = "parsing_gb"
            row2version[2] = "cbol_dict_gb"
        } else {
            _ovTitle1Data.append("註釋")
            _ovTitle1Data.append("Parsing")
            _ovTitle1Data.append("CBOL字典")
            row2version[0] = "comm"
            row2version[1] = "parsing"
            row2version[2] = "cbol_dict"
        }
        
        // bibles
        let initList = BibleVersionsListForDownloadGetter()
        let r1 = initList.main()
        let cntManual = _ovTitle1Data.count
        
        ijnRange(0, r1.count).forEach({i in
            let a1 = r1[i]
            row2version[i+cntManual] = a1.0
            _ovTitle1Data.append(a1.1)
        })
    }
    /// `和合本` `unv_gb` 按 `正確順序` 並且只列出 `能下載` 並且只有必要 `_gb` 才會自動加，像外語就不會加
    class BibleVersionsListForDownloadGetter{
        func main()->[(String,String)]{
            let canDownload = getBibleCanDownloadFromUiAbv()
            let haveGb = getBibleHaveGb()
            let order = getBibleVersionListOrderLikeVersionChoose()
            let isGb = ManagerLangSet.s.curIsGb
            
            var re:[(na:String,cname:String)] = []
            order.forEach({ a1 in
                let cname = canDownload[a1]
                if cname != nil {
                    if isGb {
                        let na2 = haveGb.contains(a1) ? "\(a1)_gb" : a1
                        re.append((na:na2,cname:cname!))
                    } else {
                        re.append((na:a1,cname:cname!))
                    }
                }
            })
            
            return re
        }
        
        /// 為了 `列出可下載譯本 的 順序，是按著選擇譯本的順序` 預備
        private func getBibleVersionListOrderLikeVersionChoose()->[String]{
            let r1 = from( BibleVersionConstants.s.datas ).orderBy({$0.od ?? 0})
                .select({from($0.vers!).orderBy({$0.od ?? 0}).select({$0.na}).toArray()}).toArray()
            
            var re:[String] = []
            r1.forEach({re.append(contentsOf: $0)})
            return re
        }
        /// 為了 `列出可下載譯本 的 name 對應 中文`
        private func getBibleCanDownloadFromUiAbv()->[String:String]{
            
            let r1 = from(AutoLoadDUiabv.s.record).whereTrue({$0.candownload == 1}).toArray()
            
            var re:[String:String] = [:]
            if (ManagerLangSet.s.curIsGb){
                r1.forEach({re[$0.book] = $0.cname})
            } else {
                r1.forEach({re[$0.book] = $0.cname})
            }
            
            return re
        }
        /// 有些譯本需要 `_gb` 但有些不用
        private func getBibleHaveGb()->[String]{
            return BibleVersionConstants.s.getBiblesHaveGb()
        }
    }
    /// `有些zip，沒有main，所以正規化的時候錯` 因此，長存個 main.db 來正規化用
    ///  在 initial 時，呼叫一次。會非同步產生 /offline/main.db 檔案
    class MainDbMakeSureExist{
        func main(){
            
            if fm.fileExists(atPath: pathMainDb.path){
                // 曾有個 bug, 讓檔案是 0kb, 所以就沒作該作的事
                if fm.sizeOfFile(atPath: pathMainDb.path) != 0{
                    return
                }
                try! fm.removeItem(at: pathMainDb)
            }
            
            // 已存在zip就不下載，就直接解壓縮並取出 main table
            if fm.fileExists(atPath: pathDownload.path) == false {
                downloader.onFinished$.addCallback { sender, pData in
                    self.doAfterZipExist()
                }
                downloader.mainAsync()
            } else {
                self.doAfterZipExist()
            }
            
        }
        private lazy var pathDownload = fm.getPathAtDocumentUserDomain(pathRelative: "/download/bible_little.zip")
        private lazy var pathMainDb = fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
        private lazy var pathUnzipDb = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_little.db")
        private lazy var fm = FileManager.default
        private lazy var downloader = Download_unv()
        private lazy var generateMainDb = SQLGenerateMainDb()
        private func doAfterZipExist(){
            Unzipor().main(pathZip: pathDownload)
            generateMainDb.main()
            deleteDownloadAndUnzipFile()
        }
        class SQLGenerateMainDb : EasySQLiteBase {
            public override var pathToDatabase: URL!{
                return fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
            }
            private lazy var fm = FileManager.default
            private lazy var path_db = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_little.db")
            func main(){
                _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
                
                // 3個分號，很適合用在 sqlite
                // drop table 要在 attach 之前，不然會把 db2.main 給 drop 掉
                let cmd = """
drop table if exists main;
attach database "\(path_db)" as db2;
create table main as select * from db2.main;
"""
                _ = doUpdateMore(stringOfSQLite: cmd)
            }
        }
        private func deleteDownloadAndUnzipFile(){
            do {
                for a1 in [pathUnzipDb,pathDownload]{
                    if fm.fileExists(atPath: a1.path){
                        try fm.removeItem(at: a1)
                    }
                }
            }catch{
                print(error.localizedDescription)
            }
        }
        
    }

    /// `確認 譯本 是否需要更新` 用的
    private func getVersion2Date()->[String:Date?]{
        let isReady = AutoLoadDUiabv.s.record.count != 0 && AutoLoadDUiabv.s.recordGb.count != 0;
        if isReady == false {
            return [:]
        }
        
        var re:[String:Date?] = [:]
        // TODO: 手動部分
        re[ManagerLangSet.s.curIsGb ? "comm_gb":"comm"] = AutoLoadDUiabv.s.dateOfComment(isGb: ManagerLangSet.s.curIsGb) ?? Date(2022, 11, 30, 0, 0, 0)
        re[ManagerLangSet.s.curIsGb ? "parsing_gb":"parsing"] = AutoLoadDUiabv.s.dataOfParsing(isGb: ManagerLangSet.s.curIsGb) ?? Date(2022, 11, 30, 0, 0, 0)
        re[ManagerLangSet.s.curIsGb ? "cbol_dict_gb":"cbol_dict"] = AutoLoadDUiabv.s.dataOfParsing(isGb: ManagerLangSet.s.curIsGb) ?? Date(2022, 11, 30, 0, 0, 0) // 因為目前沒有 cbol dict 的日期， uiabv。所以，先用 parsing。
        
        // uiabv.php
        let record = AutoLoadDUiabv.s.record
        let recordGb = AutoLoadDUiabv.s.recordGb
        
        re["unv"] = record.ijnFirstOrDefault({$0.book == "unv"})?.getVersion()
        re["unv_gb"] = recordGb.ijnFirstOrDefault({$0.book == "unv"})?.getVersion()
        
        let biblesHaveGb = BibleVersionConstants.s.getBiblesHaveGb()
        let biblesNoGb = from( record ).whereTrue { a1 in
            return biblesHaveGb.contains(a1.book) == false
        }.select({$0.book}).toArray()

        // re[cbol] = record.first(cbol).getVersion()
        // re[cbol_gb] = recordgb.first(cbol).getVersion()
        // re[kjv] = record.first(kjv).getVersion()
        // kjv 不需要 gb 版
        let isGb = ManagerLangSet.s.curIsGb
        biblesHaveGb.forEach({a1 in
            if isGb {
                re["\(a1)_gb"] = recordGb.ijnFirstOrDefault({$0.book == a1})?.getVersion()
            } else {
                re[a1] = record.ijnFirstOrDefault({$0.book == a1})?.getVersion()
            }
        })
        biblesNoGb.forEach { a1 in
            re[a1] = record.ijnFirstOrDefault({$0.book == a1})?.getVersion()
        }
        
        // check
        print("check ver2Date")
        var error_vers: [String] = []
        re.forEach { (key: String, value: Date?) in
            if value == nil {
                let r1 = record.ijnFirstOrDefault({$0.book == key})
                if r1?.candownload == 1 {
                    print("uiabv.php 沒有 \(key) 版本嗎?")
                    if r1 == nil {
                        print("是的, uiabv中沒有此譯本資訊, 回報給 tjm.")
                    } else {
                        print("不是的, uiabv 中有此譯本 \(r1!.cname!), 也 candownload, 但沒有 version 資訊, 回報給 tjm")
                        print(record.ijnFirstOrDefault({$0.book == key})?.getVersion() ?? "")
                    }
                    
                    error_vers.append(key)
                }
            }
        }
        for a1 in error_vers{
            re.removeValue(forKey: a1)
        }
        
        return re
    }
    /// `此譯本 狀態 如何。取得 state` 用的
    private func reloadStatesUsingCheckingFile(){
        for a1 in row2version {
            states[a1.key] = CheckInitialState().main(ver: a1.value,
                                                      ver2Date: self.ver2date)
        }
    }

    private func updateTitle2DataAndColorFromStates(){
        _ovTitle2Data = ijnRange(0, _ovTitle1.count).map({$0.description})
        _ovColorsData = ijnRange(0, _ovTitle1.count).map{_ in
            return .label
        }
        for a1 in states{
            _ovTitle2Data[a1.key] = a1.value.toString()
            _ovColorsData[a1.key] = a1.value.toColor()
        }
    }

    /// `onClick 時，可能會用到`
    /// 當第1次程式運作時， main.db 還沒好，但人家已經按了下載了
    /// 就要先存起來，在執行緒中等待，直到 main.db 存在，就開始下載
    /// 其實不是下載，而是執行 原本的動作 函式指標  self.do_one_bible
    lazy var queueWaitMainDbCompleted = DoVersionWaitMainDbCompleted()
    private func isReadyMainDb()->Bool { return FileManager.default.fileExists(atPath: FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db").path)}
    /// 在執行緒等 main.db 有了之後，就會開始下載所有
    class DoVersionWaitMainDbCompleted{
        var fnDoOneBible: ((String)->Void)?
        func mainAddToQueueNeverRepeatAdded(_ ver:String){
            if self.isFinish {
                // 已經執行緒跑過了，不該再呼叫此了
                return
            }
            
            self.addOrIgnore(ver)
            
            if isExistThread {
                // 不然，會有兩個 while 迴圈在 sleep
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                if self.isExistThread {
                    // 不然，會有兩個 while 迴圈在 sleep
                    // 考慮真的很衰，快速產生了2個 task
                    return
                }
                self.isExistThread = true
                
                while ( self.isFileExist() == false ){
                    print("wait main.db completed.")
                    sleep(1)
                }
                
                self.doEachVers()
                
                self.isFinish = true
            }
            
        }
        var isExistThread:Bool = false
        var isFinish:Bool = false
        private var vers:[String] = []
        private func addOrIgnore(_ ver:String){
            if vers.contains(ver) == false {
                vers.append(ver)
            }
        }
        private func doEachVers(){
            for a1 in vers{
                self.fnDoOneBible!(a1)
            }
        }
        lazy var fm = FileManager.default
        lazy var path = fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
        func isFileExist()->Bool { fm.fileExists(atPath: path.path) }
        
    }
    /// `onClick 時，會用到`
    /// 執行緒產生的資料，於要記錄一下對應的資訊
    var download_bible: [String:DoOneDownload_bible_little] = [:]
    private func gDownloadBible(_ ver:String)->DoOneDownload_bible_little {
        // 每次按，都要重新產生，因為一個只能下載一次。
        switch ver {
        case "parsing", "parsing_gb":
            return DoOneDownload_parsing()
        case "comm":
            return DoOneDownload_comm()
        case "comm_gb":
            return DoOneDownload_comm()
        case "cbol_dict", "cbol_dict_gb":
            return DoOneDownload_cbol_dict()
        case "unv":
            return DoOneDownload_bible_little()
        case "unv_gb":
            return DoOneDownload_bible_gb_little()
        case "kjv":
            return DoOneDownload_bible_kjv()
        default:
            break
        }
        return DoOneDownload_bible_tp2(ver)
    }
    func do_delete_bible(_ ver:String){
        let isSn = ["unv","unv_gb","kjv"].ijnAny({$0==ver})
        var na: String? = nil
        if ver == "comm" || ver == "comm_gb"{
            if ManagerLangSet.s.curIsGb{
                DoDeleteBibleBase("/unzip/bible_gb_comm.db", "/download/bible_gb_comm.zip", "/offline/comm_gb.db", nil).main()
            } else {
                DoDeleteBibleBase("/unzip/bible_comm.db", "/download/bible_comm.zip", "/offline/comm.db", nil).main()
            }
            return
        }
        else if ver == "unv"{
            na = "bible_little"
        } else if ver == "unv_gb"{
            na = "bible_gb_little"
        }
        
        DoDeleteBible(ver: ver, isSn: isSn, strSpecialName: na).main()
    }
    class DoDeleteBibleBase : NSObject {
        /// strSpecialName: 以 unv 為例，它是 bible_little 而不是 unv
        /// unzip: /unzip/bible_comm.db
        /// offline: /offline/comm.db
        /// offlineSn: /offline/sn_comm.db
        /// download: /download/bible_comm.zip
        init(_ unzip:String,_ download:String,_ offline:String,_ offlineSn:String?){
            super.init()
            
            let unzip = fm.getPathAtDocumentUserDomain(pathRelative: unzip)
            let zip = fm.getPathAtDocumentUserDomain(pathRelative: download)
            let db1 = fm.getPathAtDocumentUserDomain(pathRelative: offline)
            urls.append(unzip)
            urls.append(zip)
            urls.append(db1)
            if offlineSn != nil {
                let db2 = fm.getPathAtDocumentUserDomain(pathRelative: offlineSn!)
                urls.append(db2)
            }
        }
        func main(){
            forLoopDeleteFile(self.urls)
        }
        fileprivate var urls:[URL] = []
        fileprivate lazy var fm = FileManager.default
        fileprivate func forLoopDeleteFile(_ urls:[URL]){
            do {
                for a1 in urls{
                    if fm.fileExists(atPath: a1.path){
                        try fm.removeItem(at: a1)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    class DoDeleteBible : DoDeleteBibleBase {
        /// strSpecialName: 以 unv 為例，它是 bible_little 而不是 unv
        init(ver:String,isSn:Bool,strSpecialName:String?=nil){
            
            let na1 = strSpecialName == nil ? "bible_\(ver)" : strSpecialName!
            let sn:String? = isSn ? "/offline/sn_\(ver).db" : nil
            super.init("/unzip/\(na1).db", "/download/\(na1).zip", "/offline/\(ver).db", sn)
        }
    }
    /// 為何稱為 do 而非 download
    /// 因為，它 download 完，還會 unzip，還會正規化
    /// 也會自動判定，之前已經 download 完，但還沒有 unzip 與 正規化
    func do_one_bible(_ ver:String){
        download_bible[ver] = gDownloadBible(ver)
        let download = download_bible[ver]!
        download.onProcessing$.clearCallback()
        download.onProcessing$.addCallback { sender, pData in
            // self._ovTitle2Data[0] = pData!.percent.description
            let msg = "下載中 \(pData!.totalBytesWritten/1024/1024)/\(pData!.totalBytesExpectedToWrite/1024/1024)mb \(String(format: "%.1f%%", pData!.percent * 100))"
            let r1 = from( self.row2version ).firstOrNil({$0.value==ver})
            if r1 != nil {
                self._ovTitle2Data[r1!.key] = msg
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            }
        }
        download.onFinished$.addCallback { sender, pData in
            print("offline \(ver) ready.")
            self.reloadStatesUsingCheckingFile()
            self.updateTitle2DataAndColorFromStates()
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
        }
        download.mainAsync()
    }
}

class CheckInitialState : NSObject {
    
    private func pathFile(_ name:String)->URL{
        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: name)
    }
    private func fileEixst(_ path:String)->Bool{
        return FileManager.default.fileExists(atPath: path)
    }
    private func fileSize(_ path:String)->Int64{
        let r1 = FileManager.default.sizeOfFile(atPath: path)
        return r1 != nil ? r1! : 0
    }
    private func fileDate(_ path:String)->Date? {
        let r1 = FileManager.default.dateOfLastModified(atPath: path)
        return r1
    }
    var ver2Date: [String:Date?]!
    /// ver2Date 是最後日期
    func main(ver :String,ver2Date:[String:Date?])->DownloadState{
        self.ver2Date = ver2Date
        
        if ver == "comm" || ver == "comm_gb" {
            if ManagerLangSet.s.curIsGb {
                return mainCore("/offline/comm_gb.db", "/download/bible_gb_comm.zip", "comm_gb", nil)
            } else {
                return mainCore("/offline/comm.db", "/download/bible_comm.zip", "comm", nil)
            }
        } else if ver == "parsing" || ver == "parsing_gb" {
            if ManagerLangSet.s.curIsGb {
                return mainCore("/offline/parsing_gb.db", "/download/bible_gb_parsing.zip", "parsing_gb", nil)
            } else {
                return mainCore("/offline/parsing.db", "/download/bible_parsing.zip", "parsing", nil)
            }
        } else if ver == "cbol_dict" || ver == "cbol_dict_gb" {
            if ManagerLangSet.s.curIsGb {
                return mainCore("/offline/cbol_dict_gb.db", "/download/bible_gb_little.zip", "cbol_dict_gb", nil)
            } else {
                return mainCore("/offline/cbol_dict.db", "/download/bible_little.zip", "cbol_dict", nil)
            }
        } else if ver == "unv"{
            return mainUnv(ver)
        } else if ver == "unv_gb"{
            return mainCore("/offline/unv_gb.db",
                            "/download/bible_gb_little.zip",
                            ver,
                            "/offline/sn_unv_gb.db")
        } else if ver == "kjv" {
            return mainCore("/offline/kjv.db",
                            "/download/kjv.zip",
                            ver,
                            "/offline/sn_kjv.db")
        } else if ["asv","darby","bbe","erv","web"].ijnAny({$0==ver}) {
            return mainCoreEngs(ver)
        } else if ver == "cbol" {
            return mainCoreEngs(ver)
        }
        
        return mainCoreEngs(ver)
        // return DownloadState(state: .cantDownload)
    }
    private func mainUnv(_ ver:String)->DownloadState{
        return mainCore("/offline/unv.db",
                        "/download/bible_little.zip",
                        ver,
                        "/offline/sn_unv.db")
    }
    private func mainCore(_ pathOffline:String,
                          _ pathDownload:String,
                          _ ver:String,
                          _ pathSn:String?)->DownloadState{
        
        let r1 = pathFile(pathOffline)
        if fileEixst(r1.path){
            // 存在。 inUse or readyUpdate
            let sz = fileSize(r1.path)
            let sz2 = pathSn == nil ? 0 : fileSize(pathFile(pathSn!).path)
            
            let dateFile = fileDate(r1.path)
            let dateWeb = self.ver2Date[ver]
            
            if dateWeb != nil && dateFile != nil && dateWeb!! > dateFile! {
                // 需更新
                let result = DownloadState(state: .readyUpdate, sizeFile: sz+sz2)
                result.dateFile = dateFile!
                result.dateLast = dateWeb!
                return result
            }
            return DownloadState(state: .inUse, sizeFile: sz+sz2)
        }
        
        let r2 = pathFile(pathDownload)
        if fileEixst(r2.path){
            return DownloadState(state: .readyUnzipNormalize)
        } else {
            return DownloadState(state: .noDownload)
        }
    }
    /// `只要符合 沒sn 下載是 bible_xxxx.zip 即可`
    /// 原本是英文版(kjv除外),  後來 cbol 也符合
    private func mainCoreEngs(_ ver:String)->DownloadState{
        return mainCore("/offline/\(ver).db",
                        "/download/bible_\(ver).zip",
                        ver,
                        nil)
    }
    class DownloadState : NSObject {
        enum StateList {
            case inUse;
            case readyUpdate;
            case readyUnzipNormalize;
            case noDownload;
            case cantDownload;
            case downloading;
        }
        var state: StateList = .cantDownload
        var sizeFile: Int64 = 0
        var dateLast: Date?
        var dateFile: Date?
        lazy var format = DateFormatter()
        func toString()->String{
            format.dateFormat = "yyyy-MM-dd"
            switch state {
            case .cantDownload:
                return "未開放權限下載."
            case .noDownload:
                return "未下載."
            case .readyUpdate:
                if sizeFile > 1024*1024 {
                    return "需更新. 最新日期:\(format.string(from: dateLast!)) 你的檔案:\(format.string(from: dateFile!)) 佔 \(sizeFile/1024/1024) mb."
                } else if sizeFile > 1024 {
                    return "需更新. 最新日期:\(format.string(from: dateLast!)) 你的檔案:\(format.string(from: dateFile!)) 佔 \(sizeFile/1024) kb."
                } else {
                    return "需更新. 最新日期:\(format.string(from: dateLast!)) 你的檔案:\(format.string(from: dateFile!)) 佔 \(sizeFile) b."
                }
            case .inUse:
                if sizeFile > 1024*1024 {
                    return "使用中 佔\(sizeFile/1024/1024) mb."
                } else if sizeFile > 1024 {
                    return "使用中 佔\(sizeFile/1024) kb."
                } else {
                    return "使用中 佔\(sizeFile) b."
                }
            case .readyUnzipNormalize:
                return "待處理."
            case .downloading:
                return "下載中."
            }
        }
        func toColor()->UIColor {
            if state == .cantDownload || state == .inUse {
                return .label
            } else if state == .readyUpdate {
                return .systemRed
            }
            return .systemBlue
        }
        
        init(state:StateList,sizeFile:Int64=0){
            self.state = state
            self.sizeFile = sizeFile
        }
    }
}
