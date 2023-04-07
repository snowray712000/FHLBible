//
//  DApiAu.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/7.
//

import Foundation
/// 有聲聖經用
/// 仿 qsb 作的
public func fhlAu(_ param: String,_ fn: @escaping FhlJson<DApiAu>.FnCallback) {
    fhlCore(param, "au", fn)
}

open class DApiAu : FhlJsonResult {
    private enum CodingKeys: String, CodingKey { case mp3 }
    required public init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        mp3 = try? container?.decode(String.self, forKey: .mp3)
        try super.init(from: decoder)
    }
    
    required public init(_ status: String = "") {       
        super.init(status)
    }
    public var mp3 : String?
}
/**
 有聲聖經的 api 產生的網址，不一定存在。例如只有新約的，但仍然能產生舊約，我就要先檢查它存在與否
@example:
let url = URL(string: "https://example.com/file.mp3")!
 checkIfUrlExists(at: url) { exists in
 if exists {
     print("The file exists!")
 } else {
     print("The file does not exist.")
 }
}
 */
func checkIfUrlExists(at url: URL, completion: @escaping (Bool) -> Void) {
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            completion(httpResponse.statusCode == 200)
        } else {
            completion(false)
        }
    }
    task.resume()
}
