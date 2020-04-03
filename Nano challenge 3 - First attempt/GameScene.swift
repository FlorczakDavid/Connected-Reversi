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
var wasTokenflipped = false
var isHost = true
let directions = ["up", "upRight", "right", "downRight", "down", "downLeft", "left", "upLeft"]
let dirDic = ["up": -8, "upRight": -7, "right": 1, "downRight": 9, "down": 8, "downLeft": 7, "left": -1, "upLeft": -9]
var checkedDic: [String: Int] = [:]

class GameScene: SKScene, MCBrowserViewControllerDelegate {
    
    var colorIndex = 0
    var fields: [SKSpriteNode]!
    var currentPlayer: String!
    //    var test: UIView!
    
    var appDelegate: AppDelegate!
    
    override func didMove(to view: SKView) {
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate.mpcHandler.setupPeerWithDisplayName(displayName: UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(true)
        
        //        NotificationCenter.default.addObserver(self, selector: Selector(("peerChangedStateWithNotification")), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
        /*Might use later*/
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecievedDataWithNotification), name: NSNotification.Name("MPC_DidRecieveDataNotification"), object: nil)
        
        currentPlayer = "host"
        setupBoard()
        
    }
    
    
    @objc func handleRecievedDataWithNotification(notification: NSNotification) {
        do {
            let userInfo = notification.userInfo! as Dictionary
            let receivedData: NSData = userInfo["data"] as! NSData
            let message = try JSONSerialization.jsonObject(with: receivedData as Data, options: .allowFragments) as! NSDictionary
            let senderPeerId: MCPeerID = userInfo["peerID"] as! MCPeerID
            let senderDisplayName = senderPeerId.displayName
            
            var field: String? = message.object(forKey: "field") as? String
            var player: String? = message.object(forKey: "player") as? String
            
            if field != nil && player != nil {
                (self.childNode(withName: field!)?.children.first as! Token).player = player
                
                (self.childNode(withName: field!)?.children.first as! Token).setPlayer(player!)
                
                currentPlayer = player == "host" ? "guest" : "host"
            }
        } catch { print("couldn't get JSON object from Data") }
        
    }
    
    func setupBoard() {
        let lengthInSquares = 8
        
        let width = self.size.width/CGFloat(lengthInSquares)
        let tileSize = CGSize(width: width, height: width)
        
        for n in 0...(lengthInSquares*lengthInSquares)-1 {
            let gridX = n % lengthInSquares
            let gridY = n / lengthInSquares
            
            let color = ((gridX + gridY) % 2 == 0) ? #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1) : #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            
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
        (self.childNode(withName: "tile.27") as! CustomTile).Token?.setPlayer("host")
        (self.childNode(withName: "tile.28") as! CustomTile).Token?.setPlayer("guest")
        (self.childNode(withName: "tile.35") as! CustomTile).Token?.setPlayer("guest")
        (self.childNode(withName: "tile.36") as! CustomTile).Token?.setPlayer("host")
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        connectWithPlayer()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
                currentPlayer = currentPlayer == "host" ? "guest" : "host"
                self.backgroundColor = currentPlayer == "host" ? #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            }
            
            
            //            node.setPlayer(currentPlayer)
            print(node.name!)
            let messageDic = ["field": node.name!, "player": currentPlayer]
            
            do {
                let messageData = try JSONSerialization.data(withJSONObject: messageDic, options: .prettyPrinted)
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
                
            }
            catch { print("couldn't convert messageDic to JSON or send said data") }
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
        for n in 0...63 {
            self.childNode(withName: "tile.\(n)")
        }
    }
    
    func makeToken(tile: CustomTile) {
        tile.Token = Token(circleOfRadius: tile.size.width/2 - tile.size.width/10)
        tile.Token!.setPlayer(currentPlayer)
        tile.Token!.glowWidth = 0.5
        tile.Token!.strokeColor = .black
        tile.Token!.position = .zero
        tile.hasATokenOnIt = true
        tile.addChild(tile.Token!)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func shouldFlip(tileName: String) -> Bool {
        return false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func connectWithPlayer() {
        
        if appDelegate.mpcHandler.session != nil {
            appDelegate.mpcHandler.setupBrowser()
            appDelegate.mpcHandler.browser.delegate = self
            
            self.view?.window?.rootViewController!.present(appDelegate.mpcHandler.browser, animated: true, completion: nil)
        }
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
}
