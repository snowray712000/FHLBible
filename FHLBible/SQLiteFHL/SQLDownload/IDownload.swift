//
//  File.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
protocol IDownload {
    var onProcessing$: IjnEvent_ProcessingBar { get }
    var onFinished$: IjnEvent_Finished { get }
    func mainAsync()
}
