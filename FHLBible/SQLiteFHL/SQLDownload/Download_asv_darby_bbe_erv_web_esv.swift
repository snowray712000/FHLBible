//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
/// `重構味道` 取代了下面那群
/// tp2 這名稱，是因為是先重構 DoOneDownload_bible_tp2；它們是成對的，所以也叫 tp2
class Download_Base_tp2 : Download_Base {
    init(_ ver: String){
        _ver = ver
        super.init()
    }
    private var _ver : String
    override var idOfSession: String { get { return _ver }}
}
