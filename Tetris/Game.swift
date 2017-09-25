//
//  Game.swift
//  Tetris
//
//  Created by Yicha Ding on 9/23/17.
//  Copyright © 2017 Yicha Ding. All rights reserved.
//

import SpriteKit
import GameplayKit
import os.log

class BlockNode: SKShapeNode {
    var row = -1
    var col = -1

    func setColor(_ color: UIColor) {
        self.strokeColor = color
        let innerBlock = self.children[0] as! SKSpriteNode
        innerBlock.color = color
    }
}

class BlockNodeStore {

    private var blocks = [BlockNode]()

    init(_ block: Block, _ count: Int) {
        for _ in 0..<count {
            self.blocks.append(block.create(color: .clear))
        }
    }

    func popAll() -> [BlockNode] {
        let all = self.blocks
        self.blocks = [BlockNode]()
        return all
    }

    func pop(_ count: Int) -> [BlockNode] {
        assert(count <= blocks.count,
               "requesting " + String(count) + " while I only have " + String(blocks.count) + "!")
        var r = [BlockNode]()
        for _ in 0..<count {
            r.append(blocks.popLast()!)
        }
        return r
    }

    func push(_ node: BlockNode) {
        node.removeFromParent()
        blocks.append(node)
    }

    func push(_ nodes: [BlockNode]) {
        for one in nodes {
            one.removeFromParent()
            blocks.append(one)
        }
    }
}

class Block {

    let borderSize:     CGFloat
    let innerGap:       CGFloat
    let innerBlockSize: CGFloat
    let blockSize:      CGFloat
    let innerBlockPos:  CGPoint

    init(border borderSize: CGFloat, gap innerGap: CGFloat, size innerBlockSize: CGFloat) {
        self.borderSize = borderSize
        self.innerGap = innerGap
        self.innerBlockSize = innerBlockSize

        let offset = borderSize + innerGap
        self.blockSize = 2 * offset + innerBlockSize
        self.innerBlockPos = CGPoint(x: offset, y: offset)
    }

    func create(color: UIColor) -> BlockNode {
        // inner-block
        var blockSize = self.innerBlockSize
        let innerBlockNode = SKSpriteNode(color: color, size: CGSize(width: blockSize, height: blockSize))
        innerBlockNode.anchorPoint = CGPoint(x: 0, y: 0)
        innerBlockNode.position = self.innerBlockPos
        // block
        blockSize = self.blockSize
        let blockNode = BlockNode(rect: CGRect(x: 0, y: 0, width: blockSize, height: blockSize))
        blockNode.strokeColor = color
        blockNode.fillColor = .clear
        blockNode.lineWidth = CGFloat(self.borderSize)
        // add inner-block to block
        blockNode.addChild(innerBlockNode)

        return blockNode
    }
}

class BlockPatch {

    let block: Block
    let gap: CGFloat
    let rows: Int
    let cols: Int
    let positions: [[CGPoint]]
    let size: CGSize

    init(block: Block, gap: CGFloat, rows: Int, cols: Int) {
        self.block = block
        self.gap = gap
        self.rows = rows
        self.cols = cols
        let blockSize = block.blockSize
        var positions = [[CGPoint]]()
        for i in 0..<rows {
            var row = [CGPoint]()
            let y = CGFloat(i) * (blockSize + gap)
            for j in 0..<cols {
                let x = CGFloat(j) * (blockSize + gap)
                row.append(CGPoint(x: x, y: y))
            }
            positions.append(row)
        }
        self.positions = positions
        let width = CGFloat(cols) * blockSize + CGFloat(cols - 1) * gap
        let height = CGFloat(rows) * blockSize + CGFloat(rows - 1) * gap
        self.size = CGSize(width: width, height: height)
    }

    func addBackground(to parent: SKNode, color: UIColor) {
        let block = self.block
        for cols in self.positions {
            for pos in cols {
                let node = block.create(color: color)
                node.position = pos
                parent.addChild(node)
            }
        }
    }
}

class PlayArea: SKSpriteNode {

    var blockPatch: BlockPatch!
    var background: SKShapeNode!
    var field: BattleField!
    var messagePanel: MessagePanel!

    var dropEffectActions: [SKAction]!

    func setup(scene: SKScene, block: Block, unit: CGFloat) {
        let gameScene = scene as! GameScene
        self.dropEffectActions = [
            SKAction.moveBy(x: 0, y: -8, duration: 0.08),
            SKAction.moveBy(x: 0, y: 8, duration: 0.08),
        ]

        //let width = scene.size.width * Conf.playAreaWidthScale
        let rows = Conf.playAreaBlockRows
        let cols = Conf.playAreaBlockCols

        //let unit = width / Conf.getPlayAreaWidthM(cols: cols)

        //let blockBorder = Conf.blockBorderM * unit
        //let blockInnerGap = Conf.blockInnerGapM * unit
        //let blockInnerBlock = Conf.blockInnerBlockM * unit
        //let block = Block(border: blockBorder, gap: blockInnerGap, size: blockInnerBlock)
        let gap = Conf.blockGapM * unit
        let border = Conf.playAreaBorderM * unit
        let patch = BlockPatch(block: block, gap: gap, rows: rows, cols: cols)
        self.blockPatch = patch

        let offset = border + gap
        let areaWidth = 2 * offset + patch.size.width
        let areaHeight = 2 * offset + patch.size.height

        // background
        let bgPatchNode = SKNode()
        bgPatchNode.position = CGPoint(x: offset, y: offset)
        patch.addBackground(to: bgPatchNode, color: Conf.blockBackgroundColor)
        let bgNode = SKShapeNode(rect: CGRect(x: 0, y: 0, width: areaWidth, height: areaHeight))
        bgNode.fillColor = .clear
        bgNode.lineWidth = border
        bgNode.strokeColor = Conf.playAreaBorderColor
        bgNode.position = CGPoint(x: 0, y: 0)
        bgNode.zPosition = -1
        bgNode.addChild(bgPatchNode)
        self.background = bgNode

        // message panel
        let msgPanel = MessagePanel(size: patch.size)
        msgPanel.setup(patch: patch)
        msgPanel.anchorPoint = CGPoint(x: 0, y: 0)
        msgPanel.position = CGPoint(x: offset, y: offset)
        msgPanel.zPosition = 0
        msgPanel.isHidden = false
        self.messagePanel = msgPanel

        // battle field
        let field = BattleField()
        field.setup(scene: gameScene, patch: patch, resetPlayAreaAction: SKAction.run {
            self.isUserInteractionEnabled = true
            self.messagePanel.isHidden = false
            self.messagePanel.showGoMax()
            self.field.isHidden = true
        })
        field.position = CGPoint(x: offset, y: offset)
        field.zPosition = 0
        field.isHidden = true
        self.field = field

        // set props and add to scene
        let margin = Conf.margin
        let posX = margin
        let posY = scene.size.height - margin - areaHeight

        self.addChild(bgNode)
        self.addChild(field)
        self.addChild(msgPanel)
        self.color = .clear
        self.size = CGSize(width: areaWidth, height: areaHeight)
        self.position = CGPoint(x: posX, y: posY)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.isUserInteractionEnabled = true
        scene.addChild(self)
    }

