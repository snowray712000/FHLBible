//
//  JsonFileGetter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//

import Foundation

/// 取得 ios-futures.json 這個檔案用的
/// 通常不需要傳參數的都可以用這個
class JsonFileGetter<T: Decodable> : NSObject {
    var onComplete$: IjnEventOnce<JsonFileGetter,Any> = IjnEventOnce()
    var onError$: IjnEventOnce<JsonFileGetter, Any> = IjnEventOnce()
    func mainAsync(_ url: String){
        /// url2 正確嗎
        let url2 = URL(string:url)
        if url2 == nil {
            _msgError = "url字串 無法成功轉換為 URL \(url)"
            onError$.triggerAndCleanCallback(self,nil)
            return
        }
        
        // 正式處理
        let req = URLRequest(url: url2!, cachePolicy: .reloadIgnoringLocalCacheData)
        URLCache.shared.removeCachedResponse(for: req)
        let r2 = URLSession.shared.dataTask(with: req ) { data, resp, er in
            if data != nil {
                do {
                    let de = JSONDecoder()
                    let jo = try de.decode(T.self, from: data!)
                    
                    self._data = jo
                    self.onComplete$.triggerAndCleanCallback(self, nil)
                } catch {
                    // 這個 error 是 try-catch 的, 大概是 json 轉換過程為主的 error
                    let msg = "exception:  \(error.localizedDescription)"
                    
                    self._msgError = msg
                    self.onError$.triggerAndCleanCallback(self, nil)
                }
            } else {
                // 這個 error 是 dataTask 的, 大概是 網路設定或網路參數異常造成的.
                let msg = er != nil ? "dataTask Error:  \(er.debugDescription)" : "dataTask Error."
                self._msgError = msg
                self.onError$.triggerAndCleanCallback(self, nil)
            }
        }
        r2.resume()
    }
    
    var _msgError: String?
    var _data: T?
}
