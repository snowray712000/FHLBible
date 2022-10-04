//
//  JobFlag2Starter.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation

class JobFlag2Starter : NSObject, URLSessionDownloadDelegate, ObDownloadGetter {
    func getObProgress() -> IjnObservableObject<(Int64, Int64)> {
        return obProgress
    }
    
    func getObIsComplete() -> IjnObservableObject<Bool> {
        return obIsComplete
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // FileManager.default.fileExists(atPath: pathSave.absoluteString) 會判斷成 false
        if FileManager.default.fileExists(atPath: pathSave.path) {
            // 若已經存在檔案， moveItem 會錯誤
            try! FileManager.default.removeItem(at: pathSave)
        }
        try! FileManager.default.moveItem(at: location, to: pathSave)
        obIsComplete.value = true
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        obProgress.value = (totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    init(_ linkFtp: URL,_ pathSave: URL){
        self.linkftp = linkFtp
        self.pathSave = pathSave
        obProgress = IjnObservableObject((0,Int64.max)) // 隨便初始化，在事件中，會再設值
        // super init () 前要 init 變數，所以下面2行雖沒用，但為了 complie 過
        // 但 delegate 又要用 self 這個參數，要用 self 要先用 super.init()。
        session = URLSession.shared
        taskDownload = session.downloadTask(with: URL(string: "https://127.0.0.1/")!)
        super.init()
        
        self.session = URLSession(
            configuration: .default,
            delegate: self, delegateQueue: nil)
        self.taskDownload = session.downloadTask(with: linkFtp)
    }
    public func startAsync(){
        taskDownload.resume()
    }
    private var linkftp : URL
    private var pathSave : URL
    private var session : URLSession
    private var taskDownload : URLSessionDownloadTask
    private var obProgress : IjnObservableObject<(Int64,Int64)>
    private var obIsComplete = IjnObservableObject(false)
    
}