    func newGame() {
        self.messagePanel.isHidden = true
        self.field.isHidden = false
        self.field.newGame()
    }

    func pause()   {
        self.field.pause()
        self.field.isHidden = true
        self.messagePanel.isHidden = false
        self.messagePanel.showPaused()
    }

    func unpause() {
        self.field.unpause()
        self.field.isHidden = false
        self.messagePanel.isHidden = true
    }

    func reset()   {
        self.isUserInteractionEnabled = false
        self.field.reset()
    }

    func drop() {
        if let p = self.field.startDrop() {
            self.run(SKAction.sequence([
                dropEffectActions[0],
                dropEffectActions[1],
                SKAction.run { self.field.finishDrop(p) }
                ]))
        }
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = self.scene as! GameScene
        scene.playAreaTouched()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {}
}

class BattleFieldGround {

    var blocks = [[BlockNode?]]()
    var topRow = 0
    var fullRows: [Int]?

    init(rows: Int, cols: Int) {
        for _ in 0..<rows {
            var nodes = [BlockNode?]()
            for _ in 0..<cols {
                nodes.append(nil)
            }
            blocks.append(nodes)
        }
    }

    subscript(row: Int, col: Int) -> BlockNode? {
        return blocks[row][col]
    }

    func land(_ p: Piece) -> Int? {
        // add piece blocks
        var rows = Set<Int>()
        for n in p.blocks() {
            n.setColor(Conf.groundColor)
            blocks[n.row][n.col] = n
            rows.insert(n.row)
            if n.row > topRow {
                topRow = n.row
            }
        }
        // find filled rows
        var fullRows = [Int]()
        for i in rows {
            var full = true
            for one in blocks[i] {
                if one == nil {
                    full = false
                    continue
                }
            }
            if full {
                fullRows.append(i)
            }
        }
        if fullRows.count > 0 {
            if fullRows.count > 1 {
                fullRows.sort()
            }
            self.fullRows = fullRows
            return fullRows.count
        } else {
            self.fullRows = nil
            return nil
        }
    }

    func clearRow(store: BlockNodeStore, row: Int) {
        let cnt = blocks[row].count
        for col in 0..<cnt {
            if let n = blocks[row][col] {
                store.push(n)
                blocks[row][col] = nil
            }
        }
    }

    func clearRow(store: BlockNodeStore) {
        if let row = fullRows?.last {
            clearRow(store: store, row: row)
        }
    }

    func moveBlocksDownAfterRowCleared(patch: BlockPatch) {
        if let row = fullRows?.popLast() {
            if row < topRow {
                let cols = patch.cols
                for i in row..<topRow {
                    for j in 0..<cols {
                        blocks[i][j] = blocks[i+1][j]
                        if let n = blocks[i][j] {
                            n.row -= 1
                            n.position = patch.positions[n.row][n.col]
                        }
                    }
                }
                for j in 0..<cols {
                    blocks[topRow][j] = nil
                }
            }
            topRow -= 1
        }
    }

    func fillRow(field: BattleField, row: Int) {
        let store = field.store!
        let patch = field.patch!
        let cols = blocks[row].count
        for col in 0..<cols {
            if blocks[row][col] == nil {
                let block = store.pop(1).first!
                block.setColor(Conf.groundColor)
                block.row = row
                block.col = col
                block.position = patch.positions[row][col]
                blocks[row][col] = block
                field.addChild(block)
            }
        }
    }
}

func reCalculateFontSize(node: SKLabelNode, upper: CGFloat, bottom: CGFloat) -> CGFloat {
    var fontsize = node.fontSize
    //os_log("initial fontsize=%f, upper=%f, bottom=%f, node frame width=%f", type: .debug, fontsize, upper, bottom, node.frame.width)
    if node.frame.width > upper {
        while node.frame.width > upper {
            fontsize -= 1
            node.fontSize = fontsize
            //os_log("fontsize=%f, node frame width=%f", type: .debug, fontsize, node.frame.width)
        }
    } else if node.frame.width < bottom {
        while node.frame.width < bottom {
            fontsize += 1
            node.fontSize = fontsize
            //os_log("fontsize=%f, node frame width=%f", type: .debug, fontsize, node.frame.width)
        }
    }
    return fontsize
}

class MessagePanel: SKSpriteNode {

    init(size: CGSize) {
        super.init(texture: nil, color: .clear, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var goMaxLabel:  SKLabelNode!
    var pausedLabel: SKLabelNode!

    func setup(patch: BlockPatch) {

        let flashAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.unhide(),
            SKAction.wait(forDuration: 0.8),
            SKAction.hide(),
            SKAction.wait(forDuration: 0.5)
            ]))

        var fontsize = CGFloat(100)
        // go max label
        var ln = SKLabelNode()
        ln.text = "GO MAX!"
        ln.fontName = Conf.fontName
        ln.fontColor = Conf.fontColor
        ln.fontSize = fontsize
        ln.horizontalAlignmentMode = .left
        // re-caculate fontsize
        let upper = self.size.width - 2
        let bottom = self.size.width * 0.8
        fontsize = reCalculateFontSize(node: ln, upper: upper, bottom: bottom)
        //os_log("lable fontsize=%f, width=%f, height=%f", type: .debug, fontsize, ln.frame.width, ln.frame.height)
        //os_log("message panel width=%f, height=%f", type: .debug, self.size.width, self.size.height)
        ln.position = CGPoint(x: (self.size.width - ln.frame.width) / 2,
                              y: (self.size.height - ln.frame.height) / 2)
        ln.run(flashAction)
        self.goMaxLabel = ln
        self.addChild(ln)

        // paused label
        ln = SKLabelNode()
        ln.text = "Paused"
        ln.fontName = Conf.fontName
        ln.fontColor = Conf.fontColor
        ln.fontSize = fontsize
        ln.horizontalAlignmentMode = .left
        ln.position = CGPoint(x: (self.size.width - ln.frame.width) / 2,
                              y: (self.size.height - ln.frame.height) / 2)
        ln.run(flashAction)
        self.pausedLabel = ln
    }

    func showGoMax() {
        if pausedLabel.parent != nil {
            pausedLabel.removeFromParent()
        }
        if goMaxLabel.parent == nil {
            addChild(goMaxLabel)
        }
    }

    func showPaused() {
        if goMaxLabel.parent != nil {
            goMaxLabel.removeFromParent()
        }
        if pausedLabel.parent == nil {
            addChild(pausedLabel)
        }
    }
}

class GameData {

    var loaded = false

