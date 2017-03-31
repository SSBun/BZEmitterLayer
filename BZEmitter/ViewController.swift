//
//  ViewController.swift
//  BZEmitter
//
//  Created by 蔡士林 on 31/03/2017.
//  Copyright © 2017 SSBun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showQQ()
        
    }
    
    func showQQ() {
        let image = UIImage(named: "qq")
        
        let emitterLayer = BZEmitterLayer()
        emitterLayer.bounds = self.view.bounds
        emitterLayer.position = self.view.center
        emitterLayer.beginPoint = CGPoint(x: self.view.center.x, y: 0)
//        emitterLayer.beginPoint = self.view.center
        emitterLayer.maxParticleCount = 500
        emitterLayer.ignoredWhite = true
        emitterLayer.image = image
        self.view.layer.addSublayer(emitterLayer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

