//
//  VCAudioTextBible.swift
//  FHLBible
//
//  Created by littlesnow on 2023/5/27.
//

import Foundation
import UIKit

class VCAudioTextBible : UIViewController {
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnPrev: UIButton!
    @IBOutlet weak var btnPlayrate: UIButton!
    @IBOutlet weak var btnLoopMode: UIButton!
    @IBOutlet weak var labelTimeRemain: UILabel!
    @IBOutlet weak var labelTime1: UILabel!
    @IBOutlet weak var sliderProcess: UISlider!
    @IBOutlet weak var addrBarItem: UIBarItem!
    @IBOutlet weak var btnTimerStop: UIButton!
    
    var addr: VerseRange!
    var vers: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addrBarItem.title = VerseRangeToString().main(addr.verses)
    }
}
