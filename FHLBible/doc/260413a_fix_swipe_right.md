
# 260413a — 修復單指向右與系統返回手勢衝突

---

### to users

- Bug 修復：單指向右
  - iOS 26 以上新增了「從畫面任意位置向右滑返回上一頁」的系統手勢，與 app 原有的「單指向右切換章節」功能衝突，導致兩個動作同時觸發
  - 現已修復，單指向右只會切換章節，不再觸發系統返回

---

### to coder

- iOS 26 在 `UINavigationController` 新增了 `interactiveContentPopGestureRecognizer`，這是一個全新的全螢幕向右滑返回手勢，與舊的 `interactivePopGestureRecognizer`（僅左緣）是兩個不同的 gesture recognizer
- 修復方式：在 `SwipeHelp` 實作 `UIGestureRecognizerDelegate`，在 VC 進入畫面時將兩個 gesture recognizer 的 delegate 換成自己，並在 `gestureRecognizerShouldBegin` 回傳 `false` 阻止系統手勢觸發；離開畫面時還原 delegate
- 受影響的 VC（皆有 swipe-right）：`VCRead`、`VCParsing`、`VCFooter`、`VCTsk`、`VCSnDict`、`VCVersionsCompareInOneVerse`、`VCComment`
- 相關檔案：`FHLBible/Tools/SwipeHelp.swift`
