//
//  ReadPageController.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/22.
//

import Foundation
import UIKit
/// 必須實作: IAddressManager IDataGetter
//class UIReadPageController : UIPageViewController, UIPageViewControllerDataSource {
//    var uiM = ReUseAtPageController()
//    var addrM: IAddressManager = AddressManagerA() // AddressM()
//    //var dataG: IDataGetter = DataGetter01()
//    var dataG: IDataGetter = DataGetterUsingBibleReader()
//    var addrCur: String?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        dataSource = self
//        
//        uiM.doWhenViewDidLoad()
//        let addr = addrM.getCurrentAddress()
//        let ui = uiM.getUICurrent()
//        ui.addr = addr
//        
//        getDataAndSetUiAsync(addr, ui)
//        
//        if viewControllers?.count == 0 {
//            setViewControllers( [ ui ], direction: .forward, animated: false, completion: nil)
//        }
//    }
//    /// 用於 pageViewController Before After 事件中
//    /// 若 某 ui 的 addr 變了, 則會呼叫此, 在(取完資料)後, 設定 ui 資料
//    func getDataAndSetUiAsync(_ addr: String,_ ui: UIReadBibleController){
//        // step1
//        dataG.addEventCallbackWhenCompleted({ a1 in
//            guard let a1 = a1 else { return }
//            
//            DispatchQueue.main.async {
//                ui.set(a1.vers, a1.datas)
//            }
//        })
//        // step2
//        dataG.getDataAndTriggerCompletedEvent(addr, ["和合本","新譯本"])
//    }
//    /// 用於 pageViewController Before After
//    func getAddrFromViewController(_ v: UIViewController) -> String {
//        let v2 = v as! UIReadBibleController
//        return v2.addr
//    }
//    /// 從 scroll after before 事件抽出一樣的
//    func pageScrollBeforeOrAfter(_ isBefore: Bool,_ viewController: UIViewController) -> UIViewController? {
//        // 不論最後是不是回傳 nil, 仍然要呼叫此,
//        let ui = isBefore ? uiM.doWhenBefore() : uiM.doWhenAfter()
//        
//        // 此值，也是「目前中間的 address」
//        // (將來會用到 - 更新到全域變數上時)
//        let addrOfRefView = getAddrFromViewController(viewController)
//        
//        let fn = isBefore ? addrM.getAddressBefore : addrM.getAddressAfter
//        guard let addr = fn(addrOfRefView) else { return nil }
//        ui.addr = addr
//        
//        getDataAndSetUiAsync(addr, ui)
//        
//        return ui // 先 return 還沒 set 的 ui, 然後 async 完成後, 會更新 ui
//    }
//
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        return pageScrollBeforeOrAfter(true, viewController)
//    }
//
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        return pageScrollBeforeOrAfter(false, viewController)
//    }
//}
