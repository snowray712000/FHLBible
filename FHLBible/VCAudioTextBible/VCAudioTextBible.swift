//
//  VCAudioTextBible.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/27.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation
import FHLCommon

/// 「有聲文字」：用 TTS 朗讀經文的播放畫面。
/// 畫面是 SwiftUI (`AudioTextBibleView`)，以 `VCAudioTextBible(addr:vers:)` 建立後 push，不再經由 storyboard。
/// 播放核心仍是 `AudioTextBibleTTSCore.s`（關閉畫面後仍要繼續播放，所以不屬於這個畫面）。
class VCAudioTextBible : UIHostingController<AudioTextBibleView> {
    init(addr: VerseRange, vers: [String]) {
        super.init(rootView: AudioTextBibleView(model: AudioTextBibleModel(addr: addr, vers: vers)))
        // SwiftUI 這端沒有 UINavigationController 可以 push，所以由這裡接手
        rootView.onOpenSpeed = { [weak self] in
            self?.navigationController?.pushViewController(VCAudioTextSpeed(), animated: true)
        }
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("VCAudioTextBible 不再由 storyboard 建立，請用 init(addr:vers:)")
    }
}

/// 計時停止（睡覺用）可選的分鐘數；與舊的 `VCAudioStopTimer` 選項相同（30、60、1:30、2:00、3:00、4:00、6:00、8:00）。
private let stopTimerMinutes = [30, 60, 90, 120, 180, 240, 360, 480]

@Observable
final class AudioTextBibleModel {
    /// 目前章節（會因為播到下一章而改變）
    var addrStr: String
    /// 使用者是否是「播放中」(含取得資料中)；與 `ttsCore.statePlaying != .stop` 同義
    var isPlaying = false
    var loopMode: DAudioBible.LoopMode {
        didSet { ttsCore.loopMode = loopMode }
    }
    /// 計時停止的剩餘時間字串，nil 表示沒有在計時
    var timerText: String?

    @ObservationIgnored private var ttsCore: AudioTextBibleTTSCore { AudioTextBibleTTSCore.s }

    init(addr: VerseRange, vers: [String]) {
        let core = AudioTextBibleTTSCore.s
        core.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(addr)
        core.setVersions(vers)

        addrStr = core.addrStr ?? ""
        loopMode = core.loopMode
        isPlaying = core.statePlaying != .stop
        // 重新進入畫面時，計時可能還在跑
        if AudioBibleTextStopTimer.s.timer != nil {
            timerText = ctime2dashdashformat(AudioBibleTextStopTimer.s.secondRemain)
        }
        setUpEvents()

        // 背景聲音，應該只要有一個，所以要有個全域變數，知道目前是 有聲聖經 還是 有聲文字
        DBackgroundMusic.s.tp = .bibleText // 避免中控中心按下播放，是兩個音源
    }
    private func setUpEvents() {
        // 核心播放，若已經換章了，身為 ui 要更新一下章節。
        ttsCore.addrChanged$.addCallback(key) { [weak self] sender, pData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.addrStr = self.ttsCore.addrStr ?? ""
                self.refreshPlaying()
            }
        }
        // 倒數時間播放，每秒更新剩餘時間；完成時，播放按鈕要變成「播放」
        AudioBibleTextStopTimer.s.evTick.addCallback(key) { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.timerText = ctime2dashdashformat(AudioBibleTextStopTimer.s.secondRemain)
            }
        }
        AudioBibleTextStopTimer.s.evCompleted.addCallback(key) { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.timerText = nil
                self?.refreshPlaying()
            }
        }
    }
    private var key: String { "AudioTextBibleModel\(ObjectIdentifier(self).hashValue)" }

    deinit {
        let key = "AudioTextBibleModel\(ObjectIdentifier(self).hashValue)"
        ttsCore.addrChanged$.clearCallback(key)
        AudioBibleTextStopTimer.s.evTick.clearCallback(key)
        AudioBibleTextStopTimer.s.evCompleted.clearCallback(key)
    }

    /// 從主畫面切回來、計時結束、換章時，核心的播放狀態可能已經改變
    func refreshPlaying() {
        isPlaying = ttsCore.statePlaying != .stop
    }

    func playOrPause() {
        if ttsCore.statePlaying == .stop {
            ttsCore.playAndSetPlayingState()
        } else {
            ttsCore.pauseAndSetPlayingState()
        }
        refreshPlaying()
    }
    func goNext() {
        ttsCore.goNextForce()
        refreshPlaying()
    }
    func goPrev() {
        ttsCore.goPrevForce()
        refreshPlaying()
    }

    func startStopTimer(minutes: Int) {
        let sec = Double(minutes) * 60.0
        timerText = ctime2dashdashformat(sec)
        AudioBibleTextStopTimer.s.stopPrevTimerAndStartNewTimer(sec)
    }
    func cancelStopTimer() {
        // 注意：沒有在計時時 cancelTimer 什麼都不做；有在計時時，會觸發 evCompleted（核心因此暫停播放）
        AudioBibleTextStopTimer.s.cancelTimer()
        AudioBibleTextStopTimer.s.secondRemain = 0.0
        timerText = nil
        refreshPlaying()
    }
}

