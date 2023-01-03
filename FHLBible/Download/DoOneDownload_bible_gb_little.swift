//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation

extension VCData {
    class DoOneDownload_bible_gb_little : DoOneDownload_bible_little {
        override init(){
            super.init()
            pathOffline = "/offline/unv_gb.db"
            pathOfflineSn = "/offline/sn_unv_gb.db"
            pathUnzip = "/unzip/bible_gb_little.db"
            pathDownload = "/download/bible_gb_little.zip"
        }
        override func fnNormalize(){
            SQLNormalize_unv_gb().main()
            SQLNormalize_sn_unv_gb().main()
        }
        override func generateDownload()->IDownload{
            return Download_unv_gb()
        }
    }
}
