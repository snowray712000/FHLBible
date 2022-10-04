//
//  InfoButtonBase.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/5.
//

import Foundation
import UIKit

/// 當實作 版本選擇，書卷選擇，發現 button 帶著資訊，太常用到
/// 於是寫一個通用的
/// 過載 initedBtn … 每次 btn 到底要過載哪個 init 令人困惑，所以就寫一個這個
class InfoButtonBase<T> : UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initedBtn()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initedBtn()
    }
    /// 若 0，color 會設為 default；若有值，則會設為 title 同顏色 (所以要先設 title 顏色，再設這個)
    var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    var borderRadius: CGFloat = 5.0 {
        didSet { layer.cornerRadius = borderRadius }
    }
    var insets: CGFloat = 3.0 {
        didSet {
            self.contentEdgeInsets.right = insets
            self.contentEdgeInsets.left = insets
            self.contentEdgeInsets.top = insets
            self.contentEdgeInsets.bottom = insets
        }
    }
    /// true 會同時去設定 layer.backgroundColor
    var isSelected2: Bool {
        get {
            return isSelected
        }
        set {
            if newValue {
                layer.backgroundColor = UIColor.systemGreen.cgColor
                setTitleColor(selectColor, for: .normal)
            } else {
                layer.backgroundColor = nil
                setTitleColor(titleColor , for: .normal)
            }
            isSelected  = newValue
        }
    }
    var titleColor: UIColor = .systemBlue {
        didSet{
            layer.borderColor = titleColor.cgColor
        }
    }
    var selectColor: UIColor = .white {
        didSet {
            if isSelected2 {
                isSelected2 = true
            }
        }
    }
    
    /// 過載，請單叫 super.initedBtn()
    /// insets = 3 ; radius = 5
    func initedBtn(){
        titleColor = .systemBlue
        setTitleColor(titleColor, for: .normal)
        selectColor = .white
        insets = 3
        borderRadius = 5
    }
    var info: T?
}
