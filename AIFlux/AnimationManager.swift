import SceneKit
import UIKit

enum AnimationManager {
    static func applyIdleAnimation(to node: SCNNode, seed: Double) {
        let floatAction = SCNAction.sequence([
            .moveBy(x: 0, y: 0.14, z: 0, duration: 1.6 + seed),
            .moveBy(x: 0, y: -0.14, z: 0, duration: 1.6 + seed)
        ])
        floatAction.timingMode = .easeInEaseOut

        let rotateAction = SCNAction.sequence([
            .rotateBy(x: 0.04, y: 0.18, z: 0.05, duration: 1.3 + seed),
            .rotateBy(x: -0.04, y: -0.18, z: -0.05, duration: 1.3 + seed)
        ])
        rotateAction.timingMode = .easeInEaseOut

        node.runAction(.repeatForever(floatAction), forKey: "idleFloat")
        node.runAction(.repeatForever(rotateAction), forKey: "idleRotate")
    }

    static func spawn(node: SCNNode) {
        node.opacity = 0
        node.scale = SCNVector3(0.01, 0.01, 0.01)

        let appear = SCNAction.group([
            .fadeIn(duration: 0.28),
            .scale(to: 1.0, duration: 0.28)
        ])
        appear.timingMode = .easeOut
        node.runAction(appear)
    }

    static func glow(node: SCNNode) {
        guard let material = node.geometry?.firstMaterial else {
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        material.emission.contents = UIColor(red: 0.72, green: 0.98, blue: 1.0, alpha: 1.0)
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            material.emission.contents = UIColor(red: 0.12, green: 0.42, blue: 0.58, alpha: 0.6)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }

    static func moveToAssembly(node: SCNNode, slotIndex: Int, totalSlots: Int) {
        let spacing: Float = 0.55
        let totalWidth = Float(totalSlots - 1) * spacing
        let targetX = -totalWidth / 2 + Float(slotIndex) * spacing

        let move = SCNAction.move(to: SCNVector3(targetX, -1.9, 0.5), duration: 0.22)
        move.timingMode = .easeOut
        node.runAction(move, forKey: "moveToAssembly")
    }

    static func resetNodePosition(node: SCNNode, position: SCNVector3) {
        let move = SCNAction.move(to: position, duration: 0.22)
        move.timingMode = .easeInEaseOut
        node.runAction(move, forKey: "resetPosition")
    }

    static func shuffle(node: SCNNode, to position: SCNVector3) {
        let jump = SCNAction.sequence([
            .moveBy(x: 0, y: 0.3, z: 0, duration: 0.1),
            .move(to: position, duration: 0.25)
        ])
        jump.timingMode = .easeInEaseOut
        node.runAction(jump)
    }

    static func shake(cameraNode: SCNNode) {
        let left = SCNAction.moveBy(x: -0.1, y: 0, z: 0, duration: 0.05)
        let right = SCNAction.moveBy(x: 0.2, y: 0, z: 0, duration: 0.05)
        let center = SCNAction.moveBy(x: -0.1, y: 0, z: 0, duration: 0.05)
        cameraNode.runAction(.sequence([left, right, left, right, center]))
    }

    static func explode(node: SCNNode) {
        let burst = SCNParticleSystem()
        burst.birthRate = 240
        burst.particleLifeSpan = 0.5
        burst.particleLifeSpanVariation = 0.2
        burst.particleSize = 0.05
        burst.spreadingAngle = 180
        burst.emittingDirection = SCNVector3(0, 1, 0)
        burst.particleVelocity = 1.2
        burst.particleVelocityVariation = 1.0
        burst.particleColor = UIColor.systemTeal

        node.addParticleSystem(burst)

        let vanish = SCNAction.group([
            .fadeOut(duration: 0.2),
            .scale(to: 0.01, duration: 0.2)
        ])
        node.runAction(vanish)
    }

    static func addConfetti(to node: SCNNode) {
        let confetti = SCNParticleSystem()
        confetti.birthRate = 180
        confetti.particleLifeSpan = 2.4
        confetti.particleLifeSpanVariation = 1.0
        confetti.particleSize = 0.02
        confetti.particleSizeVariation = 0.03
        confetti.particleVelocity = 1.4
        confetti.particleVelocityVariation = 0.8
        confetti.emitterShape = SCNPlane(width: 8, height: 1)
        confetti.particleColor = UIColor.systemPink
        confetti.particleColorVariation = SCNVector4(0.5, 0.7, 0.7, 0)
        confetti.acceleration = SCNVector3(0, -1.8, 0)
        confetti.loops = false
        confetti.emissionDuration = 1.0

        node.addParticleSystem(confetti)
    }

    static func cameraIntroZoom(cameraNode: SCNNode) {
        cameraNode.position = SCNVector3(0, 0.2, 11)
        let zoom = SCNAction.move(to: SCNVector3(0, 0, 8.5), duration: 0.75)
        zoom.timingMode = .easeOut
        cameraNode.runAction(zoom)
    }
}
