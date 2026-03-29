import SceneKit
import UIKit

final class LetterNode: SCNNode {
    let tile: LetterTile

    init(tile: LetterTile) {
        self.tile = tile
        super.init()
        name = tile.id.uuidString
        setupGeometry(letter: tile.value)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupGeometry(letter: String) {
        let base = SCNBox(width: 0.9, height: 0.9, length: 0.28, chamferRadius: 0.16)
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 1.0)
        baseMaterial.emission.contents = UIColor(red: 0.12, green: 0.42, blue: 0.58, alpha: 0.6)
        baseMaterial.metalness.contents = 0.5
        baseMaterial.roughness.contents = 0.2

        let text = SCNText(string: letter, extrusionDepth: 0.08)
        text.font = UIFont.systemFont(ofSize: 0.72, weight: .heavy)
        text.flatness = 0.2
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.white
        textMaterial.emission.contents = UIColor(red: 0.35, green: 0.89, blue: 1.0, alpha: 0.9)
        text.firstMaterial = textMaterial

        let letterNode = SCNNode(geometry: text)
        let (minBounds, maxBounds) = text.boundingBox
        let width = maxBounds.x - minBounds.x
        let height = maxBounds.y - minBounds.y

        letterNode.scale = SCNVector3(0.56, 0.56, 0.56)
        letterNode.position = SCNVector3(-width * 0.28, -height * 0.28, 0.18)

        base.materials = [baseMaterial, baseMaterial, baseMaterial, baseMaterial, baseMaterial, baseMaterial]
        geometry = base
        addChildNode(letterNode)
    }
}
