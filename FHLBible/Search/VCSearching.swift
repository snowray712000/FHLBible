import Foundation
import UIKit
import SwiftUI
import FHLCommon

/// 「搜尋」輸入畫面（關鍵字 + 搜尋記錄）。畫面是 SwiftUI (`SearchingView`，在 ViewSearching.swift)，
/// 以 `VCSearching()` 建立後 push，不再經由 storyboard。
/// 選好關鍵字後：先返回前一個畫面，再用 `onClickSearching$` 通知 (由閱讀接著開搜尋結果，所以結果畫面不會疊在這一層)。
class VCSearching : UIHostingController<SearchingView> {
    var onClickSearching$: IjnEventOnce<UIView,DText> = IjnEventOnce()

    init() {
        super.init(rootView: SearchingView(model: SearchingModel(), onSearch: { _ in }))
        rootView = SearchingView(model: SearchingModel(), onSearch: { [weak self] w in
            self?.navigationController?.popViewController(animated: false) // 先 pop 掉再 trigger，不然會 push 到第二層
            self?.onClickSearching$.triggerAndCleanCallback(nil, DText(w))
        })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: SearchingView(model: SearchingModel(), onSearch: { _ in }))
    }
}
