//
//  VCOptionListViaTableViewControllerBase.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//

import Foundation
import UIKit

class VCHalfPresentBase : UITableViewController, UIViewControllerTransitioningDelegate {
    func presentMe(_ vc:UIViewController){
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        vc.present(self, animated: true, completion: nil)
    }
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = HalfPc(presentedViewController: presented, presenting: presenting)
        return pc
    }
    class HalfPc : UIPresentationController {
        var blackView: UIView!
        override func presentationTransitionWillBegin() {
            blackView = UIView()
            let r1 = containerView?.bounds
            if r1 != nil {
                blackView.frame = r1!
            }
            blackView.backgroundColor = .systemBackground.withAlphaComponent(0.5)
            containerView?.addSubview(blackView)
            
            let ges = UITapGestureRecognizer(target: self, action: #selector(clickForDismiss))
            blackView.addGestureRecognizer(ges)
        }
        @objc func clickForDismiss(){
            self.presentingViewController.dismiss(animated: true, completion: nil)
        }
        override var frameOfPresentedViewInContainerView: CGRect {
            let r1 = UIScreen.main.bounds
            let cy = r1.height / 2
            return CGRect(x: 0, y: r1.height - cy, width: r1.width, height: cy)
        }
        override func dismissalTransitionDidEnd(_ completed: Bool) {
            if completed {
                blackView.removeFromSuperview()
            }
        }
    }
}

/// 選單，是用 tablview 去作成的時候
class VCOptionListViaTableViewControllerBase : VCHalfPresentBase {
    var _ovTitle1 : [String] {["選項1","選項2","選項3","Cancel"]}
    var _ovTitle2 : [String]? {["","選項2-細說","",""]}
    var _ovColors : [UIColor]? { nil }
    var _ovImages : [UIImage?]? { nil }
    var _ovIsLastRedForCancel : Bool { false }
    var _onClickRow$: IjnEvent<Any,Int> = IjnEvent()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(DetailCell.self, forCellReuseIdentifier: "cell")
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _ovTitle1.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let r2 = _ovTitle1
        let r3 = _ovTitle2
        
        let i = indexPath.row
        var r1 = cell.defaultContentConfiguration()
        if i >= 0 && i < r2.count {
            r1.text = r2[i]
        }
        if r3 != nil && i >= 0 && i < r3!.count {
            let r3a = _ovTitle2![i]
            if r3a.isEmpty == false {
                r1.secondaryText = r3a
            }
        }
        if _ovIsLastRedForCancel && i == r2.count - 1 {
            r1.textProperties.color = .systemRed // cancel
        } else if _ovColors != nil {
            let colors = _ovColors!
            if i < colors.count  {
                r1.textProperties.color = colors[i]
            }
        }
        
        let img = _getImageI(i)
        if img != nil { r1.image = img }
        
        cell.contentConfiguration = r1
        return cell
    }
    func _getImageI(_ i: Int)-> UIImage? {
        if _ovImages == nil { return nil }
        let r1 = _ovImages!
        
        if i < 0 || i >= r1.count { return nil }
        return r1[i]
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _onClickRow$.trigger(nil,indexPath.row)
    }
    
    
    class DetailCell : UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            // fatalError("init(coder:) has not been implemented")
        }
    }
}
