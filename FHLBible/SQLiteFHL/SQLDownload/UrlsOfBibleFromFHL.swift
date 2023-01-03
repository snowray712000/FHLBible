//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
class UrlsOfBibleFromFHL : NSObject {
    /// singleton pattern
    static let s = UrlsOfBibleFromFHL()
    /// self.session.downloadTask(with: URL(string: arg1)!) 會用到
    var unv = "https://ftp.fhl.net/FHL/COBS/data/bible_little.zip"
    var unv_gb = "https://ftp.fhl.net/FHL/COBS/data/bible_gb_little.zip"
    var unv_after_download = "/download/bible_little.zip"
    var unv_gb_after_download = "/download/bible_gb_little.zip"
    var unv_after_unzip = "unzip/bible_little.db"
    var unv_after_unzip_url:URL {get {return FileManager.default.getPathAtDocumentUserDomain(pathRelative: self.unv_after_unzip)}}
    var unv_gb_after_unzip = "unzip/bible_gb_little.db"
    var unv_gb_after_unzip_url:URL {get {return FileManager.default.getPathAtDocumentUserDomain(pathRelative: self.unv_gb_after_unzip)}}
    var kjv = "https://ftp.fhl.net/FHL/COBS/data/bible_kjv.zip"
}
