import Foundation
import UIKit

class VCSearching : UIViewController {
    @IBOutlet weak var viewSearching: UIView!
    var vMain: ViewSearching { viewSearching as! ViewSearching}
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vMain.onClickSearching$.addCallback { sender, pData in
            
            
            self.navigationController?.popViewController(animated:  false) // 先 pop 掉再 trigger，不然會 push 到第二層
            self.onClickSearching$.triggerAndCleanCallback(sender, pData)
        }
    }
    @IBAction func doCleanSearchHistory(){
        vMain.cleanSearchHistory()
    }
    var onClickSearching$: IjnEventOnce<UIView,DText> = IjnEventOnce()
}
