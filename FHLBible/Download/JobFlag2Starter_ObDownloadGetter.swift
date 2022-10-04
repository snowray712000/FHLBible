//
//  JobFlag2Starter.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation

public protocol ObDownloadGetter {
    func getObProgress() -> IjnObservableObject<(Int64,Int64)>
    func getObIsComplete() -> IjnObservableObject<Bool>
}

class ObDownloadGetterTest : ObDownloadGetter{
    func getObIsComplete() -> IjnObservableObject<Bool> {
        return self.obIsComplete
    }
    
    init(){
        DispatchQueue.global().async { [self] in
            let r1: Int64 = 2330
            var r2: Int64 = 0
            while r2 < r1 {
                sleep(1)
                r2 += 212
                if r2 > r1 {
                    r2 = r1
                }
                
                obProgress.value = (r2,r1)
            }
            obIsComplete.value = true
        }
    }
    func getObProgress() -> IjnObservableObject<(Int64, Int64)> {
        return obProgress
    }
    
    var obProgress: IjnObservableObject< (Int64,Int64) > = IjnObservableObject((0,2330))
    var obIsComplete = IjnObservableObject(false)
}
