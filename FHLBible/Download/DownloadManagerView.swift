//
//  DownloadManagerView.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import Foundation
import UIKit

class DDownloadListFile {
    public var cname : String
    public var len : Int?  // 檔案大小，也有可能未知 (下載前、下載後也可以知)
    public var flag : Int  // 0 知道此檔 1 已下載 2 下載中 3 他人版權未開放下載
    public init() {
        flag = 0
        cname = ""
        len = 0
        pg = nil
    }
    public func set(_ na: String,_ len: Int? ,_ flag: Int){
        self.cname = na
        self.len = len
        self.flag = flag
    }
    public var pg : Progress? // 用於 flag = 2 時
}

protocol IDownloadListGetter {
    func getCountOfClassified() -> Int;
    func getCountOfFile(_ idClassified: Int) -> Int;
    func getTitleOfClassified(_ idClass: Int) -> String;
    func getItem(_ idClass: Int, _ idFile: Int) -> DDownloadListFile? ;
}

class BiblePath {
    static var `default` = BiblePath()
    
    init() {
        // 第2個 nil 就用 bible_asv.zip
        // 第3個 "" 表示沒有提供下載 nil 表示自動產生
        let r1 = [
            ["asv","bible_asv.zip","ftp://ftp.fhl.net/pub/FHL/COBS/data/bible_asv.zip"],
            ["bbe",nil,nil],
            ["bhs",nil,nil],
        ]
        
        // na2FtpPath
        for a1 in r1.map({($0[0]!, $0[2] != nil ? $0[2]! : "ftp://ftp.fhl.net/pub/FHL/COBS/data/bible_\($0[0]!).zip")}){
            if a1.1.count == 0 {
                na2FtpPath[a1.0] = nil // 不提供下載
            } else {
                na2FtpPath[a1.0] = URL(string: a1.1)!
            }
        }
        
        // na2ZipPath
        let download = try! FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        for a1 in r1.map({($0[0]!, $0[1] != nil ? $0[1]! : "bible_\($0[0]!).zip")})
            .map({($0.0, download.appendingPathComponent($0.1, isDirectory: false))})
        {
            na2ZipPath[a1.0] = a1.1
        }
        
    }
    
    func getZipPath(_ na:String) -> URL? {
        return na2ZipPath[na]!
    }
    
    var na2FtpPath : [ String : URL?] = [String:URL?]()
    var na2ZipPath : [ String : URL?] = [String:URL?]()
}
class DownloadListGetterTest : IDownloadListGetter {
    static var singleton = DownloadListGetterTest()
    
    var files : [(c:Int,f:Int,d:DDownloadListFile) ] = []
    func getItem(_ idClass: Int, _ idFile: Int) -> DDownloadListFile? {
        let r1 = files.ijnFirstOrDefault({$0.c == idClass && $0.f == idFile})
        if  r1 != nil { return r1!.d }
        
        let r2 = DDownloadListFile()
        r2.set("和合本_\(idClass)_\(idFile)",0,0)
        files.append((c:idClass,f:idFile,d:r2))
        return r2
    }
    
    var classes = ["中文聖經","中文(簡體)","英文","華語方言","非英語聖經","其它"]
    func getTitleOfClassified(_ idClass: Int) -> String {
        if idClass >= 0 && idClass < classes.count {
            return classes[idClass]
        }
        return classes.last!
    }
    
    func getCountOfFile(_ idClassified: Int) -> Int {
        return 3
    }
    
    func getCountOfClassified() -> Int {
        return classes.count
    }
    
    
    
    
}

class DownloadManagerView : UITableViewController{
    let cellid = "downloadcell"
    var downloadListGetter : IDownloadListGetter?
    var downloadListGetterMakeSure : IDownloadListGetter! {
        return downloadListGetter ?? DownloadListGetterTest.singleton
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ( tableView.dequeueReusableCell(withIdentifier: cellid) == nil ){
            tableView.register(DownloadManagerCell.self, forCellReuseIdentifier: cellid)
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return downloadListGetterMakeSure.getCountOfClassified()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadListGetterMakeSure.getCountOfFile(section)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellid, for: indexPath) as! DownloadManagerCell
        
        if let it = downloadListGetterMakeSure.getItem(indexPath.section, indexPath.row) {
            
            cell.textLabel?.text = it.cname
            
            cell.viewWithTag(1)?.isHidden = true
            cell.viewWithTag(3)?.isHidden = true
            if it.flag == 0 || it.flag == 1 {
                if cell.viewWithTag(1) == nil {
                    _ = MyButtonForDownload.initWhenCellNeed(cell,tableView)
                }
                
                let btn = cell.viewWithTag(1)! as! MyButtonForDownload
                btn.fnDoWhenParentCellChanged(it,cell,indexPath)
                
                cell.detailTextLabel?.text = "\(it.len != nil ? it.len! / 1024 : 0 ) mb"
                
            } else if it.flag == 2 {
                if cell.viewWithTag(3) == nil {
                    let pgv = UIProgressView()
                    pgv.tag = 3
                    
                    cell.addSubview(pgv)
                    let v = pgv ; let pv = cell ;
                    v.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        v.centerYAnchor.constraint(equalTo: pv.centerYAnchor),
                        v.rightAnchor.constraint(equalTo: pv.rightAnchor, constant: -10),
                        v.heightAnchor.constraint(equalToConstant: 20),
                        v.widthAnchor.constraint(equalToConstant: 20*1.618*2 )
                    ])
                }
                let pgv = cell.viewWithTag(3)! as! UIProgressView
                pgv.isHidden = false
                func onProgress(_ cur: (Int64,Int64)?, _ pre: (Int64,Int64)?){
                    guard let pg = it.pg else { return }
                    guard let cur = cur else { return }
                    pg.totalUnitCount = cur.1
                    pg.completedUnitCount = cur.0
                    
                    DispatchQueue.main.async {
                        cell.detailTextLabel?.text = "\(cur.0) / \(cur.1)"
                    }
                }
                func onComplete(_ cur: Bool?, _ pre: Bool? ){
                    guard let cur = cur else { return }
                    if cur == false { return }
                    
                    DispatchQueue.main.async {
                        it.flag = 1 // 已下載
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        it.pg = nil
                    }
                    
                    
                }
                if it.pg == nil {
                    it.pg = Progress()
                    it.pg!.totalUnitCount = 100
                    it.pg!.completedUnitCount = 0
                    let pathFile = try! FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("bible_asv.zip", isDirectory: false)
                    let jobflag2 = JobFlag2Starter(URL(string: "ftp://ftp.fhl.net/pub/FHL/COBS/data/bible_asv.zip")!, pathFile )
                    let obG : ObDownloadGetter = jobflag2
                    obG.getObProgress().addValueDidSetCallback(onProgress)
                    obG.getObIsComplete().addValueDidSetCallback(onComplete)
                    jobflag2.startAsync()
                }
                pgv.observedProgress = it.pg
            }
        }
       
        
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return downloadListGetterMakeSure.getTitleOfClassified(section)
    }
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return nil
//    }
}

class DownloadManagerCell : UITableViewCell{
    let cellid = "downloadcell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: cellid)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


