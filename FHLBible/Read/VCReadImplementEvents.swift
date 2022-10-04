//
//  VCReadImplementEvents.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation
import UIKit

class VCReadImplementEvents : IVCRead {
    var onClickAddr$: IjnEvent<UIView, DText> = IjnEvent()
    
    var onClickVersions$: IjnEvent<UIView, DText> = IjnEvent()
    
    var onClickContentDText$: IjnEvent<UIView, (dtext:DText, ver:String)> = IjnEvent()
    
    init(_ viewTable: ViewDisplayTable2,_ fnGetVersions: @escaping ()->[String]){
        self.v = viewTable
        self.fnGetVersion = fnGetVersions
        
        addVerseClick()
        addVersionsClick()
        addContentsClick()
    }
    
    var v: ViewDisplayTable2
    var fnGetVersion: ()->[String]
    
    private func addVerseClick(){
        v.onClickDatas$.addCallback { sender, pData in
            if pData != nil && pData!.col == -1 {
                self.onClickAddr$.trigger(sender, pData?.dtext)
            }
        }
    }
    private func addVersionsClick(){
        v.onClickHeader$.addCallback { sender, pData in
            self.onClickVersions$.trigger(sender, pData?.dtext)
        }
    }
    private func addContentsClick(){
        v.onClickDatas$.addCallback { sender, pData in
            if pData != nil && pData!.dtext != nil && pData!.col != -1 {
                let vers = self.fnGetVersion()
                if pData!.col < vers.count {
                    self.onClickContentDText$.trigger(sender, (dtext: pData!.dtext!, ver: vers[pData!.col]))
                }
            }
        }
    }
}
