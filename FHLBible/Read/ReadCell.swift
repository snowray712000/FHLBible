//
//  ReadCell.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/22.
//

import Foundation

import UIKit

class ReadCell : UITableViewCell {
    static let cellid = "readcell"
    /// call on viewLoad
    static func registerCell(_ tv: UITableView){
        if ( tv.dequeueReusableCell(withIdentifier: cellid) == nil ){
            tv.register(ReadCell.self, forCellReuseIdentifier: cellid)
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: ReadCell.cellid)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
