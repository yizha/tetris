//
//  GameScene.swift
//  Tetris
//
//  Created by Yicha Ding on 9/23/17.
//  Copyright © 2017 Yicha Ding. All rights reserved.
//

import SpriteKit
import GameplayKit
import os.log

enum GameState {
    case idle
    case running
    case paused
}

class GameScene: SKScene {

    let loadSndEffects = true
    var soundEffectActions: [String: SKAction]!

    var state: GameState = .idle
    var mute = false

    var playArea: PlayArea!
    var ctrlArea: ControlArea!
    var infoArea: InfoArea!

    override func didMove(to view: SKView) {

        if loadSndEffects && soundEffectActions == nil {
            soundEffectActions = [
                "move":   SKAction.playSoundFileNamed("move.wav",   waitForCompletion: false),
                "land":   SKAction.playSoundFileNamed("land.wav",   waitForCompletion: true),
                "rotate": SKAction.playSoundFileNamed("rotate.wav", waitForCompletion: false),
                "clear":  SKAction.playSoundFileNamed("clear.wav",  waitForCompletion: false),
                "over":   SKAction.playSoundFileNamed("over.wav",   waitForCompletion: false)
            ]
        } else {
            soundEffectActions = [String: SKAction]()
        }

        // customization
        self.backgroundColor = Conf.backgroundColor
        self.isUserInteractionEnabled = false

        let widthUnit = (self.size.width - 3 * Conf.margin) / Conf.getWidthM()
        //os_log("scene size width=%f, width unit=%f", type: .debug, self.size.width, widthUnit)
        //os_log("play area width-m=%f", type: .debug, Conf.getPlayAreaWidthM(cols: 10))
        //os_log("full area widht-m=%f", type: .debug, Conf.getWidthM())
        //os_log("scene frame width=%f", type: .debug, self.frame.width)
        let blockBorder = widthUnit * Conf.blockBorderM
        let blockInnerGap = widthUnit * Conf.blockInnerGapM
        let blockInnerBlock = widthUnit * Conf.blockInnerBlockM
        let block = Block(border: blockBorder, gap: blockInnerGap, size: blockInnerBlock)

        // play area
        let playArea = PlayArea()
        playArea.setup(scene: self, block: block, unit: widthUnit)

        let ctrlAreaRect = CGRect(
            x: Conf.margin,
            y: Conf.margin,
            width: self.size.width - 2 * Conf.margin,
            height: self.size.height - playArea.size.height - 2 * Conf.margin)

        // control area
        let ctrlArea = ControlArea()
        ctrlArea.setup(scene: self,
                       playAreaWidth: playArea.size.width,
                       rect: ctrlAreaRect)

        // info area
        let infoAreaRect = CGRect(
            x: playArea.size.width + 2 * Conf.margin,
            y: playArea.position.y + widthUnit * Conf.playAreaBorderM + widthUnit * Conf.blockGapM,
            width: ctrlAreaRect.width - playArea.size.width - Conf.margin,
            height: playArea.size.height - 2 * widthUnit * (Conf.playAreaBorderM + Conf.blockGapM)
        )
        //os_log("info area x=%f, y=%f, width=%f, height=%f", type: .debug, infoAreaRect.origin.x, infoAreaRect.origin.y, infoAreaRect.size.width, infoAreaRect.size.height)
        let infoArea = InfoArea(block: block, unit: widthUnit)
        infoArea.setup(scene: self, rect: infoAreaRect, data: playArea.field.gameData)

        self.playArea = playArea
        self.ctrlArea = ctrlArea
        self.infoArea = infoArea

    }

    func playSoundEffect(_ name: String) {
        if loadSndEffects && !self.mute {
            if let sndEffectAction = self.soundEffectActions[name] {
                self.run(sndEffectAction)
            }
        }
    }

    func playAreaTouched() {
        switch self.state {
        case .idle:
            self.state = .running
            self.newGame()
        case .running:
            self.state = .paused
            self.pauseGame()
        case .paused:
            self.state = .running
            self.unpauseGame()
        }
    }

    func unpauseGame() {
        self.ctrlArea.enable()
        self.playArea.unpause()
        self.infoArea.unpause()
    }

    func pauseGame() {
        self.ctrlArea.disable()
        self.playArea.pause()
        self.infoArea.pause()
    }

    func newGame() {
        self.ctrlArea.enable()
        self.playArea.newGame()
        self.infoArea.newGame()
    }

    func reset() {
        self.state = .idle
        self.ctrlArea.disable()
        self.playArea.reset()
        self.infoArea.reset()
    }

    func toggleSpeaker() {
        self.mute = !self.mute
        self.infoArea.updateSpeaker(mute: self.mute)
    }

    func changeGameSpeed() {
        self.playArea.field.changeGameSpeed()
    }

    func movePieceLeft(_ start: Bool) { self.playArea.field.moveLeft(start) }
    func movePieceRight(_ start: Bool) { self.playArea.field.moveRight(start) }
    func movePieceDown(_ start: Bool) { self.playArea.field.moveDown(start) }
    func rotatePiece() { self.playArea.field.rotate() }
    func dropPiece() { self.playArea.drop() }

    func updateNextPiece(_ piece: Piece?) { self.infoArea.updateNextPiece(piece) }
    func updateInfoArea(_ data: GameData) { self.infoArea.updateGameData(data) }
}

