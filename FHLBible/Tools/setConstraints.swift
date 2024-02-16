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

}
