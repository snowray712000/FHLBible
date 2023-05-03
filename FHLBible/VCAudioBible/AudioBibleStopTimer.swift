//
//  AudioBibleStopTimer.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/29.
//

import Foundation
import AVFoundation
class AudioBibleStopTimer {
    static var s = AudioBibleStopTimer()
    private init(){
        self.evCompleted.addCallback({ sender, pData in
            AVPlayer.s?.rate = 0 // 停止
        }, "AudioBibleStopTimer")
    }
    deinit{
        stopAndReleaseTimerAndTriggerCompleted()
        self.evTick.clearCallback()
        self.evCompleted.clearCallback()
    }
    
    // event 用作改變 ui，至於 自動關閉沒界面的事，這個 class 負責
    var evTick = IjnEventAdvancedAny()
    // event 用作改變 ui，至於 自動關閉沒界面的事，這個 class 負責
    var evCompleted = IjnEventAdvancedAny()
    
    private var timer: Timer?
    func stopPrevTimerAndStartNewTimer(_ secondRemain:Double){
        timer?.invalidate() // Stop any existing timer
        
        DAudioBible.s.secondRemainForStopTimer = secondRemain
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            DAudioBible.s.secondRemainForStopTimer -= 1
            self?.evTick.trigger(self, nil)
            
            if DAudioBible.s.secondRemainForStopTimer <= 0 {
                self?.stopAndReleaseTimerAndTriggerCompleted()
            }
        })
    }
    // 供使用者選擇，取消，用。
    func cancelTimer(){
        stopAndReleaseTimerAndTriggerCompleted()
    }
    private func stopAndReleaseTimerAndTriggerCompleted(){
        guard timer != nil else {
            return
        }
        
        timer?.invalidate()
        timer = nil
        evCompleted.trigger(self, nil)
    }
    
}
