
import Foundation
import CoreMedia
import AVFoundation

extension EasyAVPlayer {
    // 這個給 EasyAvPlayer 用，其他人不要直接用
    class EasyPlayerItem: NSObject {
        private var playerItemDidPlayToEndTimeObserver: Any?
        private var playerItemContext = 0
        private var item: AVPlayerItem!
        var evReadyStatus = IjnEventOnceAny()
        var evPlayCompleted = IjnEventOnceAny()
        
        init(_ item:AVPlayerItem){
            self.item = item
            super.init()
        }
        deinit{
            do_deinit()
        }
        func mainAsyncWhenYouBindEventAlready(){
            // 监听 AVPlayerItem 的状态，并在准备好播放时获取视频的总时长
            item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .old], context: &playerItemContext)
            // 註冊觀察者，接收播放完成通知
            playerItemDidPlayToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.item, queue: .main) { [weak self] notification in
                self?.evPlayCompleted.triggerAndCleanCallback(nil, nil)
                self?.removeCompletedObserve()
            }
        }
        // 更主動，明確的釋放，雖然應該不用，會在 deinit 自動被呼叫
        func do_deinit(){
            self.removeReadyStatusObserve()
            self.removeCompletedObserve()
        }
        // 變成 ready 後，就會馬上處理了
        private func removeReadyStatusObserve(){
            if playerItemContext != 0 {
                self.item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext) // 切換版本時，會當掉，可能是還沒新增吧
                playerItemContext = 0;
            }
        }
        private func removeCompletedObserve(){
            if let observer = playerItemDidPlayToEndTimeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if context == &playerItemContext {
                if  let change = change,
                    let newValue = change[.newKey] as? Int,
                    let oldValue = change[.oldKey] as? Int,
                    newValue != oldValue,
                    let status = AVPlayerItem.Status(rawValue: newValue){
                        switch status {
                        case .readyToPlay:
                            DispatchQueue.main.async {
                                self.removeReadyStatusObserve()
                                self.evReadyStatus.triggerAndCleanCallback(nil, nil)
                            }
                            break
                        case .unknown:
                            break
                        case .failed:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
        }

        
    }

}
