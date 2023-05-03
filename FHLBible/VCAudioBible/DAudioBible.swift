
import Foundation
import CoreMedia
import AVFoundation

// 資料必須足夠判定，下一首，上一首
open class DAudioBible {
    public enum LoopMode {
        case Chap // repeat.1
        case Book // repeat
        case All  // goforward
    }
    static var s = DAudioBible()
    init(){
        versionIndex = ManagerAudioBible.s.curVersionIndex
        loopMode = ManagerAudioBible.s.curLoopMode
        speed = ManagerAudioBible.s.curSpeed
    }
    
    
    var addr: DAddress? // 雖然 book, chap 足夠，verse就都用1
    var addrNext: DAddress?
    var addrPrev: DAddress?
    var versionIndex: Int? = 0 {
        didSet {
            ManagerAudioBible.s.updateVersionIndex(versionIndex!)
        }
    }
    var mp3: String?
    var mp3Next: String?
    var mp3Prev: String?
    var loopMode: LoopMode = .All {
        didSet {
            ManagerAudioBible.s.updateLoopMode(loopMode)
        }
    }
    var speed: Float = 1 {
        didSet {
            ManagerAudioBible.s.updateSpeed(speed)
        }
    }
    // 這不是指，目前真的在播放嗎，而是使用者是設定為 `播放中` 嗎
    // 當音樂播完，切換下一首之間，狀態會變為 false，但這個參數仍然會是 true
    // 只有當使用者按下停止，才會變為 false
    // 按上一首，下一首，切換 loopMode 切換速度，都不會影響
    var isPlaying: Bool = false 
    
    // 倒數計時用
    var secondRemainForStopTimer: Double = 0
    
    func offsetToPrev(){
        addrPrev = addr
        mp3Prev = mp3
        addr = addrNext
        mp3 = mp3Next
    }
    func offsetToNext(){
        addrNext = addr
        mp3Next = mp3
        addr = addrPrev
        mp3 = mp3Prev
    }
}
