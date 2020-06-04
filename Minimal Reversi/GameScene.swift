//
//  GameScene.swift
//  Nano challenge 3 - First attempt
//
//  Created by david florczak on 20/03/2020.
//  Copyright © 2020 david florczak. All rights reserved.
//

import SpriteKit
import Foundation
import UIKit
import MultipeerConnectivity

// Testing purposes
var gameOver = false
var wasTokenflipped = false
var isNlack = true
let directions = ["up", "upRight", "right", "downRight", "down", "downLeft", "left", "upLeft"]
let dirDic = ["up": -8, "upRight": -7, "right": 1, "downRight": 9, "down": 8, "downLeft": 7, "left": -1, "upLeft": -9]
var checkedDic: [String: Int] = [:]

class GameScene: SKScene {
    
    var colorIndex = 0
    var fields: [SKSpriteNode]!
    var currentPlayer: String!
    //    var test: UIView!
    
    var appDelegate: AppDelegate!
    
    override func didMove(to view: SKView) {
        
        currentPlayer = "black"
        setupBoard()
        
    }
    
    func setupBoard() {
        let lengthInSquares = 8
        
        let width = self.size.width/CGFloat(lengthInSquares)
        let tileSize = CGSize(width: width, height: width)
        
        for n in 0...(lengthInSquares*lengthInSquares)-1 {
            let gridX = n % lengthInSquares
            let gridY = n / lengthInSquares
            
            let color = UIColor.clear
            
            let tile = CustomTile(color: color, size: tileSize)
            //            -----Testing-----
            //            let testingNumber = SKLabelNode(text: "\(n)")
            //            testingNumber.position = .zero
            //            tile.addChild(testingNumber)
            //            -----Testing-----
            tile.position = CGPoint(x: (width/2)+CGFloat(gridX)*width, y: (self.size.height/2 + width*CGFloat(lengthInSquares/2))-CGFloat(gridY)*width)
            tile.name = "tile.\(n)"
            self.addChild(tile)
        }
        
        makeToken(tile: self.childNode(withName: "tile.27") as! CustomTile)
        makeToken(tile: self.childNode(withName: "tile.28") as! CustomTile)
        makeToken(tile: self.childNode(withName: "tile.35") as! CustomTile)
        makeToken(tile: self.childNode(withName: "tile.36") as! CustomTile)
        (self.childNode(withName: "tile.27") as! CustomTile).Token?.setPlayer("black")
        (self.childNode(withName: "tile.28") as! CustomTile).Token?.setPlayer("white")
        (self.childNode(withName: "tile.35") as! CustomTile).Token?.setPlayer("white")
        (self.childNode(withName: "tile.36") as! CustomTile).Token?.setPlayer("black")
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        //        self.backgroundColor = .black
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOver {
            self.removeAllChildren()
            self.view?.presentScene(self)
            gameOver = false
            return
        }
        
        wasTokenflipped = false
        
        if let location = touches.first?.location(in: self) {
            guard let node = self.atPoint(location) as? CustomTile
                else {
                    self.atPoint(location).run(.sequence([.scale(by: 1.2, duration: 0.1),.scale(by: 0.8, duration: 0.1),.scale(to: 1, duration: 0.1)]))
                    return
            }
            
            //            testing purposes
            checkFlips(tile: node)
            if wasTokenflipped {
                currentPlayer = currentPlayer == "black" ? "white" : "black"
                self.backgroundColor = currentPlayer == "black" ? #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                //                self.backgroundColor = currentPlayer == "black" ? .black : .white
                
            }
            checkGameOver()
            
            
            //            node.setPlayer(currentPlayer)
            print(node.name!)
        }
    }
    
