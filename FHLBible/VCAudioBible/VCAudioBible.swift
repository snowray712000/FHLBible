//
//  VCAudioBible.swift
//  FHLBible
//
//  Created by littlesnow on 2023/3/22.
//

import Foundation
import AVFoundation
import AVKit
import MediaPlayer
import SwiftUI
import FHLCommon
import OSLog

/// 「有聲聖經」：播放 FHL 的聖經 mp3（一章一檔）。
/// 畫面是 SwiftUI (`AudioBibleView`)，以 `VCAudioBible(book:chap:)` 建立後 push，不再經由 storyboard。
/// 播放核心仍是 `EasyAVPlayer.s` / `AVPlayer.s` / `DAudioBible.s` / `AudioBibleSetter.s`（關閉畫面後仍要繼續播放，所以不屬於這個畫面）。
class VCAudioBible : UIHostingController<AudioBibleView> {
    init(book: Int, chap: Int) {
        super.init(rootView: AudioBibleView(model: AudioBibleModel(book: book, chap: chap)))
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("VCAudioBible 不再由 storyboard 建立，請用 init(book:chap:)")
    }
}

/// 「有聲聖經」「有聲文字」共用：三個選項按鈕的外觀（圖示在上、說明在下，等寬）
struct AudioOptionLabel: View {
    let title: String
    let systemImage: String
    var monospacedDigit = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.title3)
            Text(verbatim: title).font(monospacedDigit ? .caption.monospacedDigit() : .caption)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 計時停止的剩餘時間。每秒都會變，所以顯示它的 view 要獨立出來（`AudioTimerTile`），
/// 否則整個畫面每秒重畫一次，會把正在打開的選單（版本、速度...）關掉。
protocol AudioTimerProviding: AnyObject {
    var timerText: String? { get }
}
struct AudioTimerTile<Model: AudioTimerProviding>: View {
    let model: Model
    var body: some View {
        if let text = model.timerText {
            AudioOptionLabel(title: text, systemImage: "timer", monospacedDigit: true)
        } else {
            AudioOptionLabel(title: NSLocalizedString("計時停止", comment: "計時停止"), systemImage: "timer")
        }
    }
}

/// 計時停止（睡覺用）可選的分鐘數；與舊的 `VCAudioStopTimer` 選項相同（30、60、1:30、2:00、3:00、4:00、6:00、8:00）。
let audioStopTimerMinutes = [30, 60, 90, 120, 180, 240, 360, 480]

func audioStopTimerMinutesTitle(_ minutes: Int) -> String {
    let f = DateComponentsFormatter()
    f.unitsStyle = .full
    f.allowedUnits = [.hour, .minute]
    return f.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
}

@Observable
final class AudioBibleModel: AudioTimerProviding {
    @ObservationIgnored private let logger = Logger(subsystem: "com.FHLBible", category: "VCAudioBible")

    /// 目前章節（會因為播到下一章而改變）
    var book: Int
    var chap: Int
    /// true 表示顯示「暫停」圖示（正在播放）
    var isPlaying = false
    var versionIdx: Int
    var speed: Float
    var loopMode: DAudioBible.LoopMode
    /// 計時停止的剩餘時間字串，nil 表示沒有在計時
    var timerText: String?
    /// 是否在計時（只在開始／結束時才變，選單內容用這個，不要用每秒都變的 `timerText`）
    var isTimerRunning = false
    /// 此版本沒有這一章時的說明，nil 表示正常
    var statusText: String?

    // 進度
    var position: Double = 0
    var duration: Double = 0
    @ObservationIgnored var isScrubbing = false

    // 下面按了，都會重新搜尋。若正在搜尋，又新的搜尋，執行緒會很亂，所以搜尋中要 disable
    var playEnabled = true
    var prevEnabled = true
    var nextEnabled = true
    var loopEnabled = true
    var versionEnabled = true

    let versions: [(id: Int, name: String)] = AudioBibleVersions.s.getNamesOrderById().compactMap { name in
        AudioBibleVersions.s.getIdWhereName(name).map { ($0, name) }
    }

    @ObservationIgnored private var events: IVCAudioBibleEvents = VCAudioBibleEvents()

