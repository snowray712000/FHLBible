//
//  ReadTableViewController.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/22.
//

import Foundation
import UIKit
protocol IReadDataGettor {
    /// 當 page 切換章的時候，總會呼叫它的 viewDidLoad
    /// 羅4:23
    func doWhenDidViewLoad(_ strAddress: String)
    /// 當多個版本，且，是平行對照的時候，就需要了。
    func geWhenCellForRowAt(_ idxPath: IndexPath) -> [DOneLine]
}
class ReadDataGettorTest1a : IReadDataGettor{
    func doWhenDidViewLoad(_ strAddress: String) {
        
    }
    
    func geWhenCellForRowAt(_ idxPath: IndexPath) -> [DOneLine] {
        let r1 = "耶穌基督的僕人保羅，奉召為使徒，特派傳　神的福音。"
        let r2 = DText()
        r2.w = r1
        let r3 = DOneLine()
        r3.children = [r2]
        r3.ver = "和合本"
        return [r3]
    }
}
class ReadTableViewController : UITableViewController {
    var daG : IReadDataGettor {
        return ReadDataGettorTest1a()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ReadCell.registerCell(self.tableView)
        
        daG.doWhenDidViewLoad("羅5:1")
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadCell.cellid, for: indexPath) as! ReadCell
        
        _ = daG.geWhenCellForRowAt(indexPath)
        
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}
