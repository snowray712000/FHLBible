
import Foundation
import UIKit
import ZIPFoundation
import zlib
import FHLCommon

// 繼承 PageViewController 並提供自己的圖片名稱, 01read
class ImagePageViewController_01Read: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_01read_01a",
            "helps_01read_02a",
            "helps_01read_02b",
            "helps_01read_03a",
            "helps_01read_03b",
            "helps_01read_04a",
            "helps_01read_05a",
            "helps_01read_06a",
            "helps_01read_07a"
        ]
    }
}
// 02translation
class ImagePageViewController_02translation: ImagePageViewController{
    override var imageNames: [String] {
        return [
            "helps_02translation_01a",
            "helps_02translation_01b",
            "helps_02translation_01c",
            "helps_02translation_02a",
            "helps_02translation_02b",
            "helps_02translation_02c",
            "helps_02translation_03a",
            "helps_02translation_04a"            
        ]
    }    
}
// 03comment
class ImagePageViewController_03comment: ImagePageViewController {
    override var imageNames: [String] {
        return [            
            "helps_03comment_01a",
            "helps_03comment_01b",
            "helps_03comment_02a",            
            "helps_03comment_03a",
            "helps_03comment_03b",
            "helps_03comment_04a",
            "helps_03comment_04b",
            "helps_03comment_05a"
        ]
    }
}

// 04comparetranslations
class ImagePageViewController_04comparetranslations: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_04comparetranslations_01a",
            "helps_04comparetranslations_01b",            
            "helps_04comparetranslations_02a",
            "helps_04comparetranslations_02b",
            "helps_04comparetranslations_02c",
            "helps_04comparetranslations_03a",
            "helps_04comparetranslations_03b",            
        ]
    }
}
// 05textsearchkey
class ImagePageViewController_05textsearchkey: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_05textsearchkey_01a",
            "helps_05textsearchkey_01b",
            "helps_05textsearchkey_02a",            
            "helps_05textsearchkey_03a",
            "helps_05textsearchkey_03b",
            "helps_05textsearchkey_04a"            
        ]
    }
}

// 06search
class ImagePageViewController_06search: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_06search_01a",
            "helps_06search_01b",
            "helps_06search_01c",
            "helps_06search_02a",
            "helps_06search_02b",
            "helps_06search_03a",
            "helps_06search_03b",
            "helps_06search_04a",
            "helps_06search_04b",
            "helps_06search_04c",
            "helps_06search_05a"
        ]
    }
}

// 07sn
class ImagePageViewController_07sn: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_07sn_01a",
            "helps_07sn_01b",
            "helps_07sn_01c",
            "helps_07sn_02a",
            "helps_07sn_02b",
            "helps_07sn_03a",
            "helps_07sn_03b",
            "helps_07sn_04a",
            "helps_07sn_04b",
            "helps_07sn_05a",
            "helps_07sn_05b",
            "helps_07sn_06a",
            "helps_07sn_06b",
            "helps_07sn_07a",
            "helps_07sn_07b",
            "helps_07sn_07c",
            "helps_07sn_07d",
            "helps_07sn_08a",
            "helps_07sn_09a",
            "helps_07sn_09b",
            "helps_07sn_10a",
            "helps_07sn_10b",
            "helps_07sn_10c"
        ]
    }
}
// 08audio
class ImagePageViewController_08audio: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_08audio_01a",
            "helps_08audio_01b",
            // "helps_08audio_01c",
            "helps_08audio_02a",
            "helps_08audio_03a",
            "helps_08audio_04a",
            "helps_08audio_05a",
            "helps_08audio_05b",
            "helps_08audio_05c",
            "helps_08audio_06a",
            "helps_08audio_06b",
            "helps_08audio_06c",
            "helps_08audio_07a",
            "helps_08audio_07b"            
        ]
    }
}

// 09textspeech
class ImagePageViewController_09textspeech: ImagePageViewController {
    override var imageNames: [String] {
        return [
            "helps_09textspeech_01a",
            "helps_09textspeech_01b",
            "helps_09textspeech_02a",
            "helps_09textspeech_02b",
            "helps_09textspeech_03a",
            "helps_09textspeech_03b",
            "helps_09textspeech_04a",
            "helps_09textspeech_04b",            
            "helps_09textspeech_05a",
            "helps_09textspeech_05b",
        ]
    }
}
class VCHelps : VCOptionListViaTableViewControllerBase{
    override func viewDidLoad() {
        super.viewDidLoad()
       _onClickRow$.addCallback { sender, pData in
           self._doClickRow(pData!)
       }
        initial_titles()
    }
    func _doClickRow(_ row: Int) {
        
        if row == 0 {
            let pageVC = ImagePageViewController_01Read(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 1 {
            let pageVC = ImagePageViewController_02translation(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 2 {
            let pageVC = ImagePageViewController_03comment(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 3 {
            let pageVC = ImagePageViewController_04comparetranslations(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 4 {
            let pageVC = ImagePageViewController_05textsearchkey(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 5 {
            let pageVC = ImagePageViewController_06search(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 6 {
            let pageVC = ImagePageViewController_07sn(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 7 {
            let pageVC = ImagePageViewController_08audio(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        } else if row == 8 {
            let pageVC = ImagePageViewController_09textspeech(transitionStyle: .scroll, navigationOrientation: .horizontal)
            navigationController?.pushViewController(pageVC, animated: true)
        }

        
    }
    
    /// `顯示於 tableview 的資料 _ title`
    override var _ovTitle1: [String] { get {return _ovTitle1Data} }
    /// `顯示於 tableview 的資料 _ 小字 sub title`
    override var _ovTitle2: [String]? { get{ return _ovTitle2Data.count != 0 ? _ovTitle2Data : []}}
    /// `顯示於 tableview 的資料 _ 顏色`
    override var _ovColors: [UIColor]? { get{return self._ovColorsData }}
    var _ovTitle1Data: [String] = ["和合本","和合本(簡體)","KJV"]

    /// 下面4個，主要由 `每個譯本的state決定`
    /// reloadStatesUsingCheckingFile updateTitle2DataAndColorFromStates 是更新的關鍵流程
    var _ovTitle2Data: [String] = []
    var _ovColorsData: [UIColor] = []
    var ver2date: [String:Date?] = [:]
    
    private func initial_titles(){
        // reset
        _ovTitle1Data = [] // 和合本 ...
        
        // TODO: manual
        if ManagerLangSet.s.curIsGb {
            _ovTitle1Data.append("阅读")
            _ovTitle1Data.append("译本切换")
            _ovTitle1Data.append("注释")
            _ovTitle1Data.append("译本比较")
            _ovTitle1Data.append("串珠")
            _ovTitle1Data.append("搜寻")
            _ovTitle1Data.append("SN")
            _ovTitle1Data.append("有声圣经")
            _ovTitle1Data.append("有声文字")
        } else {
            _ovTitle1Data.append("閱讀")
            _ovTitle1Data.append("譯本切換")
            _ovTitle1Data.append("注釋")
            _ovTitle1Data.append("譯本比較")
            _ovTitle1Data.append("串珠")
            _ovTitle1Data.append("搜尋")
            _ovTitle1Data.append("SN")
            _ovTitle1Data.append("有聲聖經")
            _ovTitle1Data.append("有聲文字")
        }
    }
}
