import UIKit
class EasyEventAppBackgroundForegroundSwitch {
    var evEnteredForeground = IjnEventAny()
    var evEnteredBackground = IjnEventAny()
    init(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    @objc func handleWillEnterForegroundNotification() {
        self.evEnteredForeground.trigger(self, nil)
    }
    @objc func handleDidEnterBackgroundNotification() {
        self.evEnteredBackground.trigger(self, nil)
    }
    deinit{
        evEnteredBackground.clearCallback()
        evEnteredForeground.clearCallback()
    }
}
