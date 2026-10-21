//
//  VCAudioTextSpeed.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/2.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation
import FHLCommon

/// 「有聲文字速度」：每個語言一個速度 (x0.25 ~ x2.00，共 8 段)，放開滑桿才存並試聽。
/// 畫面是 SwiftUI (`AudioTextSpeedView`)，以 `VCAudioTextSpeed()` 建立後 push，不再經由 storyboard。
class VCAudioTextSpeed : UIHostingController<AudioTextSpeedView> {
    init() {
        super.init(rootView: AudioTextSpeedView(model: AudioTextSpeedModel()))
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: AudioTextSpeedView(model: AudioTextSpeedModel()))
    }
}

/// 一列：語言名稱 + 試聽用的語音
struct AudioTextSpeedLang: Identifiable {
    let id: Int
    /// 各語言用自己的文字顯示，不翻譯
    let name: String
}

@Observable
final class AudioTextSpeedModel {
    /// 順序固定，要與 `TTSEngineGetter.ttsArray`、`ManagerAudioTextSpeed` 的陣列順序一致
    let langs: [AudioTextSpeedLang] = [
        AudioTextSpeedLang(id: 0, name: "中文"),
        AudioTextSpeedLang(id: 1, name: "English"),
        AudioTextSpeedLang(id: 2, name: "Hebrew"),
        AudioTextSpeedLang(id: 3, name: "Greek"),
        AudioTextSpeedLang(id: 4, name: "にほんご"),
        AudioTextSpeedLang(id: 5, name: "한국어"),
        AudioTextSpeedLang(id: 6, name: "Tiếng Việt"),
        AudioTextSpeedLang(id: 7, name: "ру́сский язы́к"),
    ]
    /// 每個語言目前滑桿的位置，0...7 的整數 (以 Double 存，給 Slider 用)。
    var steps: [Double]

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()

    init() {
        steps = ManagerAudioTextSpeed.s.curSpeed.map { Double(AudioTextSpeedModel.speed2step($0)) }
    }
    deinit {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // 0: 0.25 1: 0.50 2: 0.75 3:1.0 4: 1.25 5: 1.50 6: 1.75 7: 2.00
    static func step2speed(_ i: Int) -> Float { (Float(i) + 1.0) * 0.25 }
    static func speed2step(_ v: Float) -> Int { min(7, max(0, Int((v / 0.25 - 1).rounded()))) }
    static func speed2string(_ v: Float) -> String { String(format: "%.2f", v) }

    func speed(of idx: Int) -> Float { Self.step2speed(Int(steps[idx].rounded())) }
    func label(of idx: Int) -> String { "x" + Self.speed2string(speed(of: idx)) }

    /// 放開滑桿時：存起來，並用新速度試聽
    func commit(_ idx: Int) {
        var speeds = ManagerAudioTextSpeed.s.curSpeed
        speeds[idx] = speed(of: idx)
        ManagerAudioTextSpeed.s.updateSpeed(speeds)
        playSample(idx)
    }

    func playSample(_ i: Int) {
        guard let tts = engine(i) else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let r1 = AVSpeechUtterance(string: sampleText(i))
        r1.voice = tts
        r1.rate = 0.5 * speed(of: i)
        synthesizer.speak(r1)
    }
    private func sampleText(_ i: Int) -> String {
        switch i {
        case 0: return ManagerLangSet.s.curIsGb ? TTSEngineSamples.zhCN : TTSEngineSamples.zhTW
        case 1: return TTSEngineSamples.enUS
        case 2: return TTSEngineSamples.hebrew
        case 3: return TTSEngineSamples.greek
        case 4: return TTSEngineSamples.jp
        case 5: return TTSEngineSamples.korean
        case 6: return TTSEngineSamples.viVN
        case 7: return TTSEngineSamples.ru
        default: return ""
        }
    }
    private func engine(_ i: Int) -> AVSpeechSynthesisVoice? {
        switch i {
        case 0: return ManagerLangSet.s.curIsGb ? TTSEngineGetter.zhCN : TTSEngineGetter.zhTW
        case 1: return TTSEngineGetter.enUS
        case 2: return TTSEngineGetter.hebrew
        case 3: return TTSEngineGetter.greek
        case 4: return TTSEngineGetter.jp
        case 5: return TTSEngineGetter.korean
        case 6: return TTSEngineGetter.viVN
        case 7: return TTSEngineGetter.ru
        default: return nil
        }
    }
}

struct AudioTextSpeedView: View {
    @State var model: AudioTextSpeedModel

    var body: some View {
        List {
            Section {
                ForEach(model.langs) { lang in
                    row(lang)
                }
            } footer: {
                Text(NSLocalizedString("若點擊無聲音，是你的手機不支援此語言語音。若全部都沒聲音，那就是工程師的Bug了。", comment: "若點擊無聲音，是你的手機不支援此語言語音。若全部都沒聲音，那就是工程師的Bug了。"))
            }
        }
        .navigationTitle(NSLocalizedString("有聲文字速度", comment: "有聲文字速度"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ lang: AudioTextSpeedLang) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: lang.name)
                Spacer()
                Text(verbatim: model.label(of: lang.id))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button {
                    model.playSample(lang.id)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(NSLocalizedString("試聽", comment: "試聽"))
            }
            Slider(value: $model.steps[lang.id], in: 0...7, step: 1) { editing in
                if editing == false {
                    model.commit(lang.id)
                }
            }
            .accessibilityLabel(Text(verbatim: lang.name))
            .accessibilityValue(Text(verbatim: model.label(of: lang.id)))
        }
    }
}
