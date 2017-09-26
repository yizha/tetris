//
//  AppDelegate.swift
//  Tetris
//
//  Created by Yicha Ding on 9/23/17.
//  Copyright © 2017 Yicha Ding. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //os_log("application")
        //AVAudioSession.sharedInstance().setCategory(
        //AVAudioSession.sharedInstance().setActive(true, error: nil)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, with: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            os_log("failed to initialize audio session, error: %s", type: .debug, (error as NSError).code)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        //os_log("applicationWillResignActive")
        let view = application.keyWindow!.rootViewController!.view as! SKView
        let scene = view.scene! as! GameScene
        if scene.state == .running {
            scene.pauseGame()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //os_log("applicationDidEnterBackground")
        saveTopScore(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //os_log("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //os_log("applicationDidBecomeActive")
        loadTopScore(application)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        //os_log("applicationWillTerminate")
        saveTopScore(application)
    }

    let topScoreKey = "TopScore"
    func saveTopScore(_ app: UIApplication) {
        let view = app.keyWindow!.rootViewController!.view as! SKView
        let scene = view.scene! as! GameScene
        let topScore = scene.playArea.field.gameData.topScore
        let defaults = UserDefaults.standard
        defaults.set(topScore, forKey: topScoreKey)
    }

    func loadTopScore(_ app: UIApplication) {
        let view = app.keyWindow!.rootViewController!.view as! SKView
        let scene = view.scene! as! GameScene
        let gameData = scene.playArea.field.gameData
        if gameData.loaded { return }
        let defaults = UserDefaults.standard
        gameData.topScore = defaults.integer(forKey: topScoreKey)
        gameData.loaded = true
        scene.infoArea.updateGameData(gameData)
    }
}
