# FHL Bible — SN Dict Dynamic Type Fix (AI Reference)

## SUMMARY

The SN dict cell in parsing view had mixed font-scaling behavior:

- section labels like `原型 / 簡義 / 分析 / 備註` did **not** scale with iOS Dynamic Type
- top row button titles like SN / word / original-word also did **not** scale
- embedded `ViewDisplayCell` text already appeared to scale through a different rendering path

This fix adds Dynamic Type support to the static labels and top-row button titles inside `ViewSNDictCell`.

**Affected files**:
- `FHLBible/FHLTools/SNParsing/ViewSNDictCell.swift`
- `FHLBible/FHLTools/SNParsing/ViewSNDictCell.xib`

---

## 1. Problem Description

### Observed symptom

In the parsing dictionary popup / cell UI:

- `原型`
- `簡義`
- `分析`
- `備註`
- top row values displayed by `btnSn`, `btnWord`, `btnOrig`

did not enlarge when the system font size was increased.

However, content areas rendered by:

- `showerXExp`
- `showerXForm`
- `showerXRemark`

appeared to enlarge already, because they are `ViewDisplayCell` subviews using a separate text rendering path.

---

## 2. Root Cause

### 2.1 Static labels in xib used fixed fonts only

`ViewSNDictCell.xib` defined labels with fixed bold system font size 18:

```xml
<fontDescription key="fontDescription" type="boldSystem" pointSize="18"/>
```

There was no Dynamic Type configuration in code for those labels.

### 2.2 Top row text was inside `UIButton`, not `UILabel`

The 3 highlighted upper texts were actually button titles:

- `btnSn`
- `btnWord`
- `btnOrig`

So even after fixing the section labels, those 3 still would not scale unless `button.titleLabel` was also configured for Dynamic Type.

---

## 3. Fix

### 3.1 Added IBOutlet references for section labels

In `ViewSNDictCell.swift`:

```swift
@IBOutlet weak var labelOrigTitle: UILabel!
@IBOutlet weak var labelExpTitle: UILabel!
@IBOutlet weak var labelFormTitle: UILabel!
@IBOutlet weak var labelRemarkTitle: UILabel!
```

And connected them in `ViewSNDictCell.xib`.

### 3.2 Added Dynamic Type setup for section labels

```swift
private func applyDynamicTypeToSectionLabels() {
    let labels = [labelOrigTitle, labelExpTitle, labelFormTitle, labelRemarkTitle]
    labels.forEach { label in
        label?.font = UIFont.preferredFont(forTextStyle: .headline)
        label?.adjustsFontForContentSizeCategory = true
    }
}
```

### 3.3 Added Dynamic Type setup for top buttons

```swift
private func applyDynamicTypeToButtons() {
    let buttons = [btnSn, btnWord, btnOrig]
    buttons.forEach { button in
        button?.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
    }
}
```

### 3.4 Applied during initialization

Inside `initedFromXib()`:

```swift
applyDynamicTypeToSectionLabels()
applyDynamicTypeToButtons()
```

---

## 4. Why This Fix Works

- `UIFont.preferredFont(forTextStyle:)` gives a Dynamic Type-aware font
- `adjustsFontForContentSizeCategory = true` makes the view respond to user font size changes
- labels and button title labels now both participate in Dynamic Type
- `ViewDisplayCell` content path remains untouched

---

## 5. Scope

This fix affects only the static text elements inside `ViewSNDictCell`:

- section title labels
- top row button titles

It does **not** modify:

- `ViewDisplayCell`
- attributed text generation in `DTextDrawToAttributeString`
- parsing data logic

If future text still does not scale, investigation should continue in the attributed-text rendering path.

---

## 6. Validation

Recommended validation:

1. Open the parsing SN dict UI
2. Increase iOS text size in:
   - Settings → Accessibility → Display & Text Size → Larger Text
3. Confirm these elements enlarge:
   - `原型 / 簡義 / 分析 / 備註`
   - SN / word / original-word on the top row
4. Verify layout still behaves correctly under large accessibility sizes
