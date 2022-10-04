//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation
/// 為了 FhlJson 而存在
open class FhlJsonResult : NSObject, Decodable {
    /// 供 init(from decoder: Decoder) 用的
    private enum CodingKeys: String, CodingKey { case status }
    
    /// required 這字眼，是因為在用樣版 T1時，T1() 會 compiler error
    public required init(_ status: String="") {
        self.status = status
    }
    public required init(from decoder: Decoder) throws {
        let re = try decoder.container(keyedBy: CodingKeys.self)
        status = try re.decode(String.self, forKey: .status)
        // try super.init(decoder: decoder)
    }
    /// success, 可用 isSuccess ( )
    public var status: String
    public func isSuccess () -> Bool { return status == "success" }
}/// 將複雜的 Swift Post Json 簡化
public class FhlJson<T1:FhlJsonResult>{
    public typealias FnCallback = (_ data: T1) -> Void
    private var fn: FnCallback?
    private var url: String?
    private var param: String?
    
    /// 之所以不用 get 而用 post，是因為 qsb 的 qstr 有很長的可能
    /// url 在用的時候，要注意 https 才會可以被 xcode 專案使用
    public func postAsync(_ fn: @escaping FnCallback, _ url: String,_ param: String = "") {
        
        self.fn = fn
        self.url = url
        self.param = param
        
        let task = URLSession.shared.dataTask(with: generateRequest(), completionHandler: callbackCore)
        task.resume()
    }
    private func generateRequest()->URLRequest {
        
        let url = self.url != nil ? self.url! : "https://bible.fhl.net/json/uiabv.php"
        let param = self.param != nil ? self.param! : ""
        
        var req = URLRequest(url: URL(string: url)!, cachePolicy: .reloadIgnoringLocalCacheData)
        
        let data = param.data(using: .utf8)!
        req.httpMethod = "POST"
        req.httpBody = data
        
        return req
        
    }
    private func callbackCore(data: Data?, resp:URLResponse?, er:Error?){
        guard let fn = self.fn else { return }
        
        if let data = data {
            do {
                let de = JSONDecoder()
                let jo = try de.decode(T1.self, from: data)
                fn(jo) // case normal
            } catch {
                // 這個 error 是 try-catch 的, 大概是 json 轉換過程為主的 error
                let msg = "exception:  \(error.localizedDescription)"
                fn( T1(msg) ) // case error 1
            }
        } else {
            // 這個 error 是 dataTask 的, 大概是 網路設定或網路參數異常造成的.
            let msg = er != nil ? "dataTask Error:  \(er.debugDescription)" : "dataTask Error."
            fn(T1(msg))
            
        }
    }
}
