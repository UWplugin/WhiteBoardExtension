//
//  textNode.swift
//  EditWorld
//
//  Created by Student User on 5/21/18.
//  Copyright © 2018 EditWorld. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class TextNode: SCNNode {
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(distance:Float, scntext:SCNText, sceneView:ARSCNView, scale:CGFloat){
        super.init()
        
        
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * distance * mat.m31, -1 * distance * mat.m32, -1 * distance * mat.m33)
        let currentPosition = pointOfView.position + dir
        
        
        self.geometry = scntext
        self.position = currentPosition
        self.simdRotation = pointOfView.simdRotation
        self.setPivot()
        self.scale = SCNVector3(scale, scale, scale)
        
    }
    
    
}
