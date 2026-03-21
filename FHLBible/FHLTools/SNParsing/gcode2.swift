//
//  gcode2.swift
//  FHLBible
//
//  Created by littlesnow on 2026/3/2.
//

import Foundation

private func replaceAllLiteral(_ text: String, _ search: String, _ replacement: String) -> String {
    text.replacingOccurrences(of: search, with: replacement)
}

private func replaceByTable(_ text: String, from fromList: [String], to toList: [String]) -> String {
    guard fromList.count == toList.count else { return text }
    var out = text
    for i in 0..<fromList.count {
        out = replaceAllLiteral(out, fromList[i], toList[i])
    }
    return out
}


private func regexReplace(_ input: String, pattern: String, template: String) -> String {
    guard let re = try? NSRegularExpression(pattern: pattern) else { return input }
    let range = NSRange(input.startIndex..<input.endIndex, in: input)
    return re.stringByReplacingMatches(in: input, range: range, withTemplate: template)
}

func preprocessForGcode2(_ inputValue: Any?) -> String {

// itxt = '' if input_value is None else str(input_value)

// None 變成空字串，其他型別都轉成字串。
// if len(itxt) == 0: return itxt

// 空字串就直接回傳，不做後續替換。
// txt = re.sub(r's([-\r\n,.:;}{) ])', r'"\1', itxt)

// 找到 s 後面接「特定分隔符」時，把 s 改成 "。
// 例如：as, → a",、xs  → x" 。
// txt = re.sub(r's$', '"', txt)

// 如果字串最後一個字是 s，也改成 "。

    let itxt = inputValue.map { String(describing: $0) } ?? ""
    if itxt.isEmpty { return itxt }

    var txt = regexReplace(
        itxt,
        pattern: #"s([-\r\n,.:;}{) ])"#,
        template: #""$1"#
    )
    txt = regexReplace(
        txt,
        pattern: #"s$"#,
        template: "\""
    )
    return txt
}