    let maxSpeed = 6

    var clears = 0
    var speed = 1
    var rowClearScore = 0
    var score = 0
    var topScore = 0

    let speedScoreFactor = [
        1: 1.0,
        2: 1.5,
        3: 2.0,
        4: 3.0,
        5: 4.5,
        6: 6.0
    ]

    let clearsSpeedMap = [
        20:  2,
        50:  3,
        100: 4,
        180: 5,
        300: 6
    ]

    func newGame() {
        clears = 0
        rowClearScore = 0
        score = 0
    }

    func reset() {
        //speed = 1
        //clears = 0
        //rowClearScore = 0
        //score = 0
    }

    func clearOneRow() -> Bool {
        clears += 1
        let scoreFactor = speedScoreFactor[speed] ?? 1
        rowClearScore = 2 * rowClearScore + Int(10 * scoreFactor)
        score += rowClearScore
        if score > topScore { topScore = score }
        if speed == maxSpeed { return false }
        if let newSpeed = clearsSpeedMap[clears], newSpeed > speed {
            speed = newSpeed
            return true
        } else {
            return false
        }
    }

    func changeSpeed() {
        speed += 1
        if speed > maxSpeed { speed = 1 }

    }
}

class BattleField: SKNode {

    var store: BlockNodeStore!
    var patch: BlockPatch!
    var pieces: [Piece]!
    var pieceRander: GKRandomDistribution!
    var piece: Piece?
    var nextPiece: Piece?
    var ground: BattleFieldGround!

    let moveLeftActionKey         = "movePieceLeft"
    let moveRightActionKey        = "movePieceRight"
    let moveDownActionKey         = "movePieceDown"
    let fallActionKey             = "fallPiece"
    let clearRowActionKey         = "clearRow"
    let resetActionKey            = "reset"

    var moveLeftAction:         SKAction!
    var moveRightAction:        SKAction!
    var moveDownAction:         SKAction!
    var rotateAction:           SKAction!
    var fallAction:             SKAction!
    var clearRowAction:         SKAction!
    var resetAction:            SKAction!

    var gameData = GameData()

    func createFallAction(speed: Int) -> SKAction {
        return SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 1.0 / Double(speed)),
            SKAction.run {
                if let p = self.piece {
                    if !p.moveDown() {
                        self.piece = nil
                        self.land(p)
                    }
                }
            }
            ]))
    }

    func setupActions(scene: GameScene, patch: BlockPatch, resetPlayAreaAction: SKAction) {
        let repeatActionInterval = 0.07
        let installRepeatActionInterval = 0.3
        let moveSoundEffectAction = SKAction.run {
            if self.piece != nil { scene.playSoundEffect("move") }
        }
        let rotateSoundEffectAction = SKAction.run {
            if self.piece != nil { scene.playSoundEffect("rotate") }
        }
        let clearSoundEffectAction = SKAction.run { scene.playSoundEffect("clear") }
        // move left
        self.moveLeftAction = SKAction.sequence([
            moveSoundEffectAction,
            SKAction.run {
                if let p = self.piece {
                    p.moveLeft()
                }
            },
            SKAction.wait(forDuration: installRepeatActionInterval),
            SKAction.repeatForever(SKAction.sequence([
                moveSoundEffectAction,
                SKAction.run {
                    if let p = self.piece {
                        p.moveLeft()
                    }
                },
                SKAction.wait(forDuration: repeatActionInterval)
                ]))
            ])
        // move right
        self.moveRightAction = SKAction.sequence([
            moveSoundEffectAction,
            SKAction.run {
                if let p = self.piece {
                    p.moveRight()
                }
            },
            SKAction.wait(forDuration: installRepeatActionInterval),
            SKAction.repeatForever(SKAction.sequence([
                moveSoundEffectAction,
                SKAction.run {
                    if let p = self.piece {
                        p.moveRight()
                    }
                },
                SKAction.wait(forDuration: repeatActionInterval)
                ]))
            ])
        // move down
        self.moveDownAction = SKAction.sequence([
            moveSoundEffectAction,
            SKAction.run {
                if let p = self.piece {
                    if !p.moveDown() {
                        self.piece = nil
                        self.land(p)
                    }
                }
            },
            SKAction.wait(forDuration: installRepeatActionInterval),
            SKAction.repeatForever(SKAction.sequence([
                moveSoundEffectAction,
                SKAction.run {
                    if let p = self.piece {
                        if !p.moveDown() {
                            self.piece = nil
                            self.land(p)
                        }
                    }
                },
                SKAction.wait(forDuration: repeatActionInterval)
                ]))
            ])
        // rotate
        self.rotateAction = SKAction.sequence([
            rotateSoundEffectAction,
            SKAction.run { if let p = self.piece { p.rotate() }}
            ])
        // auto falling - created in newGame() and clearRowAction
        //self.fallAction = createFallAction(speed: self.gameData.speed)
        // clear one row
        self.clearRowAction = SKAction.sequence([
            clearSoundEffectAction,
            SKAction.run { self.ground.clearRow(store: self.store) },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { self.ground.moveBlocksDownAfterRowCleared(patch: self.patch) },
            SKAction.wait(forDuration: 0.15),
            SKAction.run {
                if self.gameData.clearOneRow() {
                    self.removeAction(forKey: self.fallActionKey)
                    self.fallAction = self.createFallAction(speed: self.gameData.speed)
                    self.run(self.fallAction, withKey: self.fallActionKey)
                }
                scene.updateInfoArea(self.gameData)
            }
            ])
        // reset game
        var resetActionArray = [SKAction]()
        resetActionArray.append(SKAction.run { scene.playSoundEffect("over") })
        for row in 0..<patch.rows {
            resetActionArray.append(SKAction.run { self.ground.fillRow(field: self, row: row) })
            resetActionArray.append(SKAction.wait(forDuration: 0.03))
        }
        for row in (0..<patch.rows).reversed() {
            resetActionArray.append(SKAction.run { self.ground.clearRow(store: self.store!, row: row) })
            resetActionArray.append(SKAction.wait(forDuration: 0.03))
        }
        resetActionArray.append(resetPlayAreaAction)
        self.resetAction = SKAction.sequence(resetActionArray)
    }

    func setup(scene: GameScene,
               patch: BlockPatch,
               resetPlayAreaAction: SKAction) {
        self.patch = patch
        self.store = BlockNodeStore(patch.block, patch.rows * patch.cols)
        self.ground = BattleFieldGround(rows: patch.rows, cols: patch.cols)
        self.pieces = [
            PieceO(self),
            PieceI(self),
            PieceT(self),
            PieceS(self),
            PieceZ(self),
            PieceJ(self),
            PieceL(self)
        ]
        self.pieceRander = GKRandomDistribution(lowestValue: 0, highestValue: self.pieces.count-1)
        setupActions(scene: scene, patch: patch, resetPlayAreaAction: resetPlayAreaAction)
    }

    func getPieceBlocks(_ count: Int) -> [BlockNode] {
        return self.store.pop(count)
    }

    func returnPieceBlocks(_ p: Piece) {
        self.store.push(p.blocks())
    }

    func createPiece() -> Piece? {
        if nextPiece == nil {
            nextPiece = pieces[pieceRander.nextInt()]
        }
        let p = nextPiece!
        nextPiece = pieces[pieceRander.nextInt()]
        return p.setup()
    }

    func pause() {
        self.removeAction(forKey: self.fallActionKey)
        self.removeAction(forKey: self.moveLeftActionKey)
        self.removeAction(forKey: self.moveRightActionKey)
        self.removeAction(forKey: self.moveDownActionKey)
    }

    func unpause() {
        self.run(self.fallAction, withKey: self.fallActionKey)
    }

    func newGame() {
        self.gameData.newGame()
        self.piece = self.createPiece()
        self.fallAction = self.createFallAction(speed: self.gameData.speed)
        self.run(self.fallAction, withKey: self.fallActionKey)
        let scene = self.scene as! GameScene
        scene.updateNextPiece(nextPiece)
        scene.updateInfoArea(self.gameData)
    }

    func reset() {
        self.gameData.reset()
        self.removeAllActions()
        self.run(self.resetAction, withKey: self.resetActionKey)
    }

    func changeGameSpeed() {
        self.gameData.changeSpeed()
        self.removeAction(forKey: self.fallActionKey)
        self.fallAction = createFallAction(speed: self.gameData.speed)
        self.run(self.fallAction, withKey: self.fallActionKey)
        (self.scene as! GameScene).updateInfoArea(self.gameData)
    }

    func newPiece() {
        // create a new piece
        self.piece = self.createPiece()
        let scene = self.scene as! GameScene
        // or game over: no room for the new piece
        if self.piece == nil {
            scene.reset()
        } else {
            scene.updateNextPiece(self.nextPiece)
        }
    }

    func land(_ p: Piece) {
        (self.scene as! GameScene).playSoundEffect("land")
        // land piece blocks
        if let fullRowCnt = ground.land(p) {
            //os_log("land(), fullRowCnt=%d", type: .debug, fullRowCnt)
            self.clearRows(count: fullRowCnt)
        } else {
            self.gameData.rowClearScore = 0
            self.newPiece()
        }
    }

    func moveLeft(_ start: Bool) {
        if start {
            self.run(self.moveLeftAction, withKey: self.moveLeftActionKey)
        } else {
            self.removeAction(forKey: self.moveLeftActionKey)
            //self.removeAction(forKey: self.moveLeftRepeatActionKey)
        }
    }

    func moveRight(_ start: Bool) {
        if start {
            self.run(self.moveRightAction, withKey: self.moveRightActionKey)
        } else {
            self.removeAction(forKey: self.moveRightActionKey)
        }
    }

    func moveDown(_ start: Bool) {
        if start {
            self.removeAction(forKey: self.fallActionKey)
            self.run(self.moveDownAction, withKey: self.moveDownActionKey)
        } else {
            self.removeAction(forKey: self.moveDownActionKey)
            self.run(self.fallAction, withKey: self.fallActionKey)
        }
    }

    func startDrop() -> Piece? {
        if let p = self.piece {
            self.removeAction(forKey: self.fallActionKey)
            self.piece = nil
            p.drop()
            return p
        } else {
            return nil
        }
    }

    func finishDrop(_ p: Piece) {
        self.run(self.fallAction, withKey: self.fallActionKey)
        self.land(p)
    }

    func clearRows(count: Int) {
        let ac = SKAction.sequence([
            SKAction.repeat(self.clearRowAction, count: count),
            SKAction.run { self.newPiece() }
            ])
        self.run(ac, withKey: self.clearRowActionKey)
    }

    func rotate() {
        self.run(self.rotateAction)
    }
}

