//
//  VCWhenLongPress.swift
//  FHLBible
//
//  Created by littlesnow on 2023/10/28.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class VCWhenLongPress : UIViewController, UICollectionViewDataSource {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    var dataSelections: DSelections!
    var isGenerateAddress: Bool = true
    /** 自動模式，就是一個譯本，不顯示；多個譯本，會顯示。*/
    var isForceShowVersion: Bool = false
    var isSNShow: Bool = true
    
    var settingsOfFunCell: [DOneLongPressCellSetting] = []
    enum TpCopy {
        case text
        case rtf
        case img
        case all
    }
    func copyToPaste(tpCopy: TpCopy){
        guard let textView = self.textView else {
            return
        }
        
        // 隱藏鍵盤
        textView.resignFirstResponder()
        
        // 檢查 TextView 是否有文字
        guard let textToCopy = textView.text, !textToCopy.isEmpty else {
            return
        }
        
        // 取得剪貼簿
        let pasteboard = UIPasteboard.general
        
        // 因為有 .all ，所以把它們作成函式，共用
        func gRTF()->Data? {
            guard let attrString = textView.attributedText, attrString.length != 0 else {
                return nil
            }
            return try? attrString.data(from: NSRange(location: 0, length: attrString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        }
        
        func gPngImageData(fn: @escaping (_ data: Data?)->Void) {
            textView.capture { image in
                fn(image?.pngData())
            }
        }
        func msgOk(){
            // 在複製後，你可以顯示一個提示或處理其他操作
            // 例如：顯示一個提示訊息
            let title = NSLocalizedString("已複製到剪貼簿", comment: "")
            let msg = NSLocalizedString("文字已複製到剪貼簿中。", comment: "")
            let confirm = NSLocalizedString("確定", comment: "")
            
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: confirm, style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        pasteboard.string = textToCopy
        if tpCopy == .text {
            msgOk()
        } else if tpCopy == .rtf {
            if let rtf = gRTF(){
                pasteboard.setItems([
                    [UTType.rtf.identifier: rtf]
                ])
            }
            msgOk()
        } else if tpCopy == .img {
            gPngImageData { data in
                if data != nil {
                    pasteboard.setItems([
                        [UTType.png.identifier: data!]
                    ])
                }
                msgOk()
            }
        } else if tpCopy == .all {
            var items:[[String:Any]] = []
            items.append([UTType.text.identifier:textToCopy])
            if let rtf = gRTF() {
                items.append([UTType.rtf.identifier:rtf])
            }
            gPngImageData { data in
                if data != nil {
                    items.append([UTType.png.identifier:data!])
                }
                pasteboard.setItems(items)
                msgOk()
            }
            
        }
        

    }
    func init_settings_of_func(){
        _add_copy_text()
        _add_copy_rtf_text()
        _add_copy_img()
        
        _add_is_sn_visiable_switch()
        _add_is_generate_link_switch()
        _add_is_show_version_forcely_switch()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        
        init_settings_of_func()
        
        // LongPressCell
        // dataSelections = DSelections.gTest7() // unit test
        textView.attributedText = generateTextViewContent()
        
        // click 到空白處 for 隱藏鍵盤
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        collectionView.backgroundView = UIView(frame: collectionView.bounds)
        collectionView.backgroundView?.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        // 隱藏鍵盤
        textView.resignFirstResponder()
    }

    func generateTextViewContent()->NSMutableAttributedString{
        // 兩個譯本以上，才需要，譯本。除非強制顯示
        var isVerShow = dataSelections.vers.count > 1 || isForceShowVersion
        
        let re = NSMutableAttributedString()
        let addrs = dataSelections.addrs!
        for key1 in addrs {
            if let oneAddrDict = dataSelections.data[key1] {
                let reOneRow = NSMutableAttributedString()
                for ver in dataSelections.vers {
                    if let dtexts = oneAddrDict[ver] {
                        let r2 = self.cvtForTextView(dtexts)
                        if reOneRow.length != 0 {
                            // 與前一個譯本，斷開。
                            reOneRow.append(NSAttributedString(string: "\n\n")) // 用 \r\n PowerPoint 會變多行
                        }
                        
                        // 內容
                        reOneRow.append(r2)
                        
                        // 譯本 (新譯本)
                        if isVerShow {
                            let attrs = EasyStringAttributes()
                            attrs.fontColor = .systemBlue
                            let ver_cna = BibleVersionConvertor().na2cna(ver)
                            let verStr = "("+ver_cna+")"
                            let reVer = NSAttributedString(string: verStr, attributes: attrs.resultAttributes)
                            reOneRow.append(reVer)
                        }
                    }
                }
                if re.length != 0 {
                    re.append(NSAttributedString(string: "\n\n"))
                }
            
                
                // 加上經文位置索引
                let addrStr = "#" + VerseRangeToString().main(key1, ManagerLangSet.s.curTpBookNameLang) + "|\n"
                let addrDtexts = DText(addrStr) // 不這樣作，字會太小。
                let title = DTextDrawToAttributeString(false, true).mainConvert([addrDtexts])
                let title2 = title[0]
                for i in 1..<title.count{
                    title2.append(title[i])
                }
                let easyAttrs = EasyStringAttributes()
                easyAttrs.fontColor = .systemBlue
                title2.setAttributes(easyAttrs.resultAttributes,
                                     range: NSRange(location: 0, length: title2.length))
                re.append(title2)
            
                re.append(reOneRow)
            }
        }
        
        // 加所有經文網址
        if isGenerateAddress {
            let reAddr = gAddressDescript(addrs: dataSelections.addrs!.flatMap{$0})
            re.append(NSAttributedString(string: "\n\n"))
            re.append(reAddr)
        }
        
        return re
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LongPressCell", for: indexPath) as! LongPressFuncCell

        cell.set_on_reuse(data: self.settingsOfFunCell[indexPath.item])
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settingsOfFunCell.count
    }
    /**
     顯示 [創1:1-2;出1:1]( https://bible.net.net/NUI/_rwd/#/bible/創1:1-2.出1:1 )
     - .link 屬性，是真正被 PowerPoint 或 Textview 長按時，開啟的連結。
     - 承上，所以要 addingPercentEncoding
     - 承上，但不能把整個 url 作 encoding，因為會把 # 變成 %23
     - 為何連結要「.」取代「;」？那是因為 angular 的網址 ; 有特殊用途，我也不知道怎麼改，所以配合 RWD 網址，只好這麼作。
     */
    private func gAddressDescript(addrs: [DAddress])->NSMutableAttributedString{
        let re = NSMutableAttributedString()
        
        let easyAttrs = EasyStringAttributes()
        easyAttrs.fontColor = .systemRed
        
        
        let addrShow = VerseRangeToString().main(addrs, ManagerLangSet.s.curTpBookNameLang)
        let r2a = NSAttributedString(string: "[#\(addrShow)|]( ", attributes: easyAttrs.resultAttributes)
        let r2b = NSAttributedString(string: " )", attributes: easyAttrs.resultAttributes) // 注解寫在這，是知道 re1b 用在哪
        re.append(r2a)
        
        let rootLink = "https://bible.fhl.net/NUI/_rwd/#/bible/"
        let addrLinkShow = addrShow.replacingOccurrences(of: ";", with: ".")
        if let addrLinkProperties = addrLinkShow.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed){
            easyAttrs.fontColor = nil // remove color
            easyAttrs.link = rootLink + addrLinkProperties
        } else {
            easyAttrs.fontColor = .systemBlue
        }
        let r3 = NSAttributedString(string: rootLink + addrLinkShow, attributes: easyAttrs.resultAttributes)
        re.append(r3)
        
        re.append(r2b)
        return re
    }
    // NSAttributedString 不好 append, 所以寫成 func
    private func attributedStringAppendString(_ origin: NSAttributedString,_ text: String)->NSMutableAttributedString{
        // 创建一个 NSMutableAttributedString，用于修改现有文本
        let mutableAttributedString = NSMutableAttributedString(attributedString: origin)
        
        // 获取原始文本的字体属性
        var lastCharacterRange = NSRange(location: origin.length - 1, length: 1)
        let originalFont = origin.attribute(.font, at: origin.length - 1, effectiveRange: &lastCharacterRange)
        
        // 要添加的文本
        let additionalText = text
        // 创建一个 NSAttributedString 包含要添加的文本
        let additionalAttributedString = NSAttributedString(string: additionalText, attributes: [.font: originalFont as Any])
        // 将要添加的 NSAttributedString 追加到现有文本的末尾
        mutableAttributedString.append(additionalAttributedString)
        // 更新 textView.attributedText
        return mutableAttributedString
    }
    
    /// 從 VCRead 那偷來用的
    private func cvtForTextView(_ dtexts: [DText]) -> NSMutableAttributedString {
        let _isFontNameOpenHanBibleTC = true        
        let r2 = DTextDrawToAttributeString(isSNShow,_isFontNameOpenHanBibleTC).mainConvert(dtexts)
        
        let re2 = NSMutableAttributedString()
        r2.forEach({re2.append($0)})
        return re2
    }
    var textToCopy: String!
    @IBAction func doCopy(){
        copyToPaste(tpCopy: .all)
    }
}

