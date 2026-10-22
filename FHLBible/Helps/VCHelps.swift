
import SwiftUI
import UIKit
import FHLCommon

/// 教學的一個主題：清單上的標題 + 依序翻頁的圖片（圖片放在 Assets.xcassets/Helps）
struct HelpTopic {
    let titleTw: String
    let titleGb: String
    let imageNames: [String]
    var title: String { ManagerLangSet.s.curIsGb ? titleGb : titleTw }

    static let all: [HelpTopic] = [
        HelpTopic(titleTw: "閱讀", titleGb: "阅读", imageNames: [
            "helps_01read_01a",
            "helps_01read_02a",
            "helps_01read_02b",
            "helps_01read_03a",
            "helps_01read_03b",
            "helps_01read_04a",
            "helps_01read_05a",
            "helps_01read_06a",
            "helps_01read_07a",
        ]),
        HelpTopic(titleTw: "譯本切換", titleGb: "译本切换", imageNames: [
            "helps_02translation_01a",
            "helps_02translation_01b",
            "helps_02translation_01c",
            "helps_02translation_02a",
            "helps_02translation_02b",
            "helps_02translation_02c",
            "helps_02translation_03a",
            "helps_02translation_04a",
        ]),
        HelpTopic(titleTw: "註釋", titleGb: "注释", imageNames: [
            "helps_03comment_01a",
            "helps_03comment_01b",
            "helps_03comment_02a",
            "helps_03comment_03a",
            "helps_03comment_03b",
            "helps_03comment_04a",
            "helps_03comment_04b",
            "helps_03comment_05a",
        ]),
        HelpTopic(titleTw: "譯本比較", titleGb: "译本比较", imageNames: [
            "helps_04comparetranslations_01a",
            "helps_04comparetranslations_01b",
            "helps_04comparetranslations_02a",
            "helps_04comparetranslations_02b",
            "helps_04comparetranslations_02c",
            "helps_04comparetranslations_03a",
            "helps_04comparetranslations_03b",
        ]),
        HelpTopic(titleTw: "串珠", titleGb: "串珠", imageNames: [
            "helps_05textsearchkey_01a",
            "helps_05textsearchkey_01b",
            "helps_05textsearchkey_02a",
            "helps_05textsearchkey_03a",
            "helps_05textsearchkey_03b",
            "helps_05textsearchkey_04a",
        ]),
        HelpTopic(titleTw: "搜尋", titleGb: "搜寻", imageNames: [
            "helps_06search_01a",
            "helps_06search_01b",
            "helps_06search_01c",
            "helps_06search_02a",
            "helps_06search_02b",
            "helps_06search_03a",
            "helps_06search_03b",
            "helps_06search_04a",
            "helps_06search_04b",
            "helps_06search_04c",
            "helps_06search_05a",
        ]),
        HelpTopic(titleTw: "SN", titleGb: "SN", imageNames: [
            "helps_07sn_01a",
            "helps_07sn_01b",
            "helps_07sn_01c",
            "helps_07sn_02a",
            "helps_07sn_02b",
            "helps_07sn_03a",
            "helps_07sn_03b",
            "helps_07sn_04a",
            "helps_07sn_04b",
            "helps_07sn_05a",
            "helps_07sn_05b",
            "helps_07sn_06a",
            "helps_07sn_06b",
            "helps_07sn_07a",
            "helps_07sn_07b",
            "helps_07sn_07c",
            "helps_07sn_07d",
            "helps_07sn_08a",
            "helps_07sn_09a",
            "helps_07sn_09b",
            "helps_07sn_10a",
            "helps_07sn_10b",
            "helps_07sn_10c",
        ]),
        HelpTopic(titleTw: "有聲聖經", titleGb: "有声圣经", imageNames: [
            "helps_08audio_01a",
            "helps_08audio_01b",
            // "helps_08audio_01c",
            "helps_08audio_02a",
            "helps_08audio_03a",
            "helps_08audio_04a",
            "helps_08audio_05a",
            "helps_08audio_05b",
            "helps_08audio_05c",
            "helps_08audio_06a",
            "helps_08audio_06b",
            "helps_08audio_06c",
            "helps_08audio_07a",
            "helps_08audio_07b",
        ]),
        HelpTopic(titleTw: "有聲文字", titleGb: "有声文字", imageNames: [
            "helps_09textspeech_01a",
            "helps_09textspeech_01b",
            "helps_09textspeech_02a",
            "helps_09textspeech_02b",
            "helps_09textspeech_03a",
            "helps_09textspeech_03b",
            "helps_09textspeech_04a",
            "helps_09textspeech_04b",
            "helps_09textspeech_05a",
            "helps_09textspeech_05b",
        ]),
    ]
}

/// 教學主題清單
struct HelpsView: View {
    let topics = HelpTopic.all
    let onSelect: (HelpTopic) -> Void

    var body: some View {
        List {
            ForEach(Array(topics.enumerated()), id: \.offset) { _, topic in
                Button {
                    onSelect(topic)
                } label: {
                    Text(verbatim: topic.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(ManagerLangSet.s.curIsGb ? "教学" : "教學")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 一個主題的圖片，左右滑動翻頁（不顯示頁碼點）
struct HelpPagesView: View {
    let imageNames: [String]

    var body: some View {
        TabView {
            ForEach(imageNames, id: \.self) { name in
                // 與舊版一樣：圖片拉伸填滿（scaleToFill），上緣貼 safe area、下緣貼畫面底
                Image(name)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .bottom)
    }
}

/// 一個主題的圖片翻頁畫面（原本是 ImagePageViewController 的 9 個子類別）
class VCHelpPages: UIHostingController<HelpPagesView> {
    init(imageNames: [String]) {
        super.init(rootView: HelpPagesView(imageNames: imageNames))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: HelpPagesView(imageNames: []))
    }
}

/// 「教學」：首頁 goHelp 以 `VCHelps()` 推進；點主題再推進圖片翻頁
class VCHelps: UIHostingController<HelpsView> {
    init() {
        super.init(rootView: HelpsView(onSelect: { _ in }))
        rootView = HelpsView(onSelect: { [weak self] topic in
            let pageVC = VCHelpPages(imageNames: topic.imageNames)
            self?.navigationController?.pushViewController(pageVC, animated: true)
        })
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: HelpsView(onSelect: { _ in }))
    }
}
