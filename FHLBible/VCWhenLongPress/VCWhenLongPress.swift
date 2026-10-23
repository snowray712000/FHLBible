//
//  VCWhenLongPress.swift
//  FHLBible
//
//  Created by littlesnow on 2023/10/28.
//

import Foundation
import UIKit
import SwiftUI
import UniformTypeIdentifiers
import FHLCommon

/// 複選經文按「完成」後的畫面：預覽 (可直接修改) 要複製的文字，並提供純文字／進階 (RTF)／圖片複製、產生圖片存到相簿。
/// 畫面是 SwiftUI (`CopyShareView`)，文字內容用 `UITextView` (要保留顏色、連結的 `NSAttributedString` 與編輯功能)。
/// 以 `VCWhenLongPress(dataSelections:)` 建立後 push，不再經由 storyboard。
class VCWhenLongPress : UIHostingController<CopyShareView> {
    private let model: CopyShareModel

    init(dataSelections: DSelections) {
        let m = CopyShareModel(selections: dataSelections)
        self.model = m
        super.init(rootView: CopyShareView(model: m))
        m.host = self
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = CopyShareModel(selections: DSelections())
        self.model = m
        super.init(coder: aDecoder, rootView: CopyShareView(model: m))
        m.host = self
    }
}

/// 複製、產生圖片的狀態：要複製的內容 (依三個開關產生)、提示訊息
@Observable
final class CopyShareModel {
    enum TpCopy {
        case text
        case rtf
        case img
        case all
    }

    let selections: DSelections
    /// 目前只有一個譯本時是否仍顯示譯本 (自動模式：一個譯本不顯示，多個譯本會顯示)
    var isForceShowVersion = false
    var isGenerateAddress = true
    var isSNShow = true

    /// `content` 每重新產生一次加 1，讓 UITextView 只在真的換內容時才重設 (否則會洗掉使用者的修改)
    private(set) var generation = 0
    private(set) var content = NSAttributedString()
    /// 短暫顯示的提示 (例如「已複製」)，nil 表示沒有
    var toast: String?

    @ObservationIgnored weak var textView: UITextView?
    @ObservationIgnored weak var host: UIViewController?
    @ObservationIgnored private var saver: SaveToPhotoHelper?
    @ObservationIgnored private var toastId = 0

    init(selections: DSelections) {
        self.selections = selections
        regenerate()
    }

    /// 開關改變後呼叫。使用者在文字框中所做的修改會被取代 (與舊版相同)
    func regenerate() {
        content = generateContent()
        generation += 1
    }

    // MARK: 複製