class GameButton: SKSpriteNode {

    var active:   (() -> Void)?
    var deactive: (() -> Void)?

    init(size: CGSize, shape: SKShapeNode) {
        super.init(texture: nil, color: .clear, size: size)
        shape.lineWidth = 2
        shape.strokeColor = Conf.disabledColor
        shape.fillColor = Conf.disabledColor
        self.addChild(shape)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enable() {
        let shape = self.children[0] as! SKShapeNode
        shape.strokeColor = Conf.enabledColor
        shape.fillColor = .clear
        self.isUserInteractionEnabled = true
    }

    func disable() {
        let shape = self.children[0] as! SKShapeNode
        shape.strokeColor = Conf.disabledColor
        shape.fillColor = Conf.disabledColor
        self.isUserInteractionEnabled = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //os_log("captured touchesBegan event!", type: .debug)
        if self.isUserInteractionEnabled {
            let shape = self.children[0] as! SKShapeNode
            shape.fillColor = Conf.enabledColor
            if let a = self.active { a() }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //os_log("captured touchesEnded event!", type: .debug)
        if self.isUserInteractionEnabled {
            let shape = self.children[0] as! SKShapeNode
            shape.fillColor = .clear
            if let a = self.deactive { a() }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //os_log("captured touchesCancelled event!", type: .debug)
        if self.isUserInteractionEnabled {
            let shape = self.children[0] as! SKShapeNode
            shape.fillColor = .clear
            if let a = self.deactive { a() }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {}
}

func leftArrowPath(size: CGSize) -> CGPath {
    let points = [CGPoint(x: 0,          y: size.height / 2),
                  CGPoint(x: size.width, y: 0),
                  CGPoint(x: size.width, y: size.height)]
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

func rightArrowPath(size: CGSize) -> CGPath {
    let points = [CGPoint(x: 0,          y: 0),
                  CGPoint(x: size.width, y: size.height / 2),
                  CGPoint(x: 0,          y: size.height)]
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

func downArrowPath(size: CGSize) -> CGPath {
    let points = [CGPoint(x: size.width / 2, y: 0),
                  CGPoint(x: size.width,     y: size.height),
                  CGPoint(x: 0,              y: size.height)]
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

func rotatePath(radius: CGFloat) -> CGPath {
    let width = radius / 2
    let innerRadius = width - radius
    let arrowSizeOnX = radius / 8
    let center = CGPoint(x: radius, y: radius)

    let path = CGMutablePath()
    // ourter arc
    path.addArc(center: center,
                radius: radius,
                startAngle: 1.75 * CGFloat.pi,
                endAngle: 1.25 * CGFloat.pi,
                clockwise: false)

    /*
     // half circle to connect outer/inner arc
     var t = radius - ((((radius * radius) / 2).squareRoot() + ((innerRadius * innerRadius) / 2).squareRoot()) / 2)
     path.addArc(center: CGPoint(x: t, y: t),
     radius: width / 2,
     startAngle: 1.25 * CGFloat.pi,
     endAngle: 0.25 * CGFloat.pi,
     clockwise: false)
     */
    // line to connect outer/inner arc
    var t = radius - ((innerRadius * innerRadius) / 2).squareRoot()
    path.addLine(to: CGPoint(x: t, y: t))

    // inner arc
    path.addArc(center: center,
                radius: innerRadius,
                startAngle: 0.25 * CGFloat.pi,
                endAngle: 0.75 * CGFloat.pi,
                clockwise: true)

    // arrow
    t = 2 * (2 * arrowSizeOnX * arrowSizeOnX).squareRoot() + width
    let offset = ((t * t) / 2).squareRoot()

    var currentPoint = path.currentPoint
    path.addLine(to: CGPoint(x: currentPoint.x - arrowSizeOnX, y: currentPoint.y + arrowSizeOnX))

    currentPoint = path.currentPoint
    path.addLine(to: CGPoint(x: currentPoint.x, y: currentPoint.y - offset))

    currentPoint = path.currentPoint
    path.addLine(to: CGPoint(x: currentPoint.x + offset, y: currentPoint.y))

    // close the path
    path.closeSubpath()

    return path
}

func shapeNode(path: CGPath, position: CGPoint) -> SKShapeNode {
    let node = SKShapeNode(path: path)
    node.position = position
    node.lineCap = .round
    node.lineJoin = .round
    return node
}

class ControlArea: SKNode {

    var left:   GameButton!
    var rotate: GameButton!
    var right:  GameButton!
    var down:   GameButton!

    func setup(scene: SKScene,
               playAreaWidth: CGFloat,
               rect: CGRect) {
        let leftRightWidth  = playAreaWidth / 2
        let height = rect.height
        let downWidth = rect.size.width - playAreaWidth
        let downHeight = height
        let size = CGSize(width: leftRightWidth, height: height)

        let arrowWidth = leftRightWidth * 0.5
        let arrowHeight = 1.5 * arrowWidth
        let arrowSize = CGSize(width: arrowWidth, height: arrowHeight)

        let gameScene = scene as! GameScene

        // move left button
        var path = leftArrowPath(size: arrowSize)
        var shape = shapeNode(path: path,
                              position: CGPoint(x: (leftRightWidth - arrowWidth) / 3,
                                                y: (height - arrowHeight) / 2))
        let left = GameButton(size: size, shape: shape)
        left.position = CGPoint(x: 0, y: 0)
        left.active = { gameScene.movePieceLeft(true) }
        left.deactive = { gameScene.movePieceLeft(false) }
        self.left = left

        // move right button
        path = rightArrowPath(size: arrowSize)
        shape = shapeNode(path: path,
                          position: CGPoint(x: (leftRightWidth - arrowWidth) * 2 / 3,
                                            y: (height - arrowHeight) / 2))
        let right = GameButton(size: size, shape: shape)
        right.position = CGPoint(x: leftRightWidth, y: 0)
        right.active = { gameScene.movePieceRight(true) }
        right.deactive = { gameScene.movePieceRight(false) }
        self.right = right

        // move down button
        let downSize = CGSize(width: downWidth, height: height)
        let downArrowWidth = arrowHeight
        let downArrowHeight = arrowWidth
        path = downArrowPath(size: CGSize(width: downArrowWidth, height: downArrowHeight))
        shape = shapeNode(path: path,
                          position: CGPoint(x: (downWidth - downArrowWidth) / 2,
                                            y: (downHeight - downArrowHeight) / 2))
        let down = GameButton(size: downSize, shape: shape)
        down.position = CGPoint(x: playAreaWidth, y: 0)
        down.active = { gameScene.movePieceDown(true) }
        down.deactive = moveDownOrDrop
        self.down = down

        // rotate button
        let rotateSize = arrowHeight
        let rotateWidth = downWidth
        let rotateHeight = downWidth
        path = rotatePath(radius: rotateSize / 2)
        let rotatePosition = CGPoint(x: (rotateWidth - rotateSize) / 2, y: (rotateHeight - rotateSize) / 2)
        shape = shapeNode(path: path, position: rotatePosition)
        let rotate = GameButton(size: CGSize(width: rotateWidth, height: rotateHeight), shape: shape)
        rotate.position = CGPoint(x: playAreaWidth, y: down.frame.height)
        rotate.active = { gameScene.rotatePiece() }
        self.rotate = rotate



        self.addChild(left)
        self.addChild(right)
        self.addChild(rotate)
        self.addChild(down)

        self.position = rect.origin
        scene.addChild(self)
    }

    func enable() {
        self.left.enable()
        self.rotate.enable()
        self.right.enable()
        self.down.enable()
    }

    func disable() {
        self.left.disable()
        self.rotate.disable()
        self.right.disable()
        self.down.disable()
    }

    func setIgnoreUserInteraction(_ ignore: Bool) {
        self.left.isUserInteractionEnabled = !ignore
        self.rotate.isUserInteractionEnabled = !ignore
        self.right.isUserInteractionEnabled = !ignore
        self.down.isUserInteractionEnabled = !ignore
    }

    var lastDownTouchEnd: Date?
    func moveDownOrDrop() {
        let scene = self.scene as! GameScene
        scene.movePieceDown(false)
        let nowTs = Date()
        if let lastTs = lastDownTouchEnd {
            let interval = nowTs.timeIntervalSince(lastTs)
            //os_log("interval=%f", type: .debug, interval)
            if interval < 0.18 {
                scene.dropPiece()
            }
        }
        lastDownTouchEnd = nowTs
    }
}

class NextPiece: SKNode {

    let patch: BlockPatch
    let blocks: [BlockNode]

    init(patch: BlockPatch) {
        self.patch = patch
        // create blocks nodes
        var blocks = [BlockNode]()
        for _ in 0..<4 {
            let b = patch.block.create(color: Conf.blockColor)
            b.isHidden = true
            blocks.append(b)
        }
        self.blocks = blocks

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        patch.addBackground(to: self, color: Conf.blockBackgroundColor)
        for b in blocks {
            self.addChild(b)
        }
    }

    func update(_ piece: Piece?) {
        if let p = piece {
            let locs = p.initRelativeLocations()
            let r = 1
            let c = (4 - p.width()) / 2
            for i in 0..<locs.count {
                let (row, col) = locs[i]
                blocks[i].row = r + row
                blocks[i].col = c + col
                blocks[i].position = patch.positions[blocks[i].row][blocks[i].col]
                blocks[i].isHidden = false
            }
        } else {
            for b in blocks {
                b.isHidden = true
            }
        }
    }
}

class FallSpeedDisplayNode: SKSpriteNode {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.scene as! GameScene).changeGameSpeed()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {}
}

class SPeakerDisplayNode: SKSpriteNode {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.scene as! GameScene).toggleSpeaker()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {}
}

func configLabelNode(node: SKLabelNode, text: String, fontsize: CGFloat) {
    node.text = text
    node.fontName = Conf.fontName
    node.fontColor = Conf.fontColor
    node.horizontalAlignmentMode = .left
    node.fontSize = fontsize
}

func speakerPath(width: CGFloat, height: CGFloat) -> CGPath {
    let points = [
        CGPoint(x: 0, y: height / 6),
        CGPoint(x: width * 3 / 5, y: height / 6),
        CGPoint(x: width, y: 0),
        CGPoint(x: width, y: height),
        CGPoint(x: width * 3 / 5, y: height * 5 / 6),
        CGPoint(x: 0, y: height * 5 / 6)
    ]
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

class InfoArea: SKNode {

    let nextPieceLabel: SKLabelNode
    let nextPiece:      NextPiece

    let rowsClearedLabel: SKLabelNode
    let rowsCleared:      SKLabelNode

    let fallSpeedLabel: SKLabelNode
    let fallSpeed:      SKLabelNode
    let speedNode:      FallSpeedDisplayNode

    let scoreLabel: SKLabelNode
    let score:      SKLabelNode

    let topScoreLabel: SKLabelNode
    let topScore:      SKLabelNode

    let speaker:      SKShapeNode
    let speakerLabel: SKLabelNode
    let speakerNode:  SPeakerDisplayNode

    init(block: Block, unit: CGFloat) {
        let gap = unit * Conf.blockGapM
        let patch = BlockPatch(block: block, gap: gap, rows: 2, cols: 4)
        self.nextPiece = NextPiece(patch: patch)
        self.nextPieceLabel = SKLabelNode()

        self.rowsCleared = SKLabelNode()
        self.rowsClearedLabel = SKLabelNode()

        self.fallSpeed = SKLabelNode()
        self.fallSpeedLabel = SKLabelNode()
        self.speedNode = FallSpeedDisplayNode(color: .clear, size: CGSize(width: 0, height: 0))

        self.score = SKLabelNode()
        self.scoreLabel = SKLabelNode()

        self.topScore = SKLabelNode()
        self.topScoreLabel = SKLabelNode()

        self.speaker = SKShapeNode(rectOf: CGSize(width: 0, height: 0))
        self.speakerLabel = SKLabelNode()
        self.speakerNode = SPeakerDisplayNode()

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func speakerLabelText(mute: Bool) -> String {
        return mute ? "OFF" : "ON"
    }

    func setup(scene: GameScene, rect: CGRect, data: GameData) {
        let gap = CGFloat(18)

        // next piece
        let x = (rect.width - nextPiece.patch.size.width) / 2
        var y = CGFloat(0)
        nextPiece.setup()
        nextPiece.position = CGPoint(x: x, y: y)
        addChild(nextPiece)

        // next piece label
        // trick: use the longest label text ("Top Score") to find the proper font size
        // then set the text to "Next"
        configLabelNode(node: nextPieceLabel, text: "Top Score", fontsize: CGFloat(50))
        let upper = nextPiece.patch.size.width * 1.0
        let bottom = nextPiece.patch.size.width * 0.8
        let labelFontSize = reCalculateFontSize(node: nextPieceLabel, upper: upper, bottom: bottom)
        nextPieceLabel.text = "Next"
        y = nextPiece.patch.size.height + 3 * Conf.margin
        nextPieceLabel.position = CGPoint(x: x, y: y)
        addChild(nextPieceLabel)

        let numberFontSize = labelFontSize

        // rows cleared
        configLabelNode(node: rowsCleared, text: String(data.clears), fontsize: numberFontSize)
        rowsCleared.horizontalAlignmentMode = .right
        y = nextPieceLabel.position.y + nextPieceLabel.frame.height + gap
        rowsCleared.position = CGPoint(x: rect.size.width, y: y)
        addChild(rowsCleared)

        // rows cleared label
        configLabelNode(node: rowsClearedLabel, text: "Clears", fontsize: labelFontSize)
        y = rowsCleared.position.y + rowsCleared.frame.height + 3 * Conf.margin
        rowsClearedLabel.position = CGPoint(x: x, y: y)
        addChild(rowsClearedLabel)

        // score
        configLabelNode(node: score, text: String(data.score), fontsize: numberFontSize)
        score.horizontalAlignmentMode = .right
        y = rowsClearedLabel.position.y + rowsClearedLabel.frame.height + gap
        score.position = CGPoint(x: rect.size.width, y: y)
        addChild(score)

        // score label
        configLabelNode(node: scoreLabel, text: "Score", fontsize: labelFontSize)
        y = score.position.y + score.frame.height + 3 * Conf.margin
        scoreLabel.position = CGPoint(x: x, y: y)
        addChild(scoreLabel)

        // top score
        configLabelNode(node: topScore, text: String(data.topScore), fontsize: numberFontSize)
        topScore.horizontalAlignmentMode = .right
        y = scoreLabel.position.y + scoreLabel.frame.height + gap
        topScore.position = CGPoint(x: rect.size.width, y: y)
        addChild(topScore)

        // top score label
        configLabelNode(node: topScoreLabel, text: "Top Score", fontsize: labelFontSize)
        y = topScore.position.y + topScore.frame.height + 3 * Conf.margin
        topScoreLabel.position = CGPoint(x: x, y: y)
        addChild(topScoreLabel)

        // fall speed
        configLabelNode(node: fallSpeed, text: String(data.speed), fontsize: numberFontSize)
        fallSpeed.horizontalAlignmentMode = .right
        fallSpeed.position = CGPoint(x: rect.size.width, y: 0)
        //addChild(fallSpeed)

        // fall speed label
        configLabelNode(node: fallSpeedLabel, text: "Speed", fontsize: labelFontSize)
        y = fallSpeed.frame.height + 3 * Conf.margin
        fallSpeedLabel.position = CGPoint(x: x, y: y)
        //addChild(fallSpeedLabel)

        // speed group node, for user touch to change speed
        var w = rect.size.width - 3 * Conf.margin
        var h = fallSpeed.frame.height + 3 * Conf.margin + fallSpeedLabel.frame.height
        speedNode.size = CGSize(width: w, height: h)
        speedNode.addChild(fallSpeed)
        speedNode.addChild(fallSpeedLabel)
        y = topScoreLabel.position.y + topScoreLabel.frame.height + gap
        speedNode.position = CGPoint(x: 0, y: y)
        speedNode.isUserInteractionEnabled = true
        addChild(speedNode)

        // speaker shape node
        w = labelFontSize * 0.6
        h = labelFontSize
        speaker.path = speakerPath(width: w, height: h)
        speaker.strokeColor = Conf.fontColor
        speaker.fillColor = Conf.fontColor
        speaker.position = CGPoint(x: x, y: 0)

        // speaker label
        configLabelNode(node: speakerLabel,
                        text: speakerLabelText(mute: scene.mute),
                        fontsize: labelFontSize)
        speakerLabel.verticalAlignmentMode = .bottom
        speakerLabel.position = CGPoint(x: speaker.position.x + w + 3 * Conf.margin,
                                        y: 0)

        // speaker group node, for user touch to mute/unmute sound
        w = rect.size.width - 3 * Conf.margin
        h = labelFontSize
        speakerNode.size = CGSize(width: w, height: h)
        speakerNode.addChild(speaker)
        speakerNode.addChild(speakerLabel)
        y = speedNode.position.y + speedNode.frame.height + gap
        speakerNode.position = CGPoint(x: 0, y: y)
        speakerNode.isUserInteractionEnabled = true
        addChild(speakerNode)


        y = rect.origin.y + (rect.size.height - (speakerNode.position.y + speaker.frame.height))
        self.position = CGPoint(x: rect.origin.x, y: y)
        scene.addChild(self)
    }

    func updateNextPiece(_ piece: Piece?) {
        nextPiece.update(piece)
    }

    func updateGameData(_ data: GameData) {
        rowsCleared.text = String(data.clears)
        fallSpeed.text = String(data.speed)
        score.text = String(data.score)
        topScore.text = String(data.topScore)
        fallSpeed.text = String(data.speed)
    }

    func updateSpeaker(mute: Bool) {
        if mute {
            speaker.strokeColor = Conf.fontDisabledColor
            speaker.fillColor = Conf.fontDisabledColor
            speakerLabel.text = speakerLabelText(mute: mute)
            speakerLabel.fontColor = Conf.fontDisabledColor
        } else {
            speaker.strokeColor = Conf.fontColor
            speaker.fillColor = Conf.fontColor
            speakerLabel.text = speakerLabelText(mute: mute)
            speakerLabel.fontColor = Conf.fontColor
        }
    }

    func reset() {
        nextPiece.update(nil)
        speedNode.isUserInteractionEnabled = true
    }

    func newGame() {
        speedNode.isUserInteractionEnabled = false
    }

    func pause() {
        speedNode.isUserInteractionEnabled = true
    }

    func unpause() {
        speedNode.isUserInteractionEnabled = false
    }
}


protocol Piece {
    func moveLeft()
    func moveRight()
    func moveDown() -> Bool
    func drop()
    func rotate()
    func rotateTo() -> [(Int, Int)]?
    func blocks() -> [BlockNode]
    func setup() -> Piece?
    func width() -> Int
    func initRelativeLocations() -> [(Int, Int)]
}


class PieceBase: Piece {

    class func checkLocations(field: BattleField, locations: [(Int, Int)]) -> [(Int, Int)]? {
        let rows = field.patch.rows
        let cols = field.patch.cols
        let ground = field.ground!
        for (row, col) in locations {
            if row < 0 || row >= rows {
                return nil
            }
            if col < 0 || col >= cols {
                return nil
            }
            if ground[row, col] != nil {
                return nil
            }
        }
        return locations
    }

    class func getBlockNodes(field: BattleField, locations: [(Int, Int)]) -> [BlockNode]? {
        // check position avalibility
        if let locs = PieceBase.checkLocations(field: field, locations: locations) {
            // get blocks and set their color, row/col and position
            let cnt = locs.count
            let blocks = field.getPieceBlocks(cnt)
            for i in 0..<cnt {
                let block = blocks[i]
                let (row, col) = locs[i]
                block.setColor(Conf.blockColor)
                block.row = row
                block.col = col
                block.position = field.patch.positions[row][col]
                field.addChild(block)
            }
            return blocks
        } else {
            return nil
        }
    }

    let _width: Int
    let _initRelativeLocs: [(Int, Int)]
    let initLocations: [(Int, Int)]
    var nodes: [BlockNode]!
    var field: BattleField

    init(field: BattleField, width: Int, locations: [(Int, Int)]) {
        assert(locations.count == 4, "expecting 4 locations, but got " + String(locations.count))
        self.field = field
        self._width = width
        self._initRelativeLocs = locations
        let patch = field.patch!
        let row = patch.rows - 1
        let col = (patch.cols - width) / 2
        var initLocs: [(Int, Int)] = []
        for (r, c) in locations {
            initLocs.append((row + r, col + c))
        }
        self.initLocations = initLocs
    }

    func width() -> Int { return _width }
    func initRelativeLocations() -> [(Int, Int)] { return _initRelativeLocs }

    func setup() -> Piece? {
        if let nodes = PieceBase.getBlockNodes(field: field, locations: initLocations) {
            self.nodes = nodes
            return self
        } else {
            return nil
        }
    }

    func blocks() -> [BlockNode] { return self.nodes }

    func rotateTo() -> [(Int, Int)]? {
        fatalError("nextRotation() -> [[(Int, Int)]]? must be implemented in subclass!")
    }

    func rotate() {
        if let candidate = rotateTo(),
            let locations = PieceBase.checkLocations(field: self.field, locations: candidate) {
            let cnt = locations.count
            for i in 0..<cnt {
                let (row, col) = locations[i]
                nodes[i].row = row
                nodes[i].col = col
                nodes[i].position = self.field.patch.positions[row][col]
            }
        }
    }

    func moveLeft() {
        var rollback = false
        // move
        for one in self.nodes {
            one.col -= 1
            if one.col < 0 {
                rollback = true
            }
        }
        if !rollback { // check ground
            for one in self.nodes {
                if self.field.ground[one.row, one.col] != nil {
                    rollback = true
                    break
                }
            }
        }
        if rollback {
            for one in self.nodes {
                one.col += 1
            }
        } else {
            self.applyChange()
        }
    }

    func moveRight() {
        var rollback = false
        let cols = field.patch.cols
        // move
        for one in self.nodes {
            one.col += 1
            if one.col == cols {
                rollback = true
            }
        }
        if !rollback { // check ground
            for one in self.nodes {
                if self.field.ground[one.row, one.col] != nil {
                    rollback = true
                    break
                }
            }
        }
        if rollback {
            for one in self.nodes {
                one.col -= 1
            }
        } else {
            self.applyChange()
        }
    }

    func moveDown() -> Bool {
        return moveDown(apply: true)
    }

    func moveDown(apply: Bool = true) -> Bool {
        var rollback = false
        // move
        for one in self.nodes {
            one.row -= 1
            if one.row < 0 {
                rollback = true
            }
        }
        if !rollback { // check ground
            for one in self.nodes {
                if self.field.ground[one.row, one.col] != nil {
                    rollback = true
                    break
                }
            }
        }
        if rollback {
            for one in self.nodes {
                one.row += 1
            }
        } else {
            self.applyChange()
        }

        return !rollback
    }

    func drop() {
        while moveDown(apply: false) {}
        self.applyChange()
    }

    func applyChange() {
        let positions = self.field.patch.positions
        for one in self.nodes {
            one.position = positions[one.row][one.col]
        }
    }
}

class PieceO: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 2, locations: [(-1, 0), (-1, 1), (0, 0), (0, 1)])
    }

    override func rotateTo() -> [(Int, Int)]? { return nil }
}

class PieceI: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 4, locations: [(0, 0), (0, 1), (0, 2), (0, 3)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row == nodes[1].row {
            return [
                (nodes[1].row-2, nodes[1].col),
                (nodes[1].row-1, nodes[1].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[1].row+1, nodes[1].col)
            ]
        } else {
            return [
                (nodes[2].row, nodes[1].col-1),
                (nodes[2].row, nodes[1].col),
                (nodes[2].row, nodes[1].col+1),
                (nodes[2].row, nodes[1].col+2)
            ]
        }
    }
}

class PieceT: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 3, locations: [(-1, 1), (0, 0), (0, 1), (0, 2)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row+1 == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[2].row == nodes[3].row { // pointing down (T)
            // to pointing left
            return [
                (nodes[0].row,   nodes[0].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[2].row,   nodes[2].col),
                (nodes[2].row+1, nodes[2].col)
            ]
        } else if nodes[0].col == nodes[2].col
            && nodes[2].col == nodes[3].col
            && nodes[1].col == nodes[0].col-1 { // pointing left
            // to pointing up
            return [
                (nodes[1].row, nodes[1].col),
                (nodes[2].row, nodes[2].col),
                (nodes[2].row, nodes[2].col+1),
                (nodes[3].row, nodes[3].col)
            ]
        } else if nodes[0].row == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[3].row == nodes[0].row+1 { // pointing up
            // to pointing right
            return [
                (nodes[1].row-1, nodes[1].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[2].row,   nodes[2].col),
                (nodes[3].row,   nodes[3].col)
            ]
        }  else if nodes[0].col == nodes[1].col
            && nodes[1].col == nodes[3].col
            && nodes[2].row == nodes[1].row { // pointing right
            // to pointing down
            return [
                (nodes[0].row, nodes[0].col),
                (nodes[1].row, nodes[1].col-1),
                (nodes[1].row, nodes[1].col),
                (nodes[2].row, nodes[2].col)
            ]
        } else {
            return nil
        }
    }
}

class PieceS: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 3, locations: [(-1, 0), (-1, 1), (0, 1), (0, 2)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row == nodes[1].row {
            return [
                (nodes[1].row-1, nodes[1].col),
                (nodes[0].row,   nodes[0].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[0].row+1, nodes[0].col)
            ]
        } else {
            return [
                (nodes[1].row,   nodes[1].col),
                (nodes[2].row,   nodes[2].col),
                (nodes[2].row+1, nodes[2].col),
                (nodes[2].row+1, nodes[2].col+1)
            ]
        }
    }
}

class PieceZ: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 3, locations: [(-1, 1), (-1, 2), (0, 0), (0, 1)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row == nodes[1].row {
            return [
                (nodes[0].row-1, nodes[0].col),
                (nodes[0].row,   nodes[0].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[1].row+1, nodes[1].col)
            ]
        } else {
            return [
                (nodes[1].row,   nodes[1].col),
                (nodes[2].row,   nodes[2].col),
                (nodes[1].row+1, nodes[1].col-1),
                (nodes[1].row+1, nodes[1].col)
            ]
        }
    }
}

class PieceJ: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 3, locations: [(-1, 0), (-1, 1), (-1, 2), (0, 0)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[2].row+1 == nodes[3].row { // pointing right
            // to pointing down
            return [
                (nodes[0].row,   nodes[0].col),
                (nodes[3].row,   nodes[3].col),
                (nodes[3].row+1, nodes[3].col),
                (nodes[3].row+1, nodes[3].col+1)
            ]
        } else if nodes[0].col == nodes[1].col
            && nodes[1].col == nodes[2].col
            && nodes[2].col+1 == nodes[3].col
            && nodes[2].row == nodes[3].row { // pointing down
            // to pointing left
            return [
                (nodes[3].row-1, nodes[3].col+1),
                (nodes[2].row,   nodes[2].col),
                (nodes[3].row,   nodes[3].col),
                (nodes[3].row,   nodes[3].col+1)
            ]
        } else if nodes[0].row+1 == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[2].row == nodes[3].row { // pointing left
            // to pointing up
            return [
                (nodes[0].row-1, nodes[0].col-1),
                (nodes[0].row-1, nodes[0].col),
                (nodes[3].row,   nodes[3].col),
                (nodes[0].row,   nodes[0].col)
            ]
        }  else if nodes[0].row == nodes[1].row
            && nodes[0].col+1 == nodes[1].col
            && nodes[1].col == nodes[2].col
            && nodes[2].col == nodes[3].col { // pointing up
            // to pointing right
            return [
                (nodes[0].row,   nodes[0].col-1),
                (nodes[0].row,   nodes[0].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[0].row+1, nodes[0].col-1)
            ]
        } else {
            return nil
        }
    }
}

