//
//  GameViewController.swift
//  Tetris
//
//  Created by Yicha Ding on 9/23/17.
//  Copyright © 2017 Yicha Ding. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let v = self.view as! SKView
        //v.showsFPS = true
        //v.showsNodeCount = true
        v.ignoresSiblingOrder = true

        let scene = GameScene(size: v.bounds.size)
        scene.scaleMode = .aspectFill

        v.presentScene(scene)
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
