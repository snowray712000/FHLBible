//
//  AudioStopTimer.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/22.
//

import Foundation
import AVFoundation
// 先開發 AudioBibleStopTimer 後來出現 AudioBibleTextStopTimer
// 太像了，所以重構 AudioStopTimer
class AudioStopTimer {
    // event 用作改變 ui，至於 自動關閉沒界面的事，這個 class 負責
    var evTick = IjnEventAdvancedAny()
    // event 用作改變 ui，至於 自動關閉沒界面的事，這個 class 負責
    var evCompleted = IjnEventAdvancedAny()
    var timer: Timer?
    init(){}
    deinit{
        stopAndReleaseTimerAndTriggerCompleted()
        self.evTick.clearCallback()
        self.evCompleted.clearCallback()
    }
    // 供使用者選擇，取消，用。
    func cancelTimer(){
        stopAndReleaseTimerAndTriggerCompleted()
    }
    // protected
    func stopAndReleaseTimerAndTriggerCompleted(){
        guard timer != nil else {
            return
        }
        
        timer?.invalidate()
        timer = nil
        evCompleted.trigger(self, nil)
    }
    // can override
    func stopPrevTimerAndStartNewTimer(_ secondRemain:Double){
        timer?.invalidate() // Stop any existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            self?.evTick.trigger(self, nil)
        })
    }
}
