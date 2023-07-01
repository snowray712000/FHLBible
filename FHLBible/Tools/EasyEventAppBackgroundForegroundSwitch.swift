import UIKit
class EasyEventAppBackgroundForegroundSwitch {
    var evBecomeActive = IjnEventAny()
    var evResignActive = IjnEventAny()
    init(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func handleResignActiveNotification() {
        self.evResignActive.trigger(self, nil)
    }
    @objc func handleBecomeActiveNotification() {
        self.evBecomeActive.trigger(self, nil)
    }
    deinit{
        evResignActive.clearCallback()
        evBecomeActive.clearCallback()
    }
}