    init(book: Int, chap: Int) {
        self.book = book
        self.chap = chap
        versionIdx = DAudioBible.s.versionIndex ?? 1
        speed = DAudioBible.s.speed
        loopMode = DAudioBible.s.loopMode
        updateTimerText()

        // 第2次進入此畫面
        if AVPlayer.s != nil {
            let cur = DAudioBible.s.addr
            let isTheSameAddr = cur != nil && book == cur!.book && chap == cur!.chap
            if isTheSameAddr {
                loadDuration()
                prevEnabled = true
                nextEnabled = true
                isPlaying = DAudioBible.s.isPlaying
                updateSliderValue()
            } else {
                position = 0
                duration = 0
                prevEnabled = false
                nextEnabled = false
                AVPlayer.s?.rate = 0
                isPlaying = false
            }

            addCallbacks()
            if isTheSameAddr == false {
                AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book, chap, 1), versionIdx)
            }
        } else { // 第1次初始化
            addCallbacks()
            AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book, chap, 1), versionIdx)
        }

        DBackgroundMusic.s.tp = .bible // 避免中控中心按下播放，是兩個音源
    }
    deinit {
        events.releaseEvents()
    }

    // MARK: - 顯示用

    var title: String {
        let bookName = BibleBookNames.getBookName(book, ManagerLangSet.s.curTpBookNameLang)
        return "\(bookName) \(chap)"
    }
    var versionName: String {
        AudioBibleVersions.s.getNameWhereId(versionIdx) ?? ""
    }
    var elapsedText: String {
        duration > 0 ? ctime2dashdashformat(position) : "-- : --"
    }
    var remainText: String {
        duration > 0 ? "-" + ctime2dashdashformat(max(duration - position, 0)) : "-- : --"
    }
    var canSeek: Bool { playEnabled && duration > 0 }

    // MARK: - 操作

    func playOrPause() {
        logger.info("clicked Play")
        guard let player = AVPlayer.s else {
            guard let mp3 = DAudioBible.s.mp3 else { return }
            EasyAVPlayer.s.replacePlayer(mp3)
            AVPlayer.s?.rate = speed
            isPlaying = true
            return
        }
        if player.rate > 0 {
            player.pause()
            isPlaying = false
            DAudioBible.s.isPlaying = false
        } else {
            isPlaying = true
            // 設定 rate 等同於呼叫 play, 但呼叫 play 等於 設定為 1.0
            player.rate = speed
            DAudioBible.s.isPlaying = true
        }
    }
    func goNext() {
        EasyAVPlayer.s.goNext()
        syncAddrFromCore()
    }
    func goPrev() {
        EasyAVPlayer.s.goPrev()
        syncAddrFromCore()
    }
    func setSpeed(_ newValue: Float) {
        if let player = AVPlayer.s, player.rate > 0, newValue != speed {
            player.rate = newValue
        }
        DAudioBible.s.speed = newValue
        speed = newValue
    }
    func setLoopMode(_ newValue: DAudioBible.LoopMode) {
        AudioBibleSetter.s.findWhenSetLoopMode(newValue, DAudioBible.s.loopMode)
        DAudioBible.s.loopMode = newValue
        loopMode = newValue
    }
    func setVersion(_ newValue: Int) {
        guard newValue != versionIdx else { return }
        let book = self.book, chap = self.chap
        DispatchQueue.main.async {
            AudioBibleSetter.s.trySetDAudioBibleAddrAndMp3(DAddress(book, chap, 1), newValue)
        }
        DAudioBible.s.versionIndex = newValue
        versionIdx = newValue
    }
    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        AVPlayer.s?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    func startStopTimer(minutes: Int) {
        let sec = Double(minutes) * 60.0
        timerText = ctime2dashdashformat(sec)
        isTimerRunning = true
        AudioBibleStopTimer.s.stopPrevTimerAndStartNewTimer(sec)
    }
    func cancelStopTimer() {
        // 有在計時時，會觸發 evCompleted（AudioBibleStopTimer 因此停止播放，畫面透過 completed 事件更新）
        AudioBibleStopTimer.s.cancelTimer()
        DAudioBible.s.secondRemainForStopTimer = 0.0
        updateTimerText()
    }

    // MARK: - 與背景／前景切換

    /// 進入背景前，不再接收事件
    func willResignActive() {
        events.releaseEvents()
    }
    /// 回到前景：目前章節、倒數、進度都可能在背景時變了，更新並重新綁定事件
    func didBecomeActive() {
        syncAddrFromCore()
        updateTimerText()
        loadDuration()
        updateSliderValue()
        addCallbacks()
    }

    // MARK: - 內部

    private func syncAddrFromCore() {
        if let addr = DAudioBible.s.addr {
            book = addr.book
            chap = addr.chap
        }
    }
    private func updateTimerText() {
        let sec = DAudioBible.s.secondRemainForStopTimer
        timerText = sec <= 0.0 ? nil : ctime2dashdashformat(sec)
        let running = sec > 0.0
        if isTimerRunning != running { isTimerRunning = running }
    }
    private func loadDuration() {
        if let d = AVPlayer.s?.currentItem?.duration.seconds, d.isFinite, d > 0 {
            duration = d
        }
    }
    private func updateSliderValue() {
        guard !isScrubbing, let player = AVPlayer.s else { return }
        let t = player.currentTime().seconds
        if t.isFinite { position = t }
    }

    private func addCallbacks() {
        events.releaseEvents() // 不重複綁定
        // 一開始
        events.addCallbackOfCheckingCurrentOfAddressOfVersion { [weak self] sender, pData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isPlaying = false
                self.playEnabled = false
                self.versionEnabled = false
                self.loopEnabled = false
                self.nextEnabled = false
                self.prevEnabled = false
            }
        }
        // 此章節可以 或 不行
        events.addCallbackOfCheckedCurrentOfAddressOfVersion { [weak self] sender, pData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.versionEnabled = true
                if let mp3 = DAudioBible.s.mp3, let addr = DAudioBible.s.addr {
                    self.statusText = nil
                    self.position = 0
                    self.duration = 0
                    self.book = addr.book
                    self.chap = addr.chap
                    EasyAVPlayer.s.replacePlayer(mp3)
                } else {
                    self.playEnabled = false
                    self.loopEnabled = false
                    self.nextEnabled = false
                    self.prevEnabled = false
                    self.position = 0
                    self.duration = 0
                    self.statusText = NSLocalizedString("無此章節", comment: "")
                }
            }
        }
        // 搜尋 next 前 / 後
        events.addCallbackOfSearchingNext { [weak self] sender, pData in
            self?.logger.info("vcaudiobible searching next")
            DispatchQueue.main.async {
                self?.nextEnabled = false
                self?.loopEnabled = false
                self?.versionEnabled = false
            }
        }
        events.addCallbackOfSearchedNext { [weak self] sender, pData in
            self?.logger.info("vcaudiobible searched next")
            DispatchQueue.main.async {
                self?.nextEnabled = true
                self?.loopEnabled = true
                self?.versionEnabled = true
            }
        }
        // 搜尋 prev 前 / 後
        events.addCallbackOfSearchingPrev { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.prevEnabled = false
                self?.loopEnabled = false
                self?.versionEnabled = false
            }
        }
        events.addCallbackOfSearchedPrev { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.prevEnabled = true
                self?.loopEnabled = true
                self?.versionEnabled = true
            }
        }
        // 準備播放後，已經成功取得歌曲資訊
        events.addCallbackOfCanSetSliderMax { [weak self] sender, pData in
            DispatchQueue.main.async {
                guard let self = self, AVPlayer.s?.currentItem?.duration != nil else { return }
                self.syncAddrFromCore()
                self.playEnabled = true
                self.position = 0
                self.loadDuration()
                self.updateSliderValue()

                if DAudioBible.s.isPlaying && AVPlayer.s!.rate == 0 {
                    self.playOrPause()
                }
            }
        }
        // 播放中，每經過 0.5 秒
        events.addCallbackOfTickOfPlaying { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateSliderValue()
            }
        }
        // 倒數功能，倒數中，每經過1秒
        events.addCallbackOfTickStopTimer { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateTimerText()
            }
        }
        // 倒數功能，倒數結束了（或被取消）
        events.addCallbackOfCompletedStopTimer { [weak self] sender, pData in
            DispatchQueue.main.async {
                self?.updateTimerText()
                self?.isPlaying = false
            }
        }
    }
}

