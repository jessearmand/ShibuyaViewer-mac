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

        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // configure the view
        sceneView.backgroundColor = NSColor.black

        sceneView.debugOptions = [.showCameras, .showLightInfluences, .showLightExtents]
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = sceneView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        sceneView.gestureRecognizers = gestureRecognizers
    }

    private func setupMenus() {
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

        if let openMenuItem = NSApp.mainMenu?
            .item(withTitle: NSLocalizedString("File", comment: ""))?
            .submenu?
            .item(at: 1) {

            openMenuItem.target = self
            openMenuItem.action = #selector(handleOpenDocument(_:))
        }
    }

    @objc func handleOpenDocument(_ menuItem: NSMenuItem) {
        let types = ["scn", "dae"]
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        let documentController = NSDocumentController.shared
        let result = documentController.runModalOpenPanel(panel, forTypes: types)
        let response = NSApplication.ModalResponse(result)

        guard (response == .OK) else { return }
        guard let url = panel.url else { return }

        if let scene = buildScene(fromURL: url) {
            sceneView.scene = scene
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
        sceneName = name

        sceneView.scene = buildScene(withSceneName: name)

        if let cameraNode = sceneView.scene?.rootNode.childNode(withName: "camera", recursively: true) {
            if let groundNode = sceneView.scene?.rootNode.childNode(withName: "shibuya", recursively: true) {
                SCNTransaction.animationDuration = 0.8
                cameraNode.simdLook(at: groundNode.simdPosition)
            }

            sceneView.pointOfView = cameraNode
        }
    }

    func buildScene(_ scene: SCNScene) -> SCNScene {
        let lightNode = SCNNode()
        lightNode.name = "directional"
        lightNode.light = SCNLight()
        lightNode.light?.intensity = 1000
        lightNode.light?.type = .directional
        lightNode.light?.color = NSColor.white

        if let groundNode = sceneView.scene?.rootNode.childNode(withName: "shibuya", recursively: true) {
            lightNode.simdPosition = float3(groundNode.simdPosition.x, groundNode.simdPosition.y + 100, groundNode.simdPosition.z)
        }

        scene.rootNode.addChildNode(lightNode)

        return scene
    }

    func buildScene(withSceneName sceneName: String) -> SCNScene? {
        // create a new scene
        guard let scene = SCNScene(named: sceneName) else {
            print("\(#function) error opening scene named \(sceneName)")
            return nil
        }

        return buildScene(scene)
    }

    func buildScene(fromURL url: URL) -> SCNScene? {
        do {
            let scene = try SCNScene(url: url, options: [:])
            return scene
        } catch {
            print("Unable to open scene at \(url)\nerror: \(error)")
            return nil
        }
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
            let material = result.node.geometry?.firstMaterial
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material?.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material?.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }
}