/// 對應 Python: gcode_2(input_value)
func gcode2(_ inputValue: Any?) -> String {
    let itxt: String = {
        guard let v = inputValue else { return "" }
        return String(describing: v)
    }()
    if itxt.isEmpty { return itxt }

    var txt = regexReplace(itxt, pattern: #"s([-\r\n,.:;}{) ])"#, template: #""$1"#)
    txt = regexReplace(txt, pattern: #"s$"#, template: "\"")

    // 舊資料相容：U+0358 視為 u（若需要可打開）
    txt = txt.replacingOccurrences(of: "\u{0358}", with: "u")

    let orgb = [
        "Aj/", "Hj/", "Wj/", "a$/", "h$/", "w$/",
        "AJ/", "HJ/", "WJ/", "a%/", "h%/", "w%/",
        "A]/", "H]/", "W]/", "a</", "h</", "w</",
        "A^/", "H^/", "W^/", "a@/", "h@/", "w@/",
        "A[/", "H[/", "W[/", "a~/", "h~/", "w~/",
        "A&/", "H&/", "W&/", "a!/", "h!/", "w!/",
        "A\\/", "H\\/", "W\\/", "a*/", "h*/", "w*/",
        "A|/", "H|/", "W|/", "a+/", "h+/", "w+/",
        "a;/", "h;/", "w;/",
        "A/", "H/", "W/", "a/", "h/", "w/",
        "a'/", "h'/", "w'/", "av/", "hv/", "wv/",
        "A&", "E&", "H&", "I&", "O&", "U&", "W&", "a!", "e!", "h!", "i!", "o!", "u!", "w!",
        "a'", "h'", "i'", "u'", "w'",
        "a;", "e;", "h;", "i;", "o;", "u;", "w;",
        "i>", "u>", "i?", "u?",
        "AJ", "EJ", "HJ", "IJ", "OJ", "UJ", "WJ", "RJ", "a%", "e%", "h%", "i%", "o%", "u%", "w%", "r%",
        "A[", "E[", "H[", "I[", "O[", "U[", "W[", "a~", "e~", "h~", "i~", "o~", "u~", "w~",
        "A\\", "E\\", "H\\", "I\\", "O\\", "U\\", "W\\", "a*", "e*", "h*", "i*", "o*", "u*", "w*",
        "A]", "E]", "H]", "I]", "O]", "U]", "W]", "a<", "e<", "h<", "i<", "o<", "u<", "w<",
        "A^", "E^", "H^", "I^", "O^", "U^", "W^", "a@", "e@", "h@", "i@", "o@", "u@", "w@",
        "Aj", "Ej", "Hj", "Ij", "Oj", "Wj", "a$", "e$", "h$", "i$", "o$", "u$", "w$",
        "Aj", "Ej", "Hj", "Ij", "Oj", "Wj",
        "A;", "E;", "H;", "I;", "O;", "W;",
        "av", "ev", "hv", "iv", "ov", "uv", "wv",
        "A|", "E|", "H|", "I|", "O|", "U|", "W|", "a+", "e+", "h+", "i+", "o+", "u+", "w+",
        "i:", "u:"
    ]

    let orga = [
        "A$/", "H$/", "W$/", "aj/", "hj/", "wj/",
        "A%/", "H%/", "W%/", "aJ/", "hJ/", "wJ/",
        "A</", "H</", "W</", "a]/", "h]/", "w]/",
        "A@/", "H@/", "W@/", "a^/", "h^/", "w^/",
        "A~/", "H~/", "W~/", "a[/", "h[/", "w[/",
        "A!/", "H!/", "W!/", "a&/", "h&/", "w&/",
        "A*/", "H*/", "W*/", "a\\/", "h\\/", "w\\/",
        "A+/", "H+/", "W+/", "a|/", "h|/", "w|/",
        "a;/", "h;/", "w;/",
        "A/", "H/", "W/", "a/", "h/", "w/",
        "av/", "hv/", "wv/", "a'/", "h'/", "w'/",
        "A!", "E!", "H!", "I!", "O!", "U!", "W!", "a&", "e&", "h&", "i&", "o&", "u&", "w&",
        "a'", "h'", "i'", "u'", "w'",
        "a;", "e;", "h;", "i;", "o;", "u;", "w;",
        "i>", "u>", "i?", "u?",
        "A%", "E%", "H%", "I%", "O%", "U%", "W%", "R%", "aJ", "eJ", "hJ", "iJ", "oJ", "uJ", "wJ", "rJ",
        "A~", "E~", "H~", "I~", "O~", "U~", "W~", "a[", "e[", "h[", "i[", "o[", "u[", "w[",
        "A*", "E*", "H*", "I*", "O*", "U*", "W*", "a\\", "e\\", "h\\", "i\\", "o\\", "u\\", "w\\",
        "A<", "E<", "H<", "I<", "O<", "U<", "W<", "a]", "e]", "h]", "i]", "o]", "u]", "w]",
        "A@", "E@", "H@", "I@", "O@", "U@", "W@", "a^", "e^", "h^", "i^", "o^", "u^", "w^",
        "A$", "E$", "H$", "I$", "O$", "W$", "aj", "ej", "hj", "ij", "oj", "uj", "wj",
        "Aj", "Ej", "Hj", "Ij", "Oj", "Wj",
        "A;", "E;", "H;", "I;", "O;", "W;",
        "av", "ev", "hv", "iv", "ov", "uv", "wv",
        "A+", "E+", "H+", "I+", "O+", "U+", "W+", "a|", "e|", "h|", "i|", "o|", "u|", "w|",
        "i:", "u:"
    ]

    let AD = [
        "\"", "#", "{", "}",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "`",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "w", "x", "y", "z"
    ]

    let UAD = [
        "ς", "᾽", "·", ";",
        "Α", "Β", "Χ", "Δ", "Ε", "Φ", "Γ", "Η", "Ι", "Κ", "Λ", "Μ", "Ν", "Ο", "Π", "Θ", "Ρ", "Σ", "Τ", "Υ", "´", "Ω", "Ξ", "Ψ", "Ζ", "`",
        "α", "β", "χ", "δ", "ε", "φ", "γ", "η", "ι", "κ", "λ", "μ", "ν", "ο", "π", "θ", "ρ", "σ", "τ", "υ", "ω", "ξ", "ψ", "ζ"
    ]

    let uorg = [
        "ᾈ", "ᾘ", "ᾨ", "ᾀ", "ᾐ", "ᾠ",
        "ᾉ", "ᾙ", "ᾩ", "ᾁ", "ᾑ", "ᾡ",
        "ᾊ", "ᾚ", "ᾪ", "ᾂ", "ᾒ", "ᾢ",
        "ᾋ", "ᾛ", "ᾫ", "ᾃ", "ᾓ", "ᾣ",
        "ᾌ", "ᾜ", "ᾬ", "ᾄ", "ᾔ", "ᾤ",
        "ᾍ", "ᾝ", "ᾭ", "ᾅ", "ᾕ", "ᾥ",
        "ᾎ", "ᾞ", "ᾮ", "ᾆ", "ᾖ", "ᾦ",
        "ᾏ", "ᾟ", "ᾯ", "ᾇ", "ᾗ", "ᾧ",
        "ᾲ", "ῂ", "ῲ",
        "ᾼ", "ῌ", "ῼ", "ᾳ", "ῃ", "ῳ",
        "ᾴ", "ῄ", "ῴ", "ᾷ", "ῇ", "ῷ",
        "Ἅ", "Ἕ", "Ἥ", "Ἵ", "Ὅ", "Ὕ", "Ὥ", "ἅ", "ἕ", "ἥ", "ἵ", "ὅ", "ὕ", "ὥ",
        "ᾶ", "ῆ", "ῖ", "ῦ", "ῶ",
        "ὰ", "ὲ", "ὴ", "ὶ", "ὸ", "ὺ", "ὼ",
        "ϊ", "ϋ", "ΐ", "ΰ",
        "Ἁ", "Ἑ", "Ἡ", "Ἱ", "Ὁ", "Ὑ", "Ὡ", "Ῥ", "ἁ", "ἑ", "ἡ", "ἱ", "ὁ", "ὑ", "ὡ", "ῥ",
        "Ἄ", "Ἔ", "Ἤ", "Ἴ", "Ὄ", "὜", "Ὤ", "ἄ", "ἔ", "ἤ", "ἴ", "ὄ", "ὔ", "ὤ",
        "Ἆ", "἞", "Ἦ", "Ἶ", "὎", "὞", "Ὦ", "ἆ", "἖", "ἦ", "ἶ", "὆", "ὖ", "ὦ",
        "Ἂ", "Ἒ", "Ἢ", "Ἲ", "Ὂ", "὚", "Ὢ", "ἂ", "ἒ", "ἢ", "ἲ", "ὂ", "ὒ", "ὢ",
        "Ἃ", "Ἓ", "Ἣ", "Ἳ", "Ὃ", "Ὓ", "Ὣ", "ἃ", "ἓ", "ἣ", "ἳ", "ὃ", "ὓ", "ὣ",
        "Ἀ", "Ἐ", "Ἠ", "Ἰ", "Ὀ", "Ὠ", "ἀ", "ἐ", "ἠ", "ἰ", "ὀ", "ὐ", "ὠ",
        "Ἀ", "Ἐ", "Ἠ", "Ἰ", "Ὀ", "Ὠ",
        "Ὰ", "Ὲ", "Ὴ", "Ὶ", "Ὸ", "Ὼ",
        "ά", "έ", "ή", "ί", "ό", "ύ", "ώ",
        "Ἇ", "἟", "Ἧ", "Ἷ", "὏", "Ὗ", "Ὧ", "ἇ", "἗", "ἧ", "ἷ", "὇", "ὗ", "ὧ",
        "ῒ", "ῢ"
    ]

    var ntxt = replaceByTable(txt, from: orga, to: uorg)
    ntxt = replaceByTable(ntxt, from: orgb, to: uorg)
    ntxt = replaceByTable(ntxt, from: AD, to: UAD)

    return ntxt
}
