
import Foundation
import CoreMedia
import AVFoundation
class EasyCheckAudioUrl {
    var evChecked:IjnEventOnce<Bool,String> = IjnEventOnce()
    func mainAsync(_ versionIdx:Int,_ book:Int,_ chap:Int){
        fhlAu("version=\(versionIdx)&bid=\(book)&chap=\(chap)") {data in
            if let mp3uri = data.mp3 {
                checkIfUrlExists(at: URL(string: mp3uri)!) { isExist in
                    if isExist {
                        self.evChecked.triggerAndCleanCallback(true, mp3uri)
                    } else {
                        self.evChecked.triggerAndCleanCallback(false, nil)
                    }
                }
            } else {
                self.evChecked.triggerAndCleanCallback(false, nil)
            }
        }
    }
}