    func checkFlips(tile: CustomTile) {
        if tile.hasATokenOnIt { return }
        let position = Int(tile.name!.replacingOccurrences(of: "tile.", with: ""))!
        let row = Int(position/8)
        
        var count = 0
        var checkedTile: CustomTile!
        
        
        for direction in directions {
            checkedTile = self.childNode(withName: "tile.\(position + dirDic[direction]!)") as? CustomTile
            var skipFlip = false
            
            while checkedTile != nil && checkedTile!.hasATokenOnIt && checkedTile?.Token?.player != currentPlayer {
                let checkedRow = Int(checkedTile!.name!.replacingOccurrences(of: "tile.", with: ""))!/8
                if ((direction == "left" || direction == "right") && row != checkedRow) || ((direction == "upLeft" || direction == "upRight") && row != checkedRow+1+count) || ((direction == "downLeft" || direction == "downRight") && row != checkedRow-1-count ) { skipFlip = true }
                count += 1
                checkedTile = self.childNode(withName: "tile.\(position + (dirDic[direction]!) * (1+count))") as? CustomTile
            }
            
            if checkedTile?.hasATokenOnIt ?? false && count > 0 && !skipFlip {
                flipTokens(direction: direction, tile: tile, numberOfTokensToFlip: count)
            }
            count = 0
            
        }
        
    }
    
    func flipTokens(direction: String, tile: CustomTile, numberOfTokensToFlip: Int) {
        
        let movement = dirDic[direction]
        let position = Int(tile.name!.replacingOccurrences(of: "tile.", with: ""))!
        
        var flippedTile = self.childNode(withName: "tile.\(position + movement!)") as? CustomTile
        
        //        while checkedTile != nil && checkedTile!.hasATokenOnIt /* && checkedTile!.player != node.player */ {
        for n in 1...numberOfTokensToFlip {
            let tilesToken = flippedTile!.Token
            tilesToken!.setPlayer(currentPlayer)
            flippedTile = self.childNode(withName: "tile.\(position + movement! * (1+n))") as? CustomTile
        }
        if !tile.hasATokenOnIt {
            makeToken(tile: tile)
            wasTokenflipped = true
        }
    }
    
    //:Mark todo
    func checkGameOver() {
        var white = 0
        var black = 0
        for n in 0...63 {
            let tile = (self.childNode(withName: "tile.\(n)") as! CustomTile)
            if !tile.hasATokenOnIt {
                return
            }
            if tile.Token?.player == "black" { black += 1 }
            else { white += 1 }
        }
        makeGameOver(white: white, black: black)
        
    }
    
    func makeGameOver(white: Int, black: Int) {
        for n in 0...63 {
            let token = (self.childNode(withName: "tile.\(n)") as! CustomTile).Token!
            let scaleSequence = SKAction.sequence([SKAction.scaleX(to: 0.1, duration: 0.1), SKAction.scaleX(to: 1, duration: 0.1)])
            let darkenSequence = SKAction.sequence([SKAction.colorize(with: SKColor.black, colorBlendFactor: 0.25, duration: 0.1), SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.1)])
//            token.fillColor = .clear
            let group = SKAction.group([scaleSequence, darkenSequence])
            let final = SKAction.sequence([.wait(forDuration: Double(n)*0.1), group])
            token.run(final)
        }
        self.run(.wait(forDuration: 6.5), completion: {
            self.removeAllChildren()
            if white == black {
                self.backgroundColor = .red
                gameOver = true
            }
            self.backgroundColor = white > black ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) : #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            let winner = white > black ? "white" : "black"
            let gameOverLabel = SKLabelNode(text: "the \(winner) player wins!")
            gameOverLabel.fontColor = self.backgroundColor == #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) ? #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            gameOverLabel.horizontalAlignmentMode = .center
            gameOverLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
            self.addChild(gameOverLabel)
            gameOver = true
            print(white, black)
        }
        )
        
    }
    
    func makeToken(tile: CustomTile) {
        tile.Token = Token(circleOfRadius: tile.size.width/2 - tile.size.width/10)
        tile.Token!.setPlayer(currentPlayer)
        tile.Token!.glowWidth = 0.5
        tile.Token!.strokeColor = .clear
        tile.hasATokenOnIt = true
        tile.addChild(tile.Token!)
    }
    
    func shouldFlip(tileName: String) -> Bool {
        return false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
}
