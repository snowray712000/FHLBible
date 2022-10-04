//
//  ViewDisplayTable.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit

//
//protocol IDisplayTableRowGenerator {
//    func gRowView(_ txt1: String? ,_ data: [DOneLine],_ cxRatio: [Float]) -> UIView
//}
//class DisplayTableRowGeneratorTest1 : IDisplayTableRowGenerator {
//    func gRowView(_ txt1: String?, _ data: [DOneLine], _ cxRatio: [Float]) -> UIView {
//        let r1 = UIView()
//        r1.backgroundColor = .purple
//        r1.translatesAutoresizingMaskIntoConstraints = false
//        r1.widthAnchor.constraint(greaterThanOrEqualToConstant: 20.0).isActive = true
//        r1.heightAnchor.constraint(greaterThanOrEqualToConstant: 10.0).isActive = true
//        return r1
//    }
//}
//class DisplayTableRowGeneratorTest2 : IDisplayTableRowGenerator {
//    func gRowView(_ txt1: String?, _ data: [DOneLine], _ cxRatio: [Float]) -> UIView {
//        
//        let re2 = [getTestCase(6).main(), getTestCase(1).main()]
//        
//        let areas = calcRatio(re2)
//        
//        let r1 = ViewDisplayRow()
//        r1.set([DText("林前11:11")], re2.map({$0.children!}), areas)
//        
//        return r1
//    }
//    private func calcRatio(_ data:[DOneLine])->[CGFloat] {
//        
//        func fn2(_ i2:Int, _ a2: DText)->Int{
//            if a2.children != nil {
//                return a2.children!.reduce(0, fn2)
//            } else {
//                return a2.w != nil ? a2.w!.count : 0
//            }
//        }
//        func fn1(_ a1: DOneLine) -> Int{
//            var sum = 0
//            for a2 in a1.children! {
//                if a2.w != nil {
//                    sum += a2.w!.count
//                }
//            }
//            return sum
//        }
//        
//        return data.map({ CGFloat(fn1($0)) })
//    }
//}
//

//@available(iOS,introduced: 14.0, deprecated: 1.0)
//@IBDesignable
//class ViewDisplayTable : ViewFromXibBase {
//    override var nibName: String { "ViewDisplayTable" }
//    @IBOutlet weak var stack1: UIStackView!
//
//    var vers: [DOneLine] = []
//    var datas: [[DOneLine]] = []
//    override func initedFromXib() {
//        stack1.arrangedSubviews.forEach({$0.removeFromSuperview()})
//
//        let g1 = DisplayTableRowGeneratorTest2()
//        for i in 0..<1 {
//            let v1 = g1.gRowView(nil, [], [])
//            stack1.addArrangedSubview(v1)
//            v1.widthAnchor.constraint(equalTo: stack1.widthAnchor).isActive = true
//
//        }
//    }
//}

