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
        AudioBibleStopTimer.s.evTick.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfCompletedStopTimer(_ fn: @escaping FnCallbackAny) {
        AudioBibleStopTimer.s.evCompleted.addCallback(fn, self.eventKey)
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
        EasyAVPlayer.s.evBeenReadyStatus.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfCheckingCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddr.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfCheckedCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddr.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfSearchingNext(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddrNext.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfSearchedNext(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddrNext.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfSearchingPrev(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckingAddrPrev.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfSearchedPrev(_ fn: @escaping FnCallbackAny) {
        AudioBibleSetter.s.evCheckedAddrPrev.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfTickOfPlaying(_ fn: @escaping FnCallbackAny) {
        EasyAVPlayer.s.evForUpdateSliderValueAtMainQueue.addCallback(fn, self.eventKey)
    }
    
    func addCallbackOfCanSetSliderMax(_ fn: @escaping FnCallbackAny) {
        EasyAVPlayer.s.evBeenReadyStatus.addCallback(fn, self.eventKey)
    }
    
    var eventKey: String!
    
    init(){
        self.eventKey = "VCAudioBibleEvents\(ObjectIdentifier(self).hashValue)"
    }
    deinit{ self.releaseEvents() }
}
