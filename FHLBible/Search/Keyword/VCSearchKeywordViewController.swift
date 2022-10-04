//
//  VCSearchKeywordViewController.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/24.
//

import UIKit

class VCSearchKeywordViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var historys: [DText] = [
        DText("摩西 長成"),
        DText("G2314", sn: "2314", tp: "G", tp2: "WTH"),
        DText("創1:3-5;2:3-4", refDescription: "創1:3-5;2:3-4", isInTitle: false)
    ]
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as UITableViewCell
        
        if indexPath.row < historys.count {
            cell.textLabel!.text = historys[indexPath.row].w ?? ""
        }
        
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
