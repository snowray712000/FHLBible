//
//  setConstraints.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/6/9.
//

import Foundation
import UIKit

public func setConstraintsLRTBMarginsGuide(_ v: UIView,_ pv: UIView){
    v.leftAnchor.constraint(equalTo: pv.layoutMarginsGuide.leftAnchor).isActive = true
    v.rightAnchor.constraint(equalTo: pv.layoutMarginsGuide.rightAnchor).isActive = true
    v.topAnchor.constraint(equalTo: pv.layoutMarginsGuide.topAnchor).isActive = true
    v.bottomAnchor.constraint(equalTo: pv.layoutMarginsGuide.bottomAnchor).isActive = true
}

public func setConstraintsLRTB(_ v: UIView,_ pv: UIView){
    v.leftAnchor.constraint(equalTo: pv.leftAnchor).isActive = true
    v.rightAnchor.constraint(equalTo: pv.rightAnchor).isActive = true
    v.topAnchor.constraint(equalTo: pv.topAnchor).isActive = true
    v.bottomAnchor.constraint(equalTo: pv.bottomAnchor).isActive = true
}

extension UIView {
    /// 像 button 就會用到,
    func addConstrainsTopLeftAndGreaterWHthanMe(){
        let pv = self.superview
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let v2 = pv == nil ? self.superview! : pv!
        
        self.leftAnchor.constraint(equalTo: v2.leftAnchor).isActive = true
        self.topAnchor.constraint(equalTo: v2.topAnchor).isActive = true
        v2.heightAnchor.constraint(greaterThanOrEqualTo: self.heightAnchor).isActive = true
        v2.widthAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor).isActive = true
    }
    func add4ConstrainsWithSuperView(){
        if self.superview == nil {
            return
        }
        
        let pv = self.superview!
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.leftAnchor.constraint(equalTo: pv.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: pv.rightAnchor).isActive = true
        self.topAnchor.constraint(equalTo: pv.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: pv.bottomAnchor).isActive = true
    }
    /// 經實驗，一般新增 constrains 不會自動把重複的去掉，所以加了這個函式
    func removeContrainsRelativeMe(){
        let v2 = self.superview
        if v2 != nil {
            // 主要是第1個，第2個只是個險起見
            // 實驗後， constrains 沒有自動幫你把重複的自動移除
            v2!.removeConstraints(v2!.constraints.filter({$0.firstItem as? UIView == self}))
            v2!.removeConstraints(v2!.constraints.filter({$0.secondItem as? UIView == self}))
        }
        
        // 注意，不是 v 的 constraints 就全部都是與自己相關，可能是 v 的 兩個 children
        self.removeConstraints(self.constraints.filter({$0.firstItem as? UIView == self}))
    }
}
