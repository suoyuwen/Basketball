//
//  ViewController.swift
//  World Tracking
//
//  Created by Yuwen Suo on 10/5/19.
//  Copyright © 2019 Yuwen Suo. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    //define the power force to the ball
    var power: Float = 1
    //trigger a code at every 0.05 seconds
    let timer = Each(0.05).seconds
    var basketAdded: Bool {
        return self.sceneView.scene.rootNode.childNode(withName: "Basket", recursively: false) != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        // make a tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    //touch the screen and shoot the ball into your net
    //the longer you touch the sceen the furher your ball goes
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //first check is there is a basket ball court or not
        //every 0.05s, add the powe 1
        if self.basketAdded == true {
            timer.perform(closure: { () -> NextStep in
                self.power = self.power + 1
                return .continue
            })
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            self.timer.stop()
            self.shootBall()
        }
        self.power = 1
    }
    
    func shootBall() {
        //throw the ball int the camara view of  the device
            guard let pointOfView = self.sceneView.pointOfView else {return}
            //self .power = 10
            self.removeEveryOtherBall()
            let transform = pointOfView.transform
            //get x,y,z
            let location = SCNVector3(transform.m41, transform.m42, transform.m43)
            // reversed
            let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
            let position = location + orientation
            let ball = SCNNode(geometry: SCNSphere(radius: 0.3))
            //apply texture to the ball
            let image = #imageLiteral(resourceName: "ball")
            ball.geometry?.firstMaterial?.diffuse.contents = image
            ball.position = position
            // make to ball to be a pysical body
            let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
                   ball.physicsBody = body
                   ball.name = "Basketball"
                   //apply force to ball
                   ball.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
                   self.sceneView.scene.rootNode.addChildNode(ball)
    }
    
    //if touched a horizontal surface then we are going to add our basketball cout right there
    @objc func handleTap(sender: UITapGestureRecognizer) {
         guard let sceneView = sender.view as? ARSCNView else {return}
         let touchLocation = sender.location(in: sceneView)
         let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
         if !hitTestResult.isEmpty {
             self.addBasket(hitTestResult: hitTestResult.first!)
         }
     }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        //load the basket scene and put the basket ball back booard on the horizontal surface
        let basketScene = SCNScene(named: "Basketball.scnassets/basketball.scn")
        let basketNode = basketScene?.rootNode.childNode(withName: "Basket", recursively: false)
        let positionOfPlane = hitTestResult.worldTransform.columns.3
        let xPosition = positionOfPlane.x
        let yPosition = positionOfPlane.y
        let zPosition = positionOfPlane.z
        basketNode?.position = SCNVector3(xPosition,yPosition,zPosition)
        // make the basket cour a pysical body
        //will collide with other bodies but not effect by gravity so will stay there
        //not collide with the hole in the court
        basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        self.sceneView.scene.rootNode.addChildNode(basketNode!)
    }
        
    override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
           // Dispose of any resources that can be recreated.
       }
    
    // Make the "Plane detected" lable last for 3 seconds and then hidden again
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetected.isHidden = true
        }
    }
    
    deinit {
        self.timer.stop()
    }
    
    func removeEveryOtherBall() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "Basketball" {
            node.removeFromParentNode()
            }
        }
    }

}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
