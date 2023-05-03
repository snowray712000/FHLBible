//
//  IVCAudioBibleEvents.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/17.
//

import Foundation
import AudioToolbox
// VCAudioBible
protocol IVCAudioBibleEvents {
    // viewDidLoad, 切換版本後會用到
    func addCallbackOfCheckingCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny);
    // viewDidLoad, 切換版本後會用到
    func addCallbackOfCheckedCurrentOfAddressOfVersion(_ fn: @escaping FnCallbackAny);
    
    // 自動播放完後(並且loopMode不是chap), 按鈕:下一首後,
    func addCallbackOfSearchingNext(_ fn: @escaping FnCallbackAny);
    func addCallbackOfSearchedNext(_ fn: @escaping FnCallbackAny);
    func addCallbackOfSearchingPrev(_ fn: @escaping FnCallbackAny);
    func addCallbackOfSearchedPrev(_ fn: @escaping FnCallbackAny);
    
    // 要 update slider bar 用
    func addCallbackOfTickOfPlaying(_ fn: @escaping FnCallbackAny);
    // slider 的 max 設定要用, 按下播放, 自動播至下首時
    func addCallbackOfCanSetSliderMax(_ fn: @escaping FnCallbackAny);
    // slider 的 max 設定要用, 按下播放, 自動播至下首時
    // 即將播放下一首，(這與 enInfoGot很像同個，但在 VC 來說是不同的)，目前可能沒用，以後可能要「設立照片」
    func addCallbackOfCanChangeSongInfo(_ fn: @escaping FnCallbackAny);
    
    // 更新 btn 剩餘秒數
    func addCallbackOfTickStopTimer(_ fn: @escaping FnCallbackAny);
    // 更新 btn titme 為 -- : --
    func addCallbackOfCompletedStopTimer(_ fn: @escaping FnCallbackAny);
    
    func releaseEvents();
    // 觀念不正確，這個事件是這個 VC 自己可以加的，不該透過別人
    // var evAppSwitchBackground: IjnEventAny{get}
    // var evAppSwitchForeground: IjnEventAny{get}
    // var evVCdeinit
}
