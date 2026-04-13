# FHL Bible — SN 字典視圖 Dynamic Type 修正說明

## 一、問題描述

Parsing 的 SN 字典視圖中，有一部分文字不會跟著 iOS 系統字級放大。

### 不會放大的項目

- `原型`
- `簡義`
- `分析`
- `備註`
- 上方三個按鈕中的文字：
  - `btnSn`
  - `btnWord`
  - `btnOrig`

### 會放大的項目

- `cellExp`
- `cellXForm`
- `cellRemark`

這些其實是 `ViewDisplayCell`，不是單純的 xib label，因此走的是另一條文字顯示路徑。

---

## 二、根本原因

### 1. xib 裡的標題 label 使用固定字型

`ViewSNDictCell.xib` 中的 `原型 / 簡義 / 分析 / 備註` 都是固定設定：

```xml
<fontDescription key="fontDescription" type="boldSystem" pointSize="18"/>
```

但沒有任何 Dynamic Type 設定，因此系統字級變大時不會跟著變。

### 2. 上方 3 個畫線文字其實是 UIButton 標題

使用者畫線的 3 個文字不是 `UILabel`，而是：

- `btnSn`
- `btnWord`
- `btnOrig`

所以只修 label 還不夠，還必須另外設定 `button.titleLabel` 才會一起放大。

---

## 三、修正方式

### 修改檔案

- `FHLBible/FHLTools/SNParsing/ViewSNDictCell.swift`
- `FHLBible/FHLTools/SNParsing/ViewSNDictCell.xib`

### 1. 為標題 label 建立 IBOutlet

在 `ViewSNDictCell.swift` 新增：

```swift
@IBOutlet weak var labelOrigTitle: UILabel!
@IBOutlet weak var labelExpTitle: UILabel!
@IBOutlet weak var labelFormTitle: UILabel!
@IBOutlet weak var labelRemarkTitle: UILabel!
```

並在 xib 中完成連線。

### 2. 對標題 label 套用 Dynamic Type

```swift
private func applyDynamicTypeToSectionLabels() {
    let labels = [labelOrigTitle, labelExpTitle, labelFormTitle, labelRemarkTitle]
    labels.forEach { label in
        label?.font = UIFont.preferredFont(forTextStyle: .headline)
        label?.adjustsFontForContentSizeCategory = true
    }
}
```

### 3. 對上方三個按鈕標題套用 Dynamic Type

```swift
private func applyDynamicTypeToButtons() {
    let buttons = [btnSn, btnWord, btnOrig]
    buttons.forEach { button in
        button?.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
    }
}
```

### 4. 在初始化時套用

```swift
applyDynamicTypeToSectionLabels()
applyDynamicTypeToButtons()
```

---

## 四、修正結果

修正後，以下文字都會跟著系統字級放大：

- `原型`
- `簡義`
- `分析`
- `備註`
- 上方 SN / 字詞 / 原文字樣按鈕內容

而原本就會放大的 `ViewDisplayCell` 內容不受影響。

---

## 五、影響範圍

本次只修改 `ViewSNDictCell` 內部靜態元件的字型行為，不影響：

- parsing 資料來源
- 分段邏輯
- `ViewDisplayCell` 的 attributed text 產生流程

若之後仍有文字沒有跟著系統字級變化，應往下追查：

- `ViewDisplayCell`
- `DTextDrawToAttributeString`
- attributedText 建立字型的程式碼

---

## 六、建議驗證方式

1. 開啟 Parsing 的 SN 字典視圖
2. 到 iPhone 設定調大字級：
   - 設定 → 輔助使用 → 顯示與文字大小 → 更大字體
3. 確認以下項目會一起變大：
   - `原型 / 簡義 / 分析 / 備註`
   - 上方三個按鈕文字
4. 再確認超大字級下版面沒有被擠壓或截斷
