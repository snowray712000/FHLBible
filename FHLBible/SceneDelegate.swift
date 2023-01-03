//
//  SceneDelegate.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    // bible.zip 變 bible.zip.tmp
    func gCachePathAndMakeSureExist(filename na:String)->URL{
        let r1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let r2 = r1.appendingPathComponent("/cache", isDirectory: true)
        if FileManager.default.fileExists(atPath: r2.path) == false {
            do{
                try FileManager.default.createDirectory(
                    at: r2, withIntermediateDirectories: true,
                    attributes: nil)
            }catch{
                print(error.localizedDescription)
            }
        }
        
        let r3 = r2.appendingPathComponent("/\(na).tmp", isDirectory: false)
        return r3
    }
    
    // 練習2: 續傳1
    func sample02DownloadWithDelegate(){
        let r1 = gCachePathAndMakeSureExist(filename: "bible.zip")
        if FileManager.default.fileExists(atPath: r1.path) == false {
            if taskDownload == nil {
                let conf = URLSessionConfiguration.default
                let session = URLSession(configuration: conf,
                                         delegate: self.mydelegate,
                                         delegateQueue: nil)
                let url = "https://ftp.fhl.net/FHL/COBS/data/bible.zip"
                let task = session.downloadTask(with: URL(string: url)!)
                task.resume()
                
                taskDownload = task
                

            }
        } else {
            if taskDownload == nil {
                let session = URLSession(
                    configuration: URLSessionConfiguration.default,
                    delegate: self.mydelegate,
                    delegateQueue: nil)
                do {
                    let task = session.downloadTask(withResumeData: try Data(contentsOf: r1))
                    task.resume()
                    taskDownload = task
                }catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    var taskDownload: URLSessionDownloadTask?
    var mydelegate = MyDelegate()
    class MyDelegate : NSObject, URLSessionDownloadDelegate {
        // 必要, 當完成時呼叫, 這裡通常處理: 存檔
        func urlSession(_ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didFinishDownloadingTo location: URL) {
            // 若 url 為 ... ，建議名稱會是 bible.zip
            // let url = "https://ftp.fhl.net/FHL/COBS/data/bible.zip"
            let r1 = downloadTask.response?.suggestedFilename ?? "aaaa.zip"
            // Users/littlesnow/Library/Developer/CoreSimulator/Devices/
            // 6B47374C-BE89-4DA5-91D7-F00165BBD869/data/Containers/Data/Application/
            // C358DC8B-CE37-4873-88AB-3CF53FE3395C/tmp/CFNetworkDownload_UFQoJW.tmp
            print ( location.path )
            
            // Users/littlesnow/Library/Developer/CoreSimulator/Devices/
            // 6B47374C-BE89-4DA5-91D7-F00165BBD869/data/Containers/Data/Application/
            // 4141026F-0D00-4A9D-89E1-114363739F10/Documents
            let r2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            print( r2.path)
            
            do {
                try FileManager.default.moveItem(
                    at: location,
                    to: r2.appendingPathComponent("/\(r1)"))
            } catch {
                // 無法將「CFNetworkDownload_etYhFY.tmp」搬移至「Documents」，因為已存在相同名稱的項目。
                print(error.localizedDescription)
            }
        }
        // 非必要.
        // 用在百分比
        func urlSession(_ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) {
            let r1 = Float( totalBytesWritten )  / Float( totalBytesExpectedToWrite )
            print("download percent \(r1) %, bys\(totalBytesWritten)")
        }
        // 非必要
        // 用在 "恢復下載" ， 但此例還不知道怎麼恢復
        func urlSession(_ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didResumeAtOffset fileOffset: Int64,
                        expectedTotalBytes: Int64) {
            print("恢復下載 offset:\(fileOffset) total:\(expectedTotalBytes)")
        }
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        // sample02DownloadWithDelegate()
    }
    func sample01_downloadAfile(){
        let url = "https://ftp.fhl.net/FHL/COBS/data/bible_little.zip"
        let task = URLSession.shared.dataTask(
            with: URL(string: url)!) { (a1:Data?, a2:URLResponse?, a3:Error?) in
            // saving file
            let r1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let r2 = r1.appendingPathComponent("bible_little.zip")
            do {
                try a1!.write(to: r2)
                print("finished")
            }catch{
                print(error.localizedDescription)
            }
        }
        task.resume()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}


