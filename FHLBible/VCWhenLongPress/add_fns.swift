//
//  add_fns.swift
//  FHLBible
//
//  Created by littlesnow on 2023/12/11.
//

import Foundation

extension VCWhenLongPress {
    func _add_copy_text(){
        let title = NSLocalizedString("純文字複製", comment: "")
        
        let settingCopy1 = DOneLongPressCellSetting(strDoSomething: title, viewController: self)
        settingsOfFunCell.append(settingCopy1)
        settingCopy1.evDo.addCallback {[weak self] sender, pData in
            self?.copyToPaste(tpCopy: .text)
        }
    }
    func _add_copy_rtf_text(){
        let strHelp = NSLocalizedString("貼上的連結，顏色，都可以按目前所看見的，例如貼在 PowerPoint 文件上。並非所有程式，都支援貼上這種格式，如果貼上無法成功，就只能使用「純文字複製」。", comment: "")
        let strTitle = NSLocalizedString("進階複製", comment: "")
        
        let settingCopy2 = DOneLongPressCellSetting(strHelp: strHelp, strDoSomething: strTitle, viewController: self)
        settingsOfFunCell.append(settingCopy2)
        settingCopy2.evDo.addCallback { [weak self] sender, pData in
            self?.copyToPaste(tpCopy: .rtf)
        }
    }
    func _add_copy_img(){
        let strHelp = NSLocalizedString("以 png 圖片格式複製，貼上", comment: "")
        let strTitle = NSLocalizedString("圖片複製", comment: "")
        
        let settingCopy3 = DOneLongPressCellSetting(strHelp: strHelp,strDoSomething: strTitle, viewController: self)
        settingsOfFunCell.append(settingCopy3)
        settingCopy3.evDo.addCallback { [weak self] sender, pData in
            self?.copyToPaste(tpCopy: .img)
        }
    }
    
    func _add_is_sn_visiable_switch(){
        let strHelp = NSLocalizedString("只有和合本，KJV，和合本2010的舊約，具有 Strong Number 代號", comment: "")
        let strTitle = NSLocalizedString("SN 複製", comment: "")
        
        let settingSNChanged = DOneLongPressCellSetting(strHelp: strHelp,strLabel: strTitle, viewController: self)
        settingsOfFunCell.append(settingSNChanged)
        settingSNChanged.evSwitch1.addCallback {[weak self] sender, pData in
            guard let self = self, let pdata = pData else {
                return
            }
            
            self.isSNShow = pdata
            self.textView!.attributedText = generateTextViewContent()
        }
        settingSNChanged.fnIsOnSwitch = {
            return self.isSNShow
        }
    }
    func _add_is_generate_link_switch(){
        let strHelp = NSLocalizedString("長按連結，可開啟連結。", comment: "")
        let strTitle = NSLocalizedString("參照連結", comment: "")
        
        let settingGenerateAddress = DOneLongPressCellSetting(strHelp: strHelp, strLabel: strTitle, viewController: self)
        settingsOfFunCell.append(settingGenerateAddress)
        settingGenerateAddress.evSwitch1.addCallback {[weak self] sender, pData in
            guard let self = self, let pdata = pData else {
                return
            }
            
            self.isGenerateAddress = pdata
            self.textView!.attributedText = generateTextViewContent()
        }
        settingGenerateAddress.fnIsOnSwitch = {
            return self.isGenerateAddress
        }
    }
    func _add_is_show_version_forcely_switch(){
        let strHelp = NSLocalizedString("關閉時，若譯本只有一個，就不會顯示譯本資訊；而開啟時，僅管只有一個譯本，仍然會強制顯示譯本資訊。二個譯本以上，一定會顯示譯本資訊", comment: "")
        let strTitle = NSLocalizedString("顯示譯本", comment: "")
        
        let settingForceShowVersion = DOneLongPressCellSetting(strHelp: strHelp,strLabel: strTitle,viewController: self)
        settingsOfFunCell.append(settingForceShowVersion)
        settingForceShowVersion.evSwitch1.addCallback {[weak self]sender, pData in
            guard let self = self, let pdata = pData else {
                return
            }
            
            self.isForceShowVersion = pdata
            self.textView!.attributedText = generateTextViewContent()
        }
        settingForceShowVersion.fnIsOnSwitch = {
            return self.isForceShowVersion
        }
    }
}
