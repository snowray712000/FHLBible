//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
public class Download_unv_gb: NSObject, IDownload{
    private var url = UrlsOfBibleFromFHL.s.unv_gb
    private var conf = URLSessionConfiguration.background(withIdentifier: "unv_gb")
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
    
    func mainAsync(){
        downloading()
    }
}
