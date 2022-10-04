//
//  MyButtonForDownload.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation
import UIKit

// 要給 MyButtonForDownload 用。
protocol IUpdatorTool {
    func isNeedUpdate(_ data: DDownloadListFile) -> Bool
}
// 要給 UpdatorTool 用。
protocol IGetZipPathTool {
    func getZipPath(cname:String) -> URL?
}
protocol IGetLastModifiedTime {
    func getLastModifiedTime(cname:String) -> Date
}

class GetZipPathToolTest : IGetZipPathTool {
    func getZipPath(cname: String) -> URL? {
        return BiblePath.default.getZipPath("asv")
    }
}
class UpdatorTool : IUpdatorTool {
    static var `default` = UpdatorTool()
    typealias Tp = DDownloadListFile

    func isNeedUpdate(_ data: Tp) -> Bool {
        guard let path = getFilePath(data) else { return true }
        
        return getLastModifedOnServer() > getPathLastModifiedTime(path)
    }
    private func getFilePath(_ data: Tp) -> URL? {
        let pathG : IGetZipPathTool = GetZipPathToolTest ()
        return pathG.getZipPath(cname: data.cname)
    }
    private func getPathLastModifiedTime(_ path: URL) -> Date {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path.path)
            return attr[FileAttributeKey.modificationDate] as! Date
        } catch {
            return Date.init(timeIntervalSince1970: 0)
        }
    }
    private func getLastModifedOnServer() -> Date {
        // abort()
        ijnPrintNotImplentYet()
        return Date(2024,1,1)
    }
}
class MyButtonForDownload : UIButton{
    var data : DDownloadListFile? = nil
    var iupdatortool : IUpdatorTool = UpdatorTool.default
    
    var indexPath : IndexPath? = nil // 為了要使用 reloadRows
    var tv : UITableView? = nil // 為了要使用 reloadRows
    var cell : UITableViewCell? = nil
    
    var actionPre : UIAction? = nil
    func setAction(_ action: UIAction,_ ev: UIControl.Event){
        if actionPre != nil {
            self.removeAction(actionPre!, for: .allEvents)
        }
        self.addAction(action, for: ev)
        self.actionPre = action
    }
    public func fnDoWhenParentCellChanged(
        _ data: DDownloadListFile?,
        _ cell: UITableViewCell,
        _ indexPath: IndexPath){
        
        self.data = data
        self.indexPath = indexPath
        self.cell = cell
        
        updateTitleViaFlag()
        updateVisibleViaFlag()
    }
    private func updateTitleViaFlag(){
        guard let data = self.data else { return }
        
        var r1 = "下載"
        if data.flag == 1 && iupdatortool.isNeedUpdate(data) {
            r1 = "更新"
        } else if data.flag == 1 {
            r1 = "完成"
        }
        setTitle(r1, for: .normal)
    }
    private func updateVisibleViaFlag(){
        guard let data = self.data else { return }
        isHidden = !(data.flag == 0 || data.flag == 1)
    }
    static func initWhenCellNeed(_ cell: UIView,_ tv: UITableView) -> MyButtonForDownload {
        let btn = MyButtonForDownload()
        btn.tv = tv
        
        btn.setTitle("下載", for: .normal)
        btn.setTitleColor(.darkText, for: .normal)
        btn.layer.cornerRadius = 5.0
        btn.layer.borderWidth = 1.0
        
        btn.tag = 1
        cell.addSubview(btn)
        let v = btn ; let pv = cell ;
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.centerYAnchor.constraint(equalTo: pv.centerYAnchor),
            v.rightAnchor.constraint(equalTo: pv.rightAnchor, constant: -10),
        ])
        
        btn.setAction(UIAction(handler: { action in
            let s1 = action.sender as! MyButtonForDownload
            
            if let data = s1.data {
                // 未下載，已下載，共用此 action
                if data.flag == 0 {
                    // 按下，下載。
                    data.flag = 2 // 下載中
                    s1.tv!.reloadRows(at: [s1.indexPath!], with: .automatic)
                } else if data.flag == 1 {
                    // 按下，更新。
                }
            }
            
        }), .touchUpInside)
        
        return btn
    }
}