struct AudioTextBibleView: View {
    @State var model: AudioTextBibleModel
    /// 由 `VCAudioTextBible` 提供：push「有聲文字速度」
    var onOpenSpeed: () -> Void = {}

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            header
            transport
            options
            Spacer()
            notes
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .navigationTitle(NSLocalizedString("有聲文字", comment: "有聲文字"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            // 從主畫面切回來時，要設定一下 play 按鈕。
            if phase == .active { model.refreshPlaying() }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: model.isPlaying)
                .accessibilityHidden(true)
            Text(verbatim: model.addrStr)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
        }
    }

    private var transport: some View {
        HStack(spacing: 36) {
            Button {
                model.goPrev()
            } label: {
                Image(systemName: "backward.end.fill").font(.title)
            }
            .accessibilityLabel(NSLocalizedString("上一章", comment: "上一章"))

            Button {
                model.playOrPause()
            } label: {
                Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .accessibilityLabel(model.isPlaying ? NSLocalizedString("暫停", comment: "暫停") : NSLocalizedString("播放", comment: "播放"))

            Button {
                model.goNext()
            } label: {
                Image(systemName: "forward.end.fill").font(.title)
            }
            .accessibilityLabel(NSLocalizedString("下一章", comment: "下一章"))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    private var options: some View {
        HStack(spacing: 12) {
            loopMenu
            Button(action: onOpenSpeed) {
                optionLabel(NSLocalizedString("速度", comment: "速度"), systemImage: "speedometer")
            }
            timerMenu
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    /// 三個選項共用：圖示在上、說明在下，等寬
    private func optionLabel(_ title: String, systemImage: String, monospacedDigit: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.title3)
            Text(verbatim: title).font(monospacedDigit ? .caption.monospacedDigit() : .caption)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var loopMenu: some View {
        Menu {
            Picker(NSLocalizedString("播放方式", comment: "播放方式"), selection: $model.loopMode) {
                Label(NSLocalizedString("連續播放", comment: "連續播放"), systemImage: "goforward").tag(DAudioBible.LoopMode.All)
                Label(NSLocalizedString("本卷循環", comment: "本卷循環"), systemImage: "repeat").tag(DAudioBible.LoopMode.Book)
                Label(NSLocalizedString("單章重複", comment: "單章重複"), systemImage: "repeat.1").tag(DAudioBible.LoopMode.Chap)
            }
        } label: {
            switch model.loopMode {
            case .All:  optionLabel(NSLocalizedString("連續播放", comment: "連續播放"), systemImage: "goforward")
            case .Book: optionLabel(NSLocalizedString("本卷循環", comment: "本卷循環"), systemImage: "repeat")
            case .Chap: optionLabel(NSLocalizedString("單章重複", comment: "單章重複"), systemImage: "repeat.1")
            }
        }
    }

    private var timerMenu: some View {
        Menu {
            if model.timerText != nil {
                Button(role: .destructive) {
                    model.cancelStopTimer()
                } label: {
                    Label(NSLocalizedString("取消計時", comment: "取消計時"), systemImage: "xmark.circle")
                }
            }
            ForEach(stopTimerMinutes, id: \.self) { minutes in
                Button(minutesTitle(minutes)) {
                    model.startStopTimer(minutes: minutes)
                }
            }
        } label: {
            if let text = model.timerText {
                optionLabel(text, systemImage: "timer", monospacedDigit: true)
            } else {
                optionLabel(NSLocalizedString("計時停止", comment: "計時停止"), systemImage: "timer")
            }
        }
    }
    private func minutesTitle(_ minutes: Int) -> String {
        let f = DateComponentsFormatter()
        f.unitsStyle = .full
        f.allowedUnits = [.hour, .minute]
        return f.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(NSLocalizedString("聖經中的希臘文是古希臘文，而文字發音系統(TTS) 是現代希臘文，希伯來文亦同，自行斟酌使用。", comment: "聖經中的希臘文是古希臘文，而文字發音系統(TTS) 是現代希臘文，希伯來文亦同，自行斟酌使用。"), systemImage: "info.circle")
            Label(NSLocalizedString("當鎖定畫面播放時，進度列時間僅供參考，堪用堪用。", comment: "當鎖定畫面播放時，進度列時間僅供參考，堪用堪用。"), systemImage: "info.circle")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
