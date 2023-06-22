//
//  AudioBibleTextStopTimer.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/22.
//

import Foundation
class AudioBibleTextStopTimer : AudioStopTimer {
    static var s = AudioBibleTextStopTimer()
    override init(){}
    var secondRemain = 0.0
    override func stopPrevTimerAndStartNewTimer(_ secondRemain:Double){
        timer?.invalidate() // Stop any existing timer
        
        self.secondRemain = secondRemain
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            self?.secondRemain -= 1
            self?.evTick.trigger(self, nil)
            
            if let sself = self {
                if sself.secondRemain <= 0 {
                    sself.stopAndReleaseTimerAndTriggerCompleted()
                }
            }
        })
    }

}
