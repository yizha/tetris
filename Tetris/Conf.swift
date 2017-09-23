//
//  Conf.swift
//  Tetris
//
//  Created by Yicha Ding on 9/23/17.
//  Copyright © 2017 Yicha Ding. All rights reserved.
//

import UIKit

class Conf {

    static let fontName = "Chalkduster"
    static let fontColor = UIColor.black
    static let fontDisabledColor = UIColor(red: 135, green: 147, blue: 114)

    static let backgroundColor      = UIColor(red: 158, green: 173, blue: 134)
    static let blockBackgroundColor = UIColor(red: 135, green: 147, blue: 114)
    static let blockColor           = UIColor.black
    static let groundColor          = UIColor(white: 1/4, alpha: 1)
    static let playAreaBorderColor  = UIColor.black
    static let disabledColor        = UIColor(red: 135, green: 147, blue: 114)
    static let enabledColor         = UIColor.black

    static let blockGapM          = CGFloat(2)
    static let blockBorderM       = CGFloat(1)
    static let blockInnerGapM     = CGFloat(1)
    static let blockInnerBlockM   = CGFloat(6)
    static var blockM: CGFloat {
        return 2 * (blockBorderM + blockInnerGapM) + blockInnerBlockM
    }

    static let margin = CGFloat(3)

    static let playAreaWidthScale = CGFloat(0.6)
    static let playAreaBorderM    = CGFloat(1)
    static let playAreaBlockCols  = 10
    static let playAreaBlockRows  = 20
    //static func getPlayAreaWidthM(cols: Int) -> CGFloat {
    //    return 2 * playAreaBorderM + CGFloat(cols) * (blockM + blockGapM) + blockGapM
    //}

    static let nextPieceBlockRows = 2
    static let nextPieceBlockCols = 4
    static func getWidthM() -> CGFloat {
        let playAreaWidthM = 2 * playAreaBorderM + CGFloat(playAreaBlockCols) * (blockM + blockGapM) + blockGapM
        let infoAreaWidthM = CGFloat(nextPieceBlockCols) * (blockM + blockGapM) + blockGapM
        let playAreaAndInfoAreaGapM = CGFloat(1)
        return playAreaWidthM + infoAreaWidthM + playAreaAndInfoAreaGapM
    }
}
