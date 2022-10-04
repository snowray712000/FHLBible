//
//  VCNews.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//

import UIKit
/// VCFutures 與 VCBugs 只有資料是不一樣，也就是 url 不一樣而已，重構
/// 願本開發的是 Futures
/// VCFutures 、 VCBugs 已經不再使用，因為直接在 support urls 裡就有了
class VCIosBase<T: DIosBase> : VCOptionListViaTableViewControllerBase {
    var _ovUrl: String { "https://bkbible.fhl.net/NUI/ios/ios-futures.json" }
    /// https://bible.fhl.net/NUI/ios/ 供 sub class 使用
    var _urlPrefix: String {"https://bible.fhl.net/NUI/ios/"}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let r2 = JsonFileGetter<T>()
        r2.onComplete$.addCallback { sender, pData in
            let r1 = sender!._data!
            
            self._dataFutures = r1._items!.map({($0.na!,$0.na2!)})
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        r2.onError$.addCallback { sender, pData in
            let r1 = sender!._msgError!
            print (r1)
        }
        
        let r1 = _ovUrl
        r2.mainAsync(r1)
    }
    
    override var _ovTitle1: [String] { _dataFutures.count == 0 ? [NSLocalizedString("取得資料中...", comment: "")] : _dataFutures.map({$0.0}) }
    override var _ovTitle2: [String]? { _dataFutures.count == 0 ? [] : _dataFutures.map({$0.1}) }
    
    var _dataFutures: [(String,String)] = []
}

/// Json file ， 原本是  DIosFutures ， 但重構出共同的地方
class DIosBase : NSObject, Decodable {
    fileprivate enum CodingKeys: String, CodingKey {
        case item
    }
    required init(from decoder: Decoder) throws {
        let de = try decoder.container(keyedBy: CodingKeys.self)
        _items = try de.decode( [DDetail].self , forKey: .item)
    }
    
    var _items: [DDetail]?
    class DDetail : Decodable {
        var na: String?
        var na2: String?
    }
}
