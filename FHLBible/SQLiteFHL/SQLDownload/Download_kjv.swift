//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation

class Download_kjv : Download_Base {
    /// 可能是 lcc 或 lcc_gb
    override var idOfSession: String { get { return "kjv" }}
}
class Download_Base : NSObject,IDownload {
    /// override
    /// 可能是 lcc 或 lcc_gb
    var idOfSession: String { get { return "kjv" }}
    var linkFromDownload: String { get {
        let r1 = idOfSession
        if r1.substring_end(count: 3) == "_gb" {
            return "https://ftp.fhl.net/FHL/COBS/data/bible_gb_\(r1.substring(offsetFromEnd: -3)).zip"
        }
        return "https://ftp.fhl.net/FHL/COBS/data/bible_\(r1).zip"
    }}
    
    func mainAsync() {
        downloading()
    }
    
    private lazy var url = self.linkFromDownload
    private lazy var conf = URLSessionConfiguration.background(withIdentifier: self.idOfSession)
    private var downloadDelegate = FHLZipFileDownloador()
    var onProcessing$: IjnEvent_ProcessingBar {
        get { self.downloadDelegate.onProcessingBar$ }
    }
    var onFinished$: IjnEvent_Finished {
        get { self.downloadDelegate.onFinished$ }
    }
    private var downloadTask: URLSessionDownloadTask!
    private var session: URLSession!

    private func downloading(){
        self.session = URLSession(configuration: conf,
                                 delegate: self.downloadDelegate,delegateQueue: nil)
        downloadTask = session.downloadTask(with: URL(string: url)!)
        downloadTask.resume()
    }
}


// 已重構 重複程式碼
//fileprivate class Download_kjvOld: NSObject, IDownload{
//    func mainAsync() {
//        downloading()
//    }
//
//    private var url = UrlsOfBibleFromFHL.s.kjv
//    private var conf = URLSessionConfiguration.background(withIdentifier: "kjv")
//    private var downloadDelegate = FHLZipFileDownloador()
//    var onProcessing$: IjnEvent_ProcessingBar {
//        get { self.downloadDelegate.onProcessingBar$ }
//    }
//    var onFinished$: IjnEvent_Finished {
//        get { self.downloadDelegate.onFinished$ }
//    }
//    private var downloadTask: URLSessionDownloadTask!
//    private var session: URLSession!
//
//    private func downloading(){
//        self.session = URLSession(configuration: conf,
//                                 delegate: self.downloadDelegate,delegateQueue: nil)
//        downloadTask = session.downloadTask(with: URL(string: url)!)
//        downloadTask.resume()
//    }
//}