class PieceL: PieceBase {

    init(_ field: BattleField) {
        super.init(field: field, width: 3, locations: [(-1, 0), (-1, 1), (-1, 2), (0, 2)])
    }

    override func rotateTo() -> [(Int, Int)]? {
        if nodes[0].row == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[2].row+1 == nodes[3].row { // pointing left
            // to pointing up
            return [
                (nodes[0].row,   nodes[0].col),
                (nodes[1].row,   nodes[1].col),
                (nodes[0].row+1, nodes[0].col),
                (nodes[0].row+2, nodes[0].col)
            ]
        } else if nodes[0].col == nodes[2].col
            && nodes[2].col == nodes[3].col
            && nodes[0].col+1 == nodes[1].col
            && nodes[0].row == nodes[1].row { // pointing up
            // to pointing right
            return [
                (nodes[2].row, nodes[2].col),
                (nodes[3].row, nodes[3].col),
                (nodes[3].row, nodes[3].col+1),
                (nodes[3].row, nodes[3].col+2)
            ]
        } else if nodes[0].row+1 == nodes[1].row
            && nodes[1].row == nodes[2].row
            && nodes[2].row == nodes[3].row { // pointing right
            // to pointing down
            return [
                (nodes[3].row-2, nodes[3].col),
                (nodes[3].row-1, nodes[3].col),
                (nodes[2].row,   nodes[2].col),
                (nodes[3].row,   nodes[3].col)
            ]
        }  else if nodes[0].col == nodes[1].col
            && nodes[1].col == nodes[3].col
            && nodes[2].row == nodes[3].row
            && nodes[2].col+1 == nodes[3].col { // pointing down
            // to pointing left
            return [
                (nodes[0].row, nodes[0].col-2),
                (nodes[0].row, nodes[0].col-1),
                (nodes[0].row, nodes[0].col),
                (nodes[1].row, nodes[1].col)
            ]
        } else {
            return nil
        }
    }
}
