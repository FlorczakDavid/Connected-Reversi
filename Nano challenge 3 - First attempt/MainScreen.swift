//
//  MainScreen.swift
//  Nano challenge 3 - First attempt
//
//  Created by david florczak on 20/03/2020.
//  Copyright © 2020 david florczak. All rights reserved.
//

// TO ADD LATER

import SpriteKit
import MultipeerConnectivity

class MainScene: SKScene, MCSessionDelegate, MCBrowserViewControllerDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
    }
    
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    
    
    func sendScene(scene: SKScene) {
        
        if mcSession.connectedPeers.count > 0 {
            var sceneData: Data = .init(count: .zero)
            do {
                do { sceneData = try NSKeyedArchiver.archivedData(withRootObject: scene, requiringSecureCoding: true) }
                catch { print("error getting data from scene") }
                try mcSession.send(sceneData, toPeers: mcSession.connectedPeers, with: .reliable)
            } catch {
                print("error sending data")
            }
        }
    }
    
    func startHosting(action: UIAlertAction!) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "colorSquare", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction!) {
        let mcBrowser = MCBrowserViewController(serviceType: "colorSquare", session: mcSession)
        mcBrowser.delegate = self
    }
    
    override func didMove(to view: SKView) {
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        
        let buttonSize = CGSize(width: self.size.width, height: self.size.height/2)
        let joinButton = SKSpriteNode(color: .cyan, size: buttonSize)
        let hostButton = SKSpriteNode(color: .systemPink, size: buttonSize)
        
        let joinLabel = SKLabelNode(text: "join")
        let hostLabel = SKLabelNode(text: "host")
        
        joinLabel.fontColor = .black
        hostLabel.fontColor = .black
        
        joinLabel.position = .zero
        hostLabel.position = .zero
        
        joinButton.addChild(joinLabel)
        hostButton.addChild(hostLabel)
    
        joinButton.position = CGPoint(x: buttonSize.width/2, y: buttonSize.height/2)
        hostButton.position = CGPoint(x: buttonSize.width/2, y: buttonSize.height*1.5)
        
        joinButton.name = "join"
        hostButton.name = "host"
        
        self.addChild(joinButton)
        self.addChild(hostButton)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let name = nodes(at: (touches.first?.location(in: self))!).first?.name
        nodes(at: (touches.first?.location(in: self))!).first?.run(.fadeOut(withDuration: 0.2)) {
//            self.view?.presentScene(GameScene(size: self.size))
            if name == "join" {
                self.joinSession(action: .none)
            }
            if name == "host" {
                self.startHosting(action: .none)
            }
        }
    }
    
}
