//
//  IVCAudioBibleEvents.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/17.
//

import Foundation
import AudioToolbox
// 沒呼叫 release, 在 deinit 會自動呼叫
class VCAudioBibleEvents : IVCAudioBibleEvents {
    func addCallbackOfTickStopTimer(_ fn: @escaping FnCallbackAny) {
        AudioBibleStopTimer.s.evTick.addCallback(self.eventKey, fn)
    }
    
    func addCallbackOfCompletedStopTimer(_ fn: @escaping FnCallbackAny) {
        AudioBibleStopTimer.s.evCompleted.addCallback(self.eventKey, fn)
    }
    
    
    func releaseEvents() {
        AudioBibleSetter.s.evCheckedAddr.clearCallback(self.eventKey)
        AudioBibleSetter.s.evCheckingAddr.clearCallback(self.eventKey)
        AudioBibleSetter.s.evCheckedAddrNext.clearCallback(self.eventKey)
        AudioBibleSetter.s.evCheckingAddrNext.clearCallback(self.eventKey)
        AudioBibleSetter.s.evCheckedAddrPrev.clearCallback(self.eventKey)
        AudioBibleSetter.s.evCheckingAddrPrev.clearCallback(self.eventKey)
        
        EasyAVPlayer.s.evOneFileCompleted.clearCallback(self.eventKey)
        EasyAVPlayer.s.evBeenReadyStatus.clearCallback(self.eventKey)
        EasyAVPlayer.s.evForUpdateSliderValueAtMainQueue.clearCallback(self.eventKey)
        
        AudioBibleStopTimer.s.evTick.clearCallback(self.eventKey)
        AudioBibleStopTimer.s.evCompleted.clearCallback(self.eventKey)
    }
    func addCallbackOfCanChangeSongInfo(_ fn: @escaping FnCallbackAny) {
        EasyAVPlayer.s.evBeenReadyStatus.addCallback(self.eventKey,fn)
    }
    
    func addCallbackOfCheckingCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddr.addCallback(self.eventKey,fn)
    }
    
    func addCallbackOfCheckedCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddr.addCallback(self.eventKey,fn)
    }
    
    func addCallbackOfSearchingNext(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddrNext.addCallback(self.eventKey,fn)
    }
    
    func addCallbackOfSearchedNext(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddrNext.addCallback(self.eventKey,fn)
    }
    
    func addCallbackOfSearchingPrev(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddrPrev.addCallback(self.eventKey, fn)
    }
    
    func addCallbackOfSearchedPrev(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddrPrev.addCallback(self.eventKey, fn)
    }
    
    func addCallbackOfTickOfPlaying(_ fn: @escaping FnCallbackAny) {
        EasyAVPlayer.s.evForUpdateSliderValueAtMainQueue.addCallback(self.eventKey, fn)
    }
    
    func addCallbackOfCanSetSliderMax(_ fn: @escaping FnCallbackAny) {
        EasyAVPlayer.s.evBeenReadyStatus.addCallback(self.eventKey,fn)
    }
    
    lazy var eventKey: String = {
        return "VCAudioBibleEvents\(ObjectIdentifier(self).hashValue)"
    }()
    init(){
    }
    deinit{ self.releaseEvents() }
}
