//
//  ViewParsingDict.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import Foundation
import UIKit

@IBDesignable
class ViewParsingDict : ViewFromXibBase, UITableViewDataSource {
    override var nibName: String {"ViewParsingDict"}
    func set(_ datas: [OneData],_ isSnVisible: Bool){
        _data = datas
        self._isSnVisible = isSnVisible
        
        viewTable.reloadData()    
    }
    
    @IBOutlet var viewTable: UITableView!
    var _data: [OneData] = []
    var _isSnVisible: Bool = true
    override func initedFromXib() {
        viewTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        viewTable.dataSource = self
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if cell.contentView.subviews.count == 0 {
            let r1 = gCell()
            cell.contentView.addSubview(r1)
            r1.add4ConstrainsWithSuperView()
            
        }
        
        let r1 = cell.contentView.subviews.first! as! ViewSNDictCell
        let r2 = _data[indexPath.row]
        r1.set(r2.sn, r2.word, r2.orig, wform: r2.wform, exp: r2.exp, remark: r2.remark)
        
        return cell
    }
    private func gCell ()-> ViewSNDictCell {
        let r1 = ViewSNDictCell()
        return r1
    }
    
    class OneData {
        var sn: DText = DText()
        var word: DText = DText()
        var orig: DText = DText ()
        var wform: [DText] = []
        var exp: [DText] = []
        var remark: [DText] = []
    }
    var testData1: [OneData] {
        return []
    }
}
