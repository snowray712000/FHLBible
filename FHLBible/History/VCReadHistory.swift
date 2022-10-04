//
//  VCReadHistory.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import UIKit

class VCReadHistory: UITableViewController {
    var onClickAddr$: IjnEventOnce<Any,String> = IjnEventOnce()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _data = ManagerHistoryOfRead.s.cur
        tableView.reloadData()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.onClickAddr$.triggerAndCleanCallback(nil, nil)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _data.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var r1 = cell.defaultContentConfiguration()
        let r = indexPath.row
        r1.text = "\(r+1). \(_data[indexPath.row])"
        cell.contentConfiguration = r1
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: false)
        onClickAddr$.triggerAndCleanCallback(nil, _data[indexPath.row])
    }
    fileprivate var _data: [String] = []
    /// 清空
    @IBAction func removeAllAndBack(){
        if _data.count != 0 {
            ManagerHistoryOfRead.s.updateCur([_data[0]])
            navigationController?.popViewController(animated: false)
        }
    }
}
