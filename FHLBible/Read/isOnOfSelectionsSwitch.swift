//
//  isOnOfSelectionsSwitch.swift
//  FHLBible
//
//  Created by littlesnow on 2023/11/15.
//

import Foundation


class IsOnOfSelectionsOfSwitch {
    /// 對應 tableview,  [row][col]
    var isOns: [[Bool]] = []
    
    func resize(row:Int,col:Int,val:Bool=false){
        isOns = ijnRange(0, row).map({ _ in
            return ijnRange(0, col).map( { _ in return val })
        })
    }
    func set_all(v: Bool){
        for (r,a1) in isOns.enumerated(){
            for (c,_) in a1.enumerated(){
                isOns[r][c] = v
            }
        }
    }
    func set_all_of_row(v: Bool, row: Int){
        for (c,_) in isOns[row].enumerated(){
            isOns[row][c] = v
        }
    }
    func set_all_of_col(v:Bool, col:Int){
        for (r,a1) in isOns.enumerated(){
            isOns[r][col] = v            
        }
    }

    private func _inverse_all(){
        let row = isOns.count
        for r in ijnRange(0, row){
            var r1 = isOns[r];
            let col = r1.count
            for c in ijnRange(0, col){
                r1[c] = !r1[c]
            }
        }
    }
    private func _inverse_col(c:Int){
        let row = isOns.count
        for r in 0..<row{
            isOns[r][c] = !isOns[r][c]
        }
    }
    private func _inverse_row(r:Int){
        for (i,a1) in isOns[r].enumerated(){
            isOns[r][i] = !a1
        }
    }
    
    /**
     ON 變 OFF，OFF 變 ON。
     - 若 r == 0, c ==0 全部反過來。(預計按了左上角)
     - 若 r == 0，某 col 全部反過來。(預計按了最上面的版次)
     - 若 c == 0，某 row 反過來。
     */
    func inverse(r:Int,c:Int){
        if r <= -1 { return }
        if c <= -1 { return }
        
        if r == 0 && c == 0 {
            // 全部反過來
            _inverse_all()
            return
        }
        
        if r == 0 {
            // 反過來某一 col
            _inverse_col(c: c)
            return
        }
        if c == 0 {
            // 反過來某一 row
            _inverse_row(r: r)
            return
        }
        
        let v = isOns[r][c]
        isOns[r][c] = !v
    }
}
