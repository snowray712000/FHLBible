//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation
import IJNSwift

extension VCData {
    class DoOneDownload_bible_kjv : DoOneDownload_bible_little {
        override init(){
            super.init()
            pathOffline = "/offline/kjv.db"
            pathOfflineSn = "/offline/sn_kjv.db"
            pathUnzip = "/unzip/bible_kjv.db"
            pathDownload = "/download/bible_kjv.zip"
        }
        override func fnNormalize(){
            SQLNormalize_kjv().main()
            SQLNormalize_sn_kjv().main()
        }
        override func generateDownload()->IDownload{
            return Download_kjv()
        }
    }
}
extension VCData {
    /// `重構味道` override var ver:string {get {return "asv"} }
    ///  tp2, 因為 tp1 就是 bible_little
    class DoOneDownload_bible_tp2 : DoOneDownload_bible_little{
        init(_ ver:String){
            /// ver 會是 lcc 或 lcc_gb ( 但 unzip之後 不論是不是 gb 都是 bible_lcc.db 而非 bible_lcc_gb.zip)
            self.ver = ver
            super.init()
            
            if ver.substring_end(count: 3) == "_gb" {
                let verNoGb = ver.substring(offsetFromEnd: -3) // lcc_gb 變 lcc
                pathOffline = "/offline/\(ver).db"
                pathUnzip = "/unzip/bible_\(verNoGb).db"
                pathDownload = "/download/bible_gb_\(verNoGb).zip"
            } else {
                pathOffline = "/offline/\(ver).db"
                pathUnzip = "/unzip/bible_\(ver).db"
                pathDownload = "/download/bible_\(ver).zip"
            }
            
            
//            pathOffline = "/offline/asv.db"
//            pathUnzip = "/unzip/bible_asv.db"
//            pathDownload = "/download/bible_asv.zip"
        }
        private var ver:String
        /// 因為 extract 了 SQLNormalizeBase_tp2，所以大部分應該不用過載這個了
        override func fnNormalize(){
            SQLNormalizeBase_tp2(ver).main()
        }
        /// 因為 extract 了 Download_Base_tp2，所以大部分應該不用過載這個了
        override func generateDownload()->IDownload{
            return Download_Base_tp2(ver)
        }

    }
}
extension VCData {
    // esv 無法 offline ， 版權問題
//    class DoOneDownload_bible_esv : DoOneDownload_bible_little {
//        override init(){
//            super.init()
//            r1 = "/offline/esv.db"
//            r2 = "/unzip/bible_esv.db"
//            r3 = "/download/bible_esv.zip"
//        }
//        override func fnNormalize(){
//            SQLNormalize_web().main()
//        }
//        override func generateDownload()->IDownload{
//            return Download_web()
//        }
//    }
}
