//
//  ViewSearchResult.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import UIKit


@IBDesignable
class ViewSearching : ViewFromXibBase, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var viewTable: UITableView!
    @IBOutlet weak var txtKeyword: UITextField!
    override var nibName: String { "ViewSearching" }
    var onClickSearching$: IjnEvent<UIView,DText> = IjnEvent()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        viewTable.delegate = self
        viewTable.dataSource = self
        
        // 按下 enter 後，能開始搜尋 https://stackoverflow.com/questions/26288124/how-do-i-get-the-return-key-to-perform-the-same-action-as-a-button-press-in-swif
        txtKeyword.delegate = self
    }
    /// // 按下 enter 後，能開始搜尋
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  //if desired
        doSearching()
        return true
    }
    /// VCSearching 會呼叫
    func cleanSearchHistory(){
        ManagerSearchHistory.s.updateCur([])
        viewTable.reloadData()
    }
    @IBAction func doSearching(){
        func upSetting(_ txt:String){
            var r1 = ManagerSearchHistory.s.cur
            let r2 = r1.firstIndex(of: txt)
            if r2 == nil {
                r1.insert(txt, at: 0)
            } else {
                r1.remove(at: r2!) // 交換到第1位置
                r1.insert(txt, at: 0)
            }
            ManagerSearchHistory.s.updateCur(r1)
        }
        
        if txtKeyword.text == nil || txtKeyword.text!.isEmpty {
            // onClickSearching$.trigger(self, nil) // 不觸發
        } else {
            // 更新
            upSetting(txtKeyword.text!)
            
            // 開始搜尋流程
            onClickSearching$.trigger(self, DText(txtKeyword.text!))
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let r1 = DText( self.datas[indexPath.row] )
        onClickSearching$.trigger(self, r1 )
    }
    var datas:[String] {
        ManagerSearchHistory.s.cur
    }
    //var datas: [String] = ["H430","H431","混沌 黑暗","awefweg","wegaweg","awefawe","1awfaweg\nawegaweg","waegawh"]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = datas[ indexPath.row ]
        return cell
    }
}
