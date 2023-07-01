//
//  AudioBibleStopTimer.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/29.
//

import Foundation
import AVFoundation
class AudioBibleStopTimer : AudioStopTimer {
    static var s = AudioBibleStopTimer()
    private override init(){
        super.init()
        self.evCompleted.addCallback({ sender, pData in
            AVPlayer.s?.rate = 0 // 停止
        }, "AudioBibleStopTimer")
    }
    
    override func stopPrevTimerAndStartNewTimer(_ secondRemain:Double){
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
}
