//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation

extension VCData {
    
    class DoOneDownload_bible_little : NSObject{
        var pathOffline = "/offline/unv.db"
        var pathOfflineSn: String?
        var pathUnzip = "/unzip/bible_little.db"
        var pathDownload = "/download/bible_little.zip"
        var downloader: IDownload?
        
        override init(){
            pathOfflineSn = "/offline/sn_unv.db"
        }
        
        private func fnExist(_ path:String)->Bool{
            let pathfull = FileManager.default.getPathAtDocumentUserDomain(pathRelative: path)
            return FileManager.default.fileExists(atPath: pathfull.path)
        }
        private func fnUnzip(){
            Unzipor().main(pathZip: FileManager.default.getPathAtDocumentUserDomain(pathRelative: pathDownload))
        }
        private func fnDeleteIfExists(_ path:String){
            do{
                let url = FileManager.default.getPathAtDocumentUserDomain(pathRelative: path)
                if FileManager.default.fileExists(atPath: url.path){
                    try FileManager.default.removeItem(at: url)
                }
                
            }catch{
                print(error.localizedDescription)
            }
        }
        func fnNormalize(){
            SQLNormalize_unv().main()
            SQLNormalize_sn_unv().main()
        }
        /// 原來是 Sync 但 CBOL Dict 正規化，需要非同步
        func fnNormalizeAsync(_ fn:()->Void){
            fnNormalize();
            fn();
        }
        func generateDownload()->IDownload{
            return Download_unv()
        }
        /// 可用作更新 下載 進度列
        var onProcessing$ = IjnEvent_ProcessingBar()
        /// 可用作更新 ui 文字
        var onFinished$ = IjnEvent_Finished()
        func deleteUnzipAndDownload(){
            fnDeleteIfExists(pathUnzip)
            fnDeleteIfExists(pathDownload)
        }
        func isReadyOffline()->Bool{
            if pathOfflineSn == nil {
                return fnExist(pathOffline)
            }
            return fnExist(pathOffline) && fnExist(pathOfflineSn!)
        }
        func mainAsync(){
            
            if isReadyOffline(){
                onFinished$.triggerAndCleanCallback(nil, nil)
            } else {
                if fnExist(pathUnzip){
                    // already unzip , but 還沒 normalize
                    fnNormalizeAsync {
                        self.deleteUnzipAndDownload()
                        onFinished$.triggerAndCleanCallback(nil, nil)
                    }
                } else {
                    if fnExist(pathDownload){
                        // already download, but 還沒 unzip
                        fnUnzip()
                        fnNormalizeAsync {
                            self.deleteUnzipAndDownload()
                            onFinished$.triggerAndCleanCallback(nil, nil)
                        }
                    } else {
                        // 還沒作任何事, 從 download 開始吧
                        if downloader == nil {
                            downloader = generateDownload()
                            downloader!.onProcessing$.addCallback {
                                self.onProcessing$.trigger(self, $1)
                            }
                            downloader!.onFinished$.addCallback({sender,pData in
                                self.fnUnzip()
                                self.fnNormalizeAsync {
                                    self.deleteUnzipAndDownload()
                                    
                                    self.downloader!.onProcessing$.clearCallback()
                                    self.onProcessing$.clearCallback()
                                    
                                    self.onFinished$.triggerAndCleanCallback(self, pData)
                                }
                            })
                            
                            downloader!.mainAsync()
                        }
                    }
                }
            }
        }
    }
}
