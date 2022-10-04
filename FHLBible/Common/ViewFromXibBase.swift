//
//  ViewSearchResult.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import UIKit

class ViewFromXibBase : UIView {
    @IBOutlet var viewBase: UIView!
    var bundleForInit: Bundle { Bundle(for: type(of: self)) }
    var nibName: String { "ViewFromXibBase" }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initFromXib()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initFromXib()
    }
    func initFromXib(){
        bundleForInit.loadNibNamed(nibName, owner: self, options: nil)
        addSubview(viewBase)
        viewBase.add4ConstrainsWithSuperView()
        viewBase.frame.size = self.frame.size
        
        initedFromXib()
    }
    func initedFromXib(){}
}