    func copy(_ tpCopy: TpCopy) {
        guard let textView = textView else { return }
        textView.resignFirstResponder()

        // 複製的是文字框「目前」的內容，包含使用者的修改
        let attr = textView.attributedText ?? NSAttributedString()
        let text = textView.text ?? ""
        guard !text.isEmpty else { return }

        // 同一個項目放多種格式，貼上時由對方程式挑它看得懂的
        var item: [String: Any] = [:]
        if tpCopy == .text || tpCopy == .rtf || tpCopy == .all {
            item[UTType.utf8PlainText.identifier] = text
        }
        if tpCopy == .rtf || tpCopy == .all {
            let rtf = try? attr.data(from: NSRange(location: 0, length: attr.length),
                                     documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            if let rtf = rtf { item[UTType.rtf.identifier] = rtf }
        }
        if tpCopy == .img || tpCopy == .all {
            if let png = renderImage()?.pngData() { item[UTType.png.identifier] = png }
        }
        guard !item.isEmpty else {
            showToast(NSLocalizedString("產生影像失敗", comment: ""))
            return
        }
        UIPasteboard.general.setItems([item])
        showToast(NSLocalizedString("文字已複製到剪貼簿中。", comment: ""))
    }

    /// 產生圖片並存到相簿
    func saveImageToPhotos() {
        textView?.resignFirstResponder()
        guard let image = renderImage(), let host = host else {
            showToast(NSLocalizedString("產生影像失敗", comment: ""))
            return
        }
        let saver = SaveToPhotoHelper()
        self.saver = saver
        saver.evCompleted.addCallback { [weak self] _, result in
            if result?.isOk == true {
                self?.showToast(NSLocalizedString("儲存影像成功", comment: ""))
            } else {
                let msg = NSLocalizedString("儲存影像失敗", comment: "")
                self?.showToast(result?.er.map { msg + ": " + $0 } ?? msg)
            }
        }
        saver.main(vc: host, img: image)
    }

    /// 把文字框目前的內容畫成一張長圖。
    /// 不是截文字框 (它在畫面上只有一小塊、要靠捲動拼接)，而是另外建一個不捲動的文字框，高度撐到放得下全部文字再畫；
    /// 白底、固定淺色外觀，這樣不論手機是不是深色模式，存下來的圖都一樣。
    private func renderImage() -> UIImage? {
        guard let source = textView, let attr = source.attributedText, attr.length > 0 else { return nil }

        let width = max(source.bounds.width, 320)
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: width, height: 10))
        tv.overrideUserInterfaceStyle = .light
        tv.backgroundColor = .white
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.attributedText = attr
        let height = ceil(tv.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
        tv.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tv.layoutIfNeeded()

        // 整章選起來會很長，太高相簿存不下 (儲存失敗)，所以倍率隨高度降低，最高約 16000 px (與閱讀的「圖片產生」相同)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = min(format.scale, max(1, 16000 / height))
        let renderer = UIGraphicsImageRenderer(size: tv.bounds.size, format: format)
        var image: UIImage?
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            image = renderer.image { ctx in
                tv.layer.render(in: ctx.cgContext)
            }
        }
        return image
    }

    private func showToast(_ msg: String) {
        toast = msg
        toastId += 1
        let id = toastId
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            // 期間又有新的提示，就讓新的自己消失
            if let self = self, self.toastId == id { self.toast = nil }
        }
    }

    // MARK: 內容

    private func generateContent() -> NSAttributedString {
        // 兩個譯本以上，才需要，譯本。除非強制顯示
        let vers = selections.vers ?? []
        let isVerShow = vers.count > 1 || isForceShowVersion

        let re = NSMutableAttributedString()
        let addrs = selections.addrs ?? []
        for key1 in addrs {
            if let oneAddrDict = selections.data[key1] {
                let reOneRow = NSMutableAttributedString()
                for ver in vers {
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
                let title2 = NSMutableAttributedString()
                title.forEach { title2.append($0) }
                let easyAttrs = EasyStringAttributes()
                easyAttrs.fontColor = .systemBlue
                title2.setAttributes(easyAttrs.resultAttributes,
                                     range: NSRange(location: 0, length: title2.length))
                re.append(title2)

                re.append(reOneRow)
            }
        }

        // 加所有經文網址
        if isGenerateAddress, !addrs.isEmpty {
            let reAddr = gAddressDescript(addrs: addrs.flatMap{$0})
            re.append(NSAttributedString(string: "\n\n"))
            re.append(reAddr)
        }

        return re
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
    /// 從 VCRead 那偷來用的
    private func cvtForTextView(_ dtexts: [DText]) -> NSMutableAttributedString {
        let _isFontNameOpenHanBibleTC = true
        let r2 = DTextDrawToAttributeString(isSNShow,_isFontNameOpenHanBibleTC).mainConvert(dtexts)

        let re2 = NSMutableAttributedString()
        r2.forEach({re2.append($0)})
        return re2
    }
}

// MARK: - View

struct CopyShareView: View {
    let model: CopyShareModel

    var body: some View {
        List {
            Section {
                CopyTextView(model: model)
                    .frame(height: 240)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text(NSLocalizedString("內容（可直接修改）", comment: ""))
            }

            Section {
                ActionRow(title: NSLocalizedString("純文字複製", comment: ""),
                          systemImage: "doc.on.doc",
                          help: nil) { model.copy(.text) }
                ActionRow(title: NSLocalizedString("進階複製", comment: ""),
                          systemImage: "doc.richtext",
                          help: NSLocalizedString("貼上的連結，顏色，都可以按目前所看見的，例如貼在 PowerPoint 文件上。並非所有程式，都支援貼上這種格式，如果貼上無法成功，就只能使用「純文字複製」。", comment: "")) { model.copy(.rtf) }
                ActionRow(title: NSLocalizedString("圖片複製", comment: ""),
                          systemImage: "photo.on.rectangle",
                          help: NSLocalizedString("以 png 圖片格式複製，貼上", comment: "")) { model.copy(.img) }
                ActionRow(title: NSLocalizedString("圖片產生", comment: ""),
                          systemImage: "square.and.arrow.down",
                          help: NSLocalizedString("並非所有程式都能貼上，所以提供生成為相片。應用1:可搭配手寫新增筆記重點，再傳給他人。", comment: "")) { model.saveImageToPhotos() }
            } header: {
                Text(NSLocalizedString("複製", comment: ""))
            }

            Section {
                OptionRow(title: NSLocalizedString("SN 複製", comment: ""),
                          help: NSLocalizedString("只有和合本，KJV，和合本2010的舊約，具有 Strong Number 代號", comment: ""),
                          isOn: Binding(get: { model.isSNShow },
                                        set: { model.isSNShow = $0; model.regenerate() }))
                OptionRow(title: NSLocalizedString("參照連結", comment: ""),
                          help: NSLocalizedString("長按連結，可開啟連結。", comment: ""),
                          isOn: Binding(get: { model.isGenerateAddress },
                                        set: { model.isGenerateAddress = $0; model.regenerate() }))
                OptionRow(title: NSLocalizedString("顯示譯本", comment: ""),
                          help: NSLocalizedString("關閉時，若譯本只有一個，就不會顯示譯本資訊；而開啟時，僅管只有一個譯本，仍然會強制顯示譯本資訊。二個譯本以上，一定會顯示譯本資訊", comment: ""),
                          isOn: Binding(get: { model.isForceShowVersion },
                                        set: { model.isForceShowVersion = $0; model.regenerate() }))
            } header: {
                Text(NSLocalizedString("內容選項", comment: ""))
            } footer: {
                Text(NSLocalizedString("改變選項會重新產生上面的內容，之前所做的修改會消失。", comment: ""))
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(NSLocalizedString("複製與圖片", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(NSLocalizedString("複製", comment: "")) { model.copy(.all) }
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = model.toast {
                Text(msg)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .shadow(radius: 4, y: 2)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toast)
    }
}

/// 一列：按了就執行的動作，說明文字在標題下方
private struct ActionRow: View {
    let title: String
    let systemImage: String
    let help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 26)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    if let help = help {
                        Text(help)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 一列：開關，說明文字在標題下方
private struct OptionRow: View {
    let title: String
    let help: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(help)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// 可編輯的 `UITextView`，內容是帶顏色、連結的 `NSAttributedString`；SwiftUI 的 `TextEditor` 在 iOS 17 不能放這種文字
private struct CopyTextView: UIViewRepresentable {
    let model: CopyShareModel

    final class Coordinator: NSObject {
        var generation = -1
        weak var textView: UITextView?
        @objc func doneEditing() { textView?.resignFirstResponder() }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .secondarySystemGroupedBackground
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.adjustsFontForContentSizeCategory = true
        tv.keyboardDismissMode = .interactive

        // 鍵盤上方的「完成」，不然沒辦法收鍵盤 (這個畫面整頁都是文字框與按鈕)
        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [UIBarButtonItem(systemItem: .flexibleSpace),
                     UIBarButtonItem(title: NSLocalizedString("完成", comment: ""), style: .done,
                                     target: context.coordinator, action: #selector(Coordinator.doneEditing))]
        tv.inputAccessoryView = bar

        context.coordinator.textView = tv
        model.textView = tv
        return tv
    }
    func updateUIView(_ tv: UITextView, context: Context) {
        model.textView = tv
        if context.coordinator.generation != model.generation {
            context.coordinator.generation = model.generation
            tv.attributedText = model.content
        }
    }
}