struct AudioBibleView: View {
    @State var model: AudioBibleModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            header
            progress
            transport
            options
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .navigationTitle(NSLocalizedString("有聲聖經", comment: "有聲聖經"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: model.didBecomeActive()
            default: model.willResignActive()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: model.isPlaying)
                .accessibilityHidden(true)
            Text(verbatim: model.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            versionMenu
            if let status = model.statusText {
                Text(verbatim: status)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var versionMenu: some View {
        Menu {
            Picker(NSLocalizedString("版本", comment: "版本"), selection: Binding(get: { model.versionIdx }, set: { model.setVersion($0) })) {
                ForEach(model.versions, id: \.id) { v in
                    Text(verbatim: v.name).tag(v.id)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: model.versionName).font(.subheadline)
                Image(systemName: "chevron.up.chevron.down").font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .disabled(!model.versionEnabled)
    }

    private var progress: some View {
        AudioBibleProgressView(model: model)
    }

    private var transport: some View {
        HStack(spacing: 36) {
            Button {
                model.goPrev()
            } label: {
                Image(systemName: "backward.end.fill").font(.title)
            }
            .disabled(!model.prevEnabled)
            .accessibilityLabel(NSLocalizedString("上一章", comment: "上一章"))

            Button {
                model.playOrPause()
            } label: {
                Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .disabled(!model.playEnabled)
            .accessibilityLabel(model.isPlaying ? NSLocalizedString("暫停", comment: "暫停") : NSLocalizedString("播放", comment: "播放"))

            Button {
                model.goNext()
            } label: {
                Image(systemName: "forward.end.fill").font(.title)
            }
            .disabled(!model.nextEnabled)
            .accessibilityLabel(NSLocalizedString("下一章", comment: "下一章"))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    private var options: some View {
        HStack(spacing: 12) {
            loopMenu
            speedMenu
            timerMenu
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    private var loopMenu: some View {
        Menu {
            Picker(NSLocalizedString("播放方式", comment: "播放方式"), selection: Binding(get: { model.loopMode }, set: { model.setLoopMode($0) })) {
                Label(NSLocalizedString("連續播放", comment: "連續播放"), systemImage: "goforward").tag(DAudioBible.LoopMode.All)
                Label(NSLocalizedString("本卷循環", comment: "本卷循環"), systemImage: "repeat").tag(DAudioBible.LoopMode.Book)
                Label(NSLocalizedString("單章重複", comment: "單章重複"), systemImage: "repeat.1").tag(DAudioBible.LoopMode.Chap)
            }
        } label: {
            switch model.loopMode {
            case .All:  AudioOptionLabel(title: NSLocalizedString("連續播放", comment: "連續播放"), systemImage: "goforward")
            case .Book: AudioOptionLabel(title: NSLocalizedString("本卷循環", comment: "本卷循環"), systemImage: "repeat")
            case .Chap: AudioOptionLabel(title: NSLocalizedString("單章重複", comment: "單章重複"), systemImage: "repeat.1")
            }
        }
        .disabled(!model.loopEnabled)
    }

    private var speedMenu: some View {
        Menu {
            Picker(NSLocalizedString("速度", comment: "速度"), selection: Binding(get: { model.speed }, set: { model.setSpeed($0) })) {
                ForEach(VCPlayrate.speed, id: \.self) { s in
                    Text(verbatim: "\(s)x").tag(s)
                }
            }
        } label: {
            AudioOptionLabel(title: "\(model.speed)x", systemImage: "speedometer", monospacedDigit: true)
        }
    }

    private var timerMenu: some View {
        Menu {
            if model.isTimerRunning {
                Button(role: .destructive) {
                    model.cancelStopTimer()
                } label: {
                    Label(NSLocalizedString("取消計時", comment: "取消計時"), systemImage: "xmark.circle")
                }
            }
            ForEach(audioStopTimerMinutes, id: \.self) { minutes in
                Button(audioStopTimerMinutesTitle(minutes)) {
                    model.startStopTimer(minutes: minutes)
                }
            }
        } label: {
            AudioTimerTile(model: model)
        }
    }
}

/// 進度條：每 0.5 秒更新一次，獨立成 view，只有它會跟著重畫
private struct AudioBibleProgressView: View {
    @Bindable var model: AudioBibleModel

    var body: some View {
        VStack(spacing: 4) {
            Slider(value: $model.position, in: 0...max(model.duration, 1)) { editing in
                model.isScrubbing = editing
                if editing == false {
                    model.seek(to: model.position)
                }
            }
            .disabled(!model.canSeek)
            .accessibilityLabel(Text(NSLocalizedString("播放進度", comment: "播放進度")))
            .accessibilityValue(Text(verbatim: model.elapsedText))
            HStack {
                Text(verbatim: model.elapsedText)
                Spacer()
                Text(verbatim: model.remainText)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }
}
