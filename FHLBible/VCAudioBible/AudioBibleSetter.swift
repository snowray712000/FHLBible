
import Foundation
import CoreMedia
import AVFoundation

// 開發 VCAudioBible 時用的
// 分為 ing ed 兩大類
// 承上， ing 通常是綁定讓控制項 isEnable = false 時候用的
class AudioBibleSetter {
    static var s = AudioBibleSetter ()
    private init(){
        self.evCheckedAddr.addCallback({ [weak self] sender, pData in
            if pData! {
                self?.findNext()
                self?.findPrev()
            }
        }, "AudioBibleSetter")
    }
    deinit{
        self.cleanAllEventCallbacks()
    }
    
    var evCheckingAddr = IjnEventAdvancedAny()
    var evCheckedAddr: IjnEventAdvanced<AudioBibleSetter,Bool> = IjnEventAdvanced()
    var evCheckingAddrNext = IjnEventAdvancedAny()
    var evCheckedAddrNext = IjnEventAdvancedAny()
    var evCheckingAddrPrev = IjnEventAdvancedAny()
    var evCheckedAddrPrev = IjnEventAdvancedAny()
    
    private func cleanAllEventCallbacks(){
        for a1 in [evCheckingAddr,evCheckedAddrNext,evCheckingAddrNext,evCheckedAddrPrev,evCheckingAddrPrev]{
            a1.clearCallback()
        }
        evCheckedAddr.clearCallback()
    }
    
    // if true, addr mp3 will be set, or 不作任何事
    // 想像，這個會是在 viewDidLoad 時被呼叫，也會在 SetVersionIndex 的按鈕被按下後呼叫
    // 想像，evCheckingAddr 會把 播放/下一首/上一首/切換版本 的按鈕 isEnable = false
    // 承上，evCheckedAddr 會 if pData as! Bool. play isEnable or 顯示此版本沒有
    //
    // if true, will find next, prev continuely
    func trySetDAudioBibleAddrAndMp3(_ addr:DAddress,_ versionIndex:Int){
        evCheckingAddr.trigger(nil, nil)
        let easyCheckAudioUrl = EasyCheckAudioUrl()
        easyCheckAudioUrl.evChecked.addCallback { [weak self] sender, pData in
            if self == nil { return }
            if sender! {
                DAudioBible.s.addr = addr
                DAudioBible.s.mp3 = pData!
                self?.evCheckedAddr.trigger(self, true)
            } else {
                DAudioBible.s.addr = nil
                DAudioBible.s.mp3 = nil
                EasyAVPlayer.s.replacePlayer("")
                self?.evCheckedAddr.trigger(self, false)
            }
        }
        easyCheckAudioUrl.mainAsync(versionIndex, addr.book, addr.chap)
    }
    func setNextToCurrAndFindNext(){
        DAudioBible.s.offsetToPrev()
        self.findNext()
    }
    // 想像，在按下 Next 或播放完時，會呼叫這個
    private func findNext(){
        evCheckingAddrNext.trigger(nil, nil)
        let findNextHelper = AudioBibleNextPrevGetter()
        findNextHelper.evNext.addCallback({ sender, pData in
            DAudioBible.s.mp3Next = findNextHelper.mp3Next
            DAudioBible.s.addrNext = DAddress(findNextHelper.bookNext,findNextHelper.chapNext,1)
            self.evCheckedAddrNext.trigger(nil, nil)
        })
        let r1 = DAudioBible.s
        findNextHelper.mainAsync(addr: r1.addr!, versionIndex: r1.versionIndex!, loopMode: r1.loopMode, mp3: r1.mp3!, isFindNext: true, isFindPrev: false)
    }
    func setPrevToCurrAndFindPrev(){
        DAudioBible.s.offsetToNext()
        self.findPrev()
    }
    private func findPrev(){
        evCheckingAddrPrev.trigger(nil, nil)
        let findPrevHelper = AudioBibleNextPrevGetter()
        findPrevHelper.evPrev.addCallback({ sender, pData in
            DAudioBible.s.mp3Prev = findPrevHelper.mp3Prev
            DAudioBible.s.addrPrev = DAddress(findPrevHelper.bookPrev,findPrevHelper.chapPrev,1)
            self.evCheckedAddrPrev.trigger(nil, nil)
        })
        let r1 = DAudioBible.s
        findPrevHelper.mainAsync(addr:r1.addr!, versionIndex: r1.versionIndex!, loopMode: r1.loopMode, mp3: r1.mp3!, isFindNext: false, isFindPrev: true)
    }
    // 算 Next Prev
    // 兩個參數，才會讓使用者知道，要先使用這個，才去設定全域變數
    func findWhenSetLoopMode(_ modeNew: DAudioBible.LoopMode,_ modeOld: DAudioBible.LoopMode){
        if modeNew != modeOld {
            findNext()
            findPrev()
        }
    }
}
