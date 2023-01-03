//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
public class FHLZipFileDownloador_FinishEventObject {
    /// 例如 bible_little.zip
    var name_zip :String!
    /// /download/bible_little.zip
    /// 可用於 unzipItem
    var path_zip :URL!
    /// 若有值，表示沒有成功下載
    /// 最常見就是 moveItem 過程出錯
    var msg_error:String?
}

public class FHLZipFileDownloador_ProcessingBarEventObject{
    var totalBytesWritten:Int64!
    var totalBytesExpectedToWrite:Int64!
    var percent: Float {
        get {
            return Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) ;
        }
    }
    init(totalBytesWritten:Int64,totalBytesExpectedToWrite:Int64){
        self.totalBytesWritten = totalBytesWritten
        self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
    }
}
typealias IjnEvent_ProcessingBar = IjnEvent<Any,FHLZipFileDownloador_ProcessingBarEventObject>
typealias IjnEvent_Finished = IjnEventOnce<Any,FHLZipFileDownloador_FinishEventObject>
class FHLZipFileDownloador : NSObject , URLSessionDownloadDelegate {
    var onFinished$: IjnEvent_Finished = IjnEvent_Finished()
    var onProcessingBar$: IjnEvent_ProcessingBar = IjnEvent_ProcessingBar()
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let result = FHLZipFileDownloador_FinishEventObject()
        do {
            let fm = FileManager.default
            let dir1 = fm.makeSureDirExistAtDocumentUserDomain(dirName: "download")
            let path1 = dir1.appendingPathComponent("/\(downloadTask.response!.suggestedFilename!)")
                        
            result.name_zip = downloadTask.response!.suggestedFilename
            result.path_zip = path1

            try fm.moveItem(at: location, to: path1)
        }catch{
            result.msg_error = error.localizedDescription
            print(error.localizedDescription)
        }
        
        session.finishTasksAndInvalidate() // 要下這行，才能把這個 unv backgroundsession 拿掉，不然下次再按一次 unv 下載會失敗
        self.onFinished$.triggerAndCleanCallback(self, result)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        onProcessingBar$.trigger(self, FHLZipFileDownloador_ProcessingBarEventObject(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite))
        
        //let r1 = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) ;
        //print(r1)
    }
    
    
}
