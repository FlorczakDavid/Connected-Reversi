//
//  playerTexture.swift
//  Nano challenge 3 - First attempt
//
//  Created by david florczak on 23/03/2020.
//  Copyright © 2020 david florczak. All rights reserved.
//

import SpriteKit

class Token: SKShapeNode {
    var player: String?
    
    func setPlayer(_ player: String) {
        self.player = player
        self.fillColor = player == "host" ? #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        let scaleSequence = SKAction.sequence([SKAction.scaleX(to: 0.1, duration: 0.1), SKAction.scaleX(to: 1, duration: 0.1)])
        let darkenSequence = SKAction.sequence([SKAction.colorize(with: SKColor.black, colorBlendFactor: 0.25, duration: 0.1), SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)])
        let group = SKAction.group([scaleSequence, darkenSequence])
        self.run(group)
    }
}
