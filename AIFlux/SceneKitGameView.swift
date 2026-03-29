import SceneKit
import SwiftUI
import UIKit

struct SceneKitGameView: UIViewRepresentable {
    let tiles: [LetterTile]
    let targetWordLength: Int
    let selectedTileIDs: [UUID]
    let roundResult: RoundResult?
    let onSelectTile: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectTile: onSelectTile)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.scene
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.rendersContinuously = true
        scnView.preferredFramesPerSecond = 60
        scnView.autoenablesDefaultLighting = false
        scnView.isPlaying = true
        scnView.pointOfView = context.coordinator.cameraNode

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)
        context.coordinator.scnView = scnView
        context.coordinator.setupIfNeeded()
        context.coordinator.reloadTiles(tiles)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.update(
            tiles: tiles,
            targetWordLength: targetWordLength,
            selectedTileIDs: selectedTileIDs,
            roundResult: roundResult
        )
    }

    final class Coordinator: NSObject {
        let scene = SCNScene()
        let rootNode = SCNNode()
        let puzzleNode = SCNNode()
        let confettiNode = SCNNode()
        let cameraNode = SCNNode()

        var scnView: SCNView?
        private let onSelectTile: (UUID) -> Void

        private var nodesByID: [UUID: LetterNode] = [:]
        private var originalPositions: [UUID: SCNVector3] = [:]
        private var lastTileSignature: String = ""

        init(onSelectTile: @escaping (UUID) -> Void) {
            self.onSelectTile = onSelectTile
            super.init()
        }

        func setupIfNeeded() {
            guard rootNode.parent == nil else {
                return
            }

            scene.rootNode.addChildNode(rootNode)
            rootNode.addChildNode(puzzleNode)
            rootNode.addChildNode(confettiNode)

            let camera = SCNCamera()
            camera.wantsHDR = true
            camera.bloomIntensity = 1.2
            camera.bloomThreshold = 0.2
            camera.bloomBlurRadius = 8
            cameraNode.camera = camera
            rootNode.addChildNode(cameraNode)
            AnimationManager.cameraIntroZoom(cameraNode: cameraNode)

            let omni = SCNLight()
            omni.type = .omni
            omni.intensity = 1100
            omni.color = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
            let omniNode = SCNNode()
            omniNode.light = omni
            omniNode.position = SCNVector3(0, 2.8, 6)
            rootNode.addChildNode(omniNode)

            let ambient = SCNLight()
            ambient.type = .ambient
            ambient.intensity = 450
            ambient.color = UIColor(red: 0.15, green: 0.2, blue: 0.34, alpha: 1.0)
            let ambientNode = SCNNode()
            ambientNode.light = ambient
            rootNode.addChildNode(ambientNode)
        }

        func update(tiles: [LetterTile], targetWordLength: Int, selectedTileIDs: [UUID], roundResult: RoundResult?) {
            let signature = tiles.map { "\($0.id.uuidString)-\($0.index)-\($0.value)" }.joined(separator: "|")
            if signature != lastTileSignature {
                reloadTiles(tiles)
                lastTileSignature = signature
            } else {
                updateSelection(selectedTileIDs: selectedTileIDs, totalSlots: targetWordLength)
            }

            if let roundResult {
                switch roundResult {
                case .correct:
                    handleCorrectResult()
                case .incorrect:
                    handleIncorrectResult()
                }
            } else {
                restoreNodesToOriginalPositions()
            }
        }

        func reloadTiles(_ tiles: [LetterTile]) {
            puzzleNode.childNodes.forEach { $0.removeFromParentNode() }
            nodesByID.removeAll()
            originalPositions.removeAll()

            let positions = makeGridPositions(count: tiles.count)
            for (index, tile) in tiles.enumerated() {
                let node = LetterNode(tile: tile)
                let position = positions[index]
                node.position = position
                puzzleNode.addChildNode(node)
                nodesByID[tile.id] = node
                originalPositions[tile.id] = position

                AnimationManager.spawn(node: node)
                AnimationManager.applyIdleAnimation(to: node, seed: Double(index % 4) * 0.15)
            }
        }

        private func updateSelection(selectedTileIDs: [UUID], totalSlots: Int) {
            for (slotIndex, tileID) in selectedTileIDs.enumerated() {
                guard let node = nodesByID[tileID] else {
                    continue
                }
                AnimationManager.glow(node: node)
                AnimationManager.moveToAssembly(node: node, slotIndex: slotIndex, totalSlots: max(totalSlots, 3))
            }

            let selectedSet = Set(selectedTileIDs)
            for (tileID, node) in nodesByID where !selectedSet.contains(tileID) {
                guard let originalPosition = originalPositions[tileID] else {
                    continue
                }
                AnimationManager.resetNodePosition(node: node, position: originalPosition)
            }
        }

        private func handleCorrectResult() {
            for node in nodesByID.values {
                AnimationManager.explode(node: node)
            }
            AnimationManager.addConfetti(to: confettiNode)
        }

        private func handleIncorrectResult() {
            AnimationManager.shake(cameraNode: cameraNode)
            restoreNodesToOriginalPositions()
        }

        private func restoreNodesToOriginalPositions() {
            for (tileID, node) in nodesByID {
                guard let originalPosition = originalPositions[tileID] else {
                    continue
                }
                AnimationManager.resetNodePosition(node: node, position: originalPosition)
            }
        }

        private func makeGridPositions(count: Int) -> [SCNVector3] {
            let columns = max(3, Int(ceil(sqrt(Double(count)))))
            let rows = Int(ceil(Double(count) / Double(columns)))
            let spacing: Float = 1.45
            var positions: [SCNVector3] = []

            for index in 0..<count {
                let row = index / columns
                let col = index % columns
                let x = (Float(col) - Float(columns - 1) / 2) * spacing
                let y = (Float(rows - 1) / 2 - Float(row)) * spacing * 0.9
                positions.append(SCNVector3(x, y + 0.4, 0))
            }

            return positions.shuffled()
        }

        @objc
        func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scnView else {
                return
            }

            let location = recognizer.location(in: scnView)
            let hits = scnView.hitTest(location, options: nil)

            guard
                let node = hits.first?.node,
                let foundNode = resolveLetterNode(from: node),
                let id = UUID(uuidString: foundNode.name ?? "")
            else {
                return
            }

            AnimationManager.glow(node: foundNode)
            onSelectTile(id)
        }

        private func resolveLetterNode(from node: SCNNode) -> SCNNode? {
            if node is LetterNode {
                return node
            }
            return node.parent
        }
    }
}
