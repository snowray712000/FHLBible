# FHLBible 信望愛聖經

[信望愛站（fhl.net）](https://www.fhl.net) 的聖經 iOS App，完整版。多譯本對照、全文搜尋、原文（Strong 號碼／Parsing）、有聲聖經、註釋與串珠，下載譯本後可離線閱讀。

Bundle ID：`IJN.FHLBible`。最低支援 iOS 17.0。台語精簡版是兄弟專案 [FHLBibleTW](https://github.com/snowray712000/FHLBibleTW)。

## 功能

- **閱讀**：一節一列，可同時顯示多個譯本（上下排）；底部切換譯本與上下章；點經文可開註腳、參照經文、Strong 原文。
- **搜尋**：關鍵字全文搜尋，可依書卷／分類篩選，保留搜尋記錄。
- **原文**：Strong 字典（CBOL／浸宣）、原文逐字分析（Parsing）。
- **註釋與串珠**：註釋、串珠（經文交叉參照）。
- **譯本比較**：同一節經文，各譯本並排。
- **有聲**：有聲聖經（可調速度）、有聲文字（TTS 朗讀）。
- **複製與圖片**：長按經文後複製文字或產生圖片分享。
- **資料**：在 App 內下載譯本、字典、Parsing 等資料檔，下載後離線可用；沒下載的譯本則走信望愛 API。
- **其他**：閱讀記錄、設定（含注腳載入方式）、教學、版本資訊。

各版本新增了什麼，見 App 內「版本資訊」，原始檔是 [`FHLBible/Helps/app_versions.md`](FHLBible/Helps/app_versions.md)。

## 專案組成

這個 repo 只有 FHLBible。它和另外兩個獨立 repo 放在同一個 Xcode workspace（`FHLWorkSpace.xcworkspace`）：

| 專案 | 角色 |
|------|------|
| **FHLBible**（本 repo） | 完整版 App |
| [FHLBibleTW](https://github.com/snowray712000/FHLBibleTW) | 台語聖經精簡版 |
| [FHLCommon](https://github.com/snowray712000/FHLCommon) | 兩個 App 共用的 Framework（`import FHLCommon`） |

三個 repo 要 clone 在同一層資料夾，workspace 才找得到彼此：

```
<任一資料夾>/
├── FHLWorkSpace.xcworkspace
├── FHLBible/
├── FHLBibleTW/
└── FHLCommon/
```

> `FHLWorkSpace.xcworkspace` 目前不在任何 repo 裡，需要從現有環境複製，或自行建立一個包含這三個 `.xcodeproj` 的 workspace。

## 建置

需要 Xcode（目前用 Xcode 27 的 SDK 開發）。

1. 開啟 `FHLWorkSpace.xcworkspace`（不要單獨開 `FHLBible.xcodeproj`，否則 FHLCommon 不會一起編譯）。
2. Scheme 選 `FHLBible`，選一個 iOS 17.0 以上的模擬器或實機，Run。
3. 第一次開啟 Xcode 會自動抓 Swift Package。

指令列：

```bash
xcodebuild -workspace ../FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16' build
```

（模擬器名稱依你機器上有的為準，可用 `xcrun simctl list devices` 查。）

### 相依套件（Swift Package Manager）

| 套件 | 用途 |
|------|------|
| [FMDB](https://github.com/ccgus/fmdb) | 讀 SQLite 譯本檔 |
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | 下載後解壓縮譯本／資料檔 |
| FHLCommon | 共用元件（workspace 內以 Framework 連結並 Embed） |

## 測試

```bash
xcodebuild test -workspace ../FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16'
```

`FHLBibleTests/fhlwh_bug/` 內的部分測試需要區網伺服器（`192.168.0.116:5600`），連不到時會 `XCTSkip`，不算失敗。

## 程式結構

UIKit 為主；簡單的畫面已逐步改用 SwiftUI（以 `UIHostingController` 放進既有 `UINavigationController`）。

```
FHLBible/
├── Read/              閱讀畫面與取資料流程（核心）
├── Search/            搜尋（關鍵字輸入、結果）
├── FHLTools/          SNDict 字典、SNParsing 原文分析、Tsk 串珠、Comment 註釋
├── VCAudioBible/      有聲聖經
├── VCAudioTextBible/  有聲文字（TTS）
├── VCVersionsPicker/  譯本選擇
├── VCVersionsCompareInOneVerse/  譯本比較
├── BookChapPicker/    書卷章選擇
├── Download/          譯本與資料檔下載、SQLite 檔管理
├── SQLiteFHL/         SQLite 操作（FMDB 包裝）
├── Common/            DAddress、DText、DOneLine 等共用型別
├── Helps/             教學、版本資訊（app_versions.md）
├── VCSetting/         設定
└── doc/               手寫的開發筆記
```

資料流（閱讀）：選定經文位址 → 每個譯本一條執行緒取資料（本機有 SQLite 檔就用，沒有就呼叫信望愛 API）→ 轉成富文字節點 `[DText]` → 回主執行緒更新畫面。

核心型別：`DAddress`（單節位址）、`VerseRange`（經文範圍）、`DOneLine`（某譯本的一節）、`DText`（含 Strong 號碼、註腳的富文字節點）。更完整的說明見 [`CLAUDE.md`](CLAUDE.md)。

## 開發紀錄與文件

- [`CLAUDE.md`](CLAUDE.md)：給 AI 助手的專案導讀（架構、慣例、限制），人也可以讀。
- [`ai-log/`](ai-log/index.md)：每次開發的詳細紀錄（英文，給 AI 讀），從 [`index.md`](ai-log/index.md) 找起。
- [`FHLBible/doc/`](FHLBible/doc/)：較早期手寫的筆記（Parsing 格式、離線 Parsing 資料庫等）。

## 發佈新版本

1. 在 [`app_versions.md`](FHLBible/Helps/app_versions.md) 新增版本區段（格式見該檔最上方的註解）。
2. 同步更新 `FHLBible/VCIndex.swift` 的 `labelVer`／`labelDate`。

## 資料來源

經文、字典、註釋等內容來自 [信望愛站](https://www.fhl.net)，各譯本的版權屬原版權所有者。
