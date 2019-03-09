//
//  GameViewController.swift
//  ShibuyaViewer
//
//  Created by Jesse Armand on 9/3/19.
//  Copyright © 2019 Jesse Armand. All rights reserved.
//

import AppKit
import SceneKit
import QuartzCore

private enum ShibuyaAsset: String {
    case highBlock
    case mediumSize
}

private extension ShibuyaAsset {
    var sceneName: String {
        switch self {
        case .highBlock:
            return "shibuyaHighBlock.scnassets/Shibuya_high_2Block.scn"
        case .mediumSize:
            return "shibuyaM.scnassets/Shibuya.scn"
        }
    }

    var menuTitle: String {
        switch self {
        case .highBlock:
            return NSLocalizedString("Shibuya High Block", comment: "")
        case .mediumSize:
            return NSLocalizedString("Shibuya M Size", comment: "")
        }
    }
}

final class GameViewController: NSViewController {

    @IBOutlet weak var sceneView: SCNView!

    private var firstAssetMenuItem: NSMenuItem?
    private var secondAssetMenuItem: NSMenuItem?

    private var sceneName: String = ShibuyaAsset.highBlock.sceneName

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenus()

        updateScene(withName: sceneName)

        // set the scene to the view
        sceneView.scene = buildScene(withSceneName: sceneName)

        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // configure the view
        sceneView.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = sceneView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        sceneView.gestureRecognizers = gestureRecognizers
    }

    func setupMenus() {
        let selectItem = NSMenuItem(title: NSLocalizedString("Select", comment: ""),
                                    action: nil,
                                    keyEquivalent: "")

        let firstAssetItem = NSMenuItem(title: ShibuyaAsset.highBlock.menuTitle,
                                        action: #selector(selectAction(_:)),
                                        keyEquivalent: "")
        firstAssetItem.identifier = NSUserInterfaceItemIdentifier(ShibuyaAsset.highBlock.rawValue)
        firstAssetItem.state = .on
        firstAssetItem.tag = 1

        firstAssetMenuItem = firstAssetItem

        let secondAssetItem = NSMenuItem(title: ShibuyaAsset.mediumSize.menuTitle,
                                         action: #selector(selectAction(_:)),
                                         keyEquivalent: "")
        secondAssetItem.identifier = NSUserInterfaceItemIdentifier(ShibuyaAsset.mediumSize.rawValue)
        secondAssetItem.tag = 2

        secondAssetMenuItem = secondAssetItem

        let selectMenu = NSMenu(title: "Select")
        selectMenu.autoenablesItems = true
        selectMenu.items = [firstAssetItem, secondAssetItem]
        selectItem.submenu = selectMenu

        if let index = NSApp.mainMenu?.indexOfItem(withTitle: NSLocalizedString("File", comment: "")) {
            NSApp.mainMenu?.insertItem(selectItem, at: index + 1)
        }
    }

    @objc func selectAction(_ menuItem: NSMenuItem) {
        let menuItemIdentifier = menuItem.identifier?.rawValue ?? ""
        let selection: ShibuyaAsset = ShibuyaAsset(rawValue: menuItemIdentifier) ?? .highBlock

        switch selection {
        case .highBlock:
            firstAssetMenuItem?.state = .on
            secondAssetMenuItem?.state = .off
        case .mediumSize:
            firstAssetMenuItem?.state = .off
            secondAssetMenuItem?.state = .on
        }

        updateScene(withName: selection.sceneName)
    }

    func updateScene(withName name: String) {
        sceneView.stop(self)

        sceneName = name

        sceneView.scene = buildScene(withSceneName: name)

        sceneView.play(self)
    }

    func buildScene(withSceneName sceneName: String) -> SCNScene? {
        // create a new scene
        let scene = SCNScene(named: sceneName)

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene?.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene?.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene?.rootNode.addChildNode(ambientLightNode)

        // retrieve the camera node
        // let camera = scene.rootNode.childNode(withName: "camera", recursively: true)!

        // animate the 3d object
        // camera.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        return scene
    }
    
    @objc func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }
}
