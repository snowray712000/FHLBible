//
//  EasySQLiteBase.swift
//  Sqlite1FMDB
//
//  Created by littlesnow on 2022/10/2.
//

import Foundation
import FMDB

// sample
public class TestDb : EasySQLiteBase {
    public override var pathToDatabase: URL! {
        get {
            let r1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return r1.appendingPathComponent("test/bible_little.db")
        }
    }
    public static let shared = TestDb()
}

// 建立自己的 singleton 變數 static var shared: XXXXX = XXXXXX ()
// override pathToDatabase getter
open class EasySQLiteBase: NSObject {
    
    // 因為 static 初始值要給，就沒辦法用了，所以將其變為 override getter
    open var pathToDatabase: URL! {
        get {
            let r1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let r2 = r1[0].appendingPathComponent("test", isDirectory: true)
            let r3 = r2.appendingPathComponent("/bible_little.db")
            return r3
        }
    }
    var database: FMDatabase!
    public var lastError: Error!
    public var lastErrorMessage:String!
    
    // static let shared :EasySQLite = EasySQLite()
    public override init(){
        super.init()
        
        if isPathExist(){
            database = FMDatabase(path: pathToDatabase.path)
        }
    }
    
    
    private func isPathExist()->Bool { return FileManager.default.fileExists(atPath: pathToDatabase.path)}
    
    private func openDatabase() -> Bool {
        if database == nil {
            // assert ( isPathExist() )
            database = FMDatabase(path: pathToDatabase.path)
        }
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
    }
    private func closeDatabase() {
        database.close()
    }

    // 雖然完整是 update version set 'dt'='2019-07-16 23:12:24'
    // 但若用?時，不要寫成 ='?' 只要寫 =? 即可
    public func doSelect(stringOfSQLite cmd:String,
                args values:[Any]?,
                CallbackWhenQueryed fnDo: (FMResultSet)->Void)->Bool{
        if openDatabase(){
            let r1 = gAutoClose()
            r1.ignoreWarning()
            
            do {
                fnDo(try database.executeQuery(cmd, values: values))
                return true
            } catch {
                lastError = error
                lastErrorMessage = error.localizedDescription
            }
        }
        return false
    }
    // 雖然完整是 update version set 'dt'='2019-07-16 23:12:24'
    // 但若用?時，不要寫成 ='?' 只要寫 =? 即可
    public func doUpdate(stringOfSQLite cmd:String,
                  args values:[Any]?) -> Bool{
        if openDatabase() {
            let r1 = gAutoClose()
            r1.ignoreWarning()
            
            do {
                try database.executeUpdate(cmd, values: values)
                return true
            } catch {
                lastError = error
                lastErrorMessage = error.localizedDescription
            }
        }
        return false
    }
    public func doUpdateMore(stringOfSQLite cmds:String)->Bool{
        if openDatabase() {
            let r1 = gAutoClose()
            r1.ignoreWarning()
            
            if database.executeStatements(cmds){
                return true
            }
            
            self.lastError = database.lastError()
            self.lastErrorMessage = database.lastErrorMessage()
        }
        return false
    }
    private func gAutoClose()->AutoDisposedUsingDeconstructor {return AutoDisposedUsingDeconstructor({self.closeDatabase()})}
    // 不可以使用 _ ，這樣會馬上呼叫解構子
    // 但只宣告不作什麼，又會有 warning，所以加一個函式
    class AutoDisposedUsingDeconstructor : NSObject {
        var fn: ()->Void
        init(_ fn: @escaping ()->Void){
            self.fn = fn
        }
        deinit{
            fn()
        }
        func ignoreWarning(){}
    }
}


