/**
 
 */

import Foundation
import UIKit


class LongPressFuncCell : UICollectionViewCell{
    @IBOutlet weak var btnHelp: UIButton!
    @IBOutlet weak var btnDo: UIButton!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var switch1: UISwitch!
    var yourViewBorder: CAShapeLayer?
    
    /** weak , 實體放在  View Controller */
    weak var setting: DOneLongPressCellSetting?
    /**
     cell 會不斷被重用，就像 tableview 一樣。
     */
    func set_on_reuse(data: DOneLongPressCellSetting){
        setting = data
        
        guard let setting = setting else {
            btnDo.isHidden = true
            btnHelp.isHidden = true
            label1.isHidden = true
            switch1.isHidden = true
            
            return
        }
        
        if yourViewBorder == nil {
            yourViewBorder = CAShapeLayer()
            yourViewBorder!.strokeColor = UIColor.black.cgColor
            yourViewBorder!.lineDashPattern = [2, 2]
            yourViewBorder!.frame = contentView.bounds
            yourViewBorder!.fillColor = nil
            yourViewBorder!.path = UIBezierPath(rect: contentView.bounds).cgPath
            contentView.layer.addSublayer(yourViewBorder!)
        } else {
            yourViewBorder!.frame = contentView.bounds
            yourViewBorder!.path = UIBezierPath(rect: contentView.bounds).cgPath
        }
        
        if setting.strHelp != nil {
            btnHelp.setTitle("", for: .normal) // nil 會跑出 Button 字眼
            btnHelp.isHidden = false
        } else {
            btnHelp.isHidden = true
        }
        
        if setting.strDoSomething != nil {
            btnDo.setTitle(setting.strDoSomething!, for: .normal)
        }
        btnDo.isHidden = setting.strDoSomething == nil
        
        if setting.strLabel != nil {
            label1.text = setting.strLabel!
            label1.isHidden = false
            switch1.isHidden = false
            if setting.fnIsOnSwitch != nil {
                switch1.isOn = setting.fnIsOnSwitch!()
            }
        } else {
            label1.isHidden = true
            switch1.isHidden = true
        }
    }
    @IBAction func doHelp(){
        guard let setting = setting, let msg = setting.strHelp, let vc = setting.viewController else {
            return
        }
        // 在複製後，你可以顯示一個提示或處理其他操作
        // 例如：顯示一個提示訊息
        let alert = UIAlertController(title: "說明", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    @IBAction func doSomething(){
        setting?.evDo.trigger()
    }
    @IBAction func switchChanged(){
        setting?.evSwitch1.trigger(self, switch1.isOn)
    }
}
