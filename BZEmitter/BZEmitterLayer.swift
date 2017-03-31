//
//  BZEmitterLayer.swift
//  BZEmitter
//
//  Created by 蔡士林 on 31/03/2017.
//  Copyright © 2017 SSBun. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

struct BZParticle {
    var color: UIColor
    var point: CGPoint
    var  customColor: UIColor? {
        set {
            if let value = newValue {
                color = value
            }
        }
        get {
            return color
        }
    }
    var randomPointRange: CGFloat? {
        set {
            let value = newValue ?? 0
            if value != 0 {
                point.x = point.x - value + CGFloat(arc4random_uniform(UInt32(value) * 2))
                point.y = point.y - value + CGFloat(arc4random_uniform(UInt32(value) * 2))
            }
        }
        get {
            return 0
        }
    }
    let delayTime: UInt32     = arc4random_uniform(30)
    let delayDuration: UInt32 = arc4random_uniform(10)
}


protocol BZEmitterLayerDelegate {
    func emitterLayerEndAnimation()
}

class BZEmitterLayer: CALayer {
    
    public var beginPoint: CGPoint       = .zero// 粒子发射起点
    public var ignoredBlack: Bool        = false// 忽略黑色粒子
    public var ignoredWhite: Bool        = false// 忽略白色粒子
    public var customColor: UIColor?      // 覆盖原粒子颜色，最后会是一个图片的纯色图片
    public var randomPointRange: CGFloat = 0// 不能等于0
    
    public var maxParticleCount: UInt32 = 0 // 每行最大的粒子数量
    public var image: UIImage? {            // 待渲染的图片
        didSet {
            if let image = image {
                particleArray = self.getRGBAs(from: image)
            }
        }
    }
    public var emitterDelegate: BZEmitterLayerDelegate?
    
    private var animationTime: CGFloat     = 0
    private var animationDuration: CGFloat = 2
    private var displayLink:CADisplayLink?
    private var particleArray:[BZParticle] = []
    
    
    override init() {
        super.init()
        self.masksToBounds = false
        displayLink = CADisplayLink(target: self, selector: #selector(BZEmitterLayer.emitterAnimation))
        displayLink?.add(to: .current, forMode: .commonModes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func emitterAnimation() {
        self.setNeedsDisplay()
        animationTime += 0.6
    }
    
    override func draw(in ctx: CGContext) {
        var count = 0
        for particle in particleArray {
            if CGFloat(particle.delayTime) > animationTime {
                continue
            }
            var curTime = animationTime - CGFloat(particle.delayTime)
            if curTime > animationDuration + CGFloat(particle.delayDuration) {
                curTime = animationDuration + CGFloat(particle.delayDuration)
                count += 1
            }
            let curX = self.easeInOutQuad(curTime, beginPoint.x, particle.point.x + self.bounds.size.width/2 - CGFloat(image!.cgImage!.width/2), animationDuration + CGFloat(particle.delayDuration))
            let curY = self.easeInOutQuad(curTime, beginPoint.y, particle.point.y + self.bounds.size.height/2 - CGFloat(image!.cgImage!.height/2), animationDuration + CGFloat(particle.delayDuration))
            
            ctx.addRect(CGRect(x:curX, y:curY, width:1, height:1))
            let components = particle.color.cgColor.components!
            ctx.setFillColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
            ctx.fillPath()
        }
        if (count == particleArray.count) {
            self.reset()
            self.emitterDelegate?.emitterLayerEndAnimation()
        }
    }
    
    func easeInOutQuad(_ time: CGFloat, _ begin: CGFloat, _ end: CGFloat, _ duration: CGFloat) -> CGFloat {
        let coverDistance = end - begin
        var newTime = time / (duration/2)
        if newTime < 1 {
            return coverDistance/2.0 * pow(newTime, 2) + begin
        }
        newTime -= 1
        return -coverDistance/2.0 * (newTime * (newTime - 2) - 1) + begin
    }
    
    
    func getRGBAs(from image: UIImage) -> [BZParticle] {
        let imageRef = image.cgImage!
        let imageW = imageRef.width
        let imageH = imageRef.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4 // 一个像素4个字节
        let bytesPerRow = bytesPerPixel * imageW
        let rawData: UnsafeMutableRawPointer = calloc(imageH*imageW*bytesPerPixel, MemoryLayout.size(ofValue: CChar()))
        let bitsPerComponent = 8
        let context = CGContext(data: rawData, width: imageW, height: imageH, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: imageW, height: imageH))
        
        
        let addY = maxParticleCount == 0 ? 1 : imageH / Int(maxParticleCount)
        let addX = maxParticleCount == 0 ? 1 : imageW / Int(maxParticleCount)
        var result = [BZParticle]()
        let bufferData = UnsafeRawBufferPointer(start: rawData, count: imageH*imageW*bytesPerPixel)
        
        for y in stride(from: 0, to: imageH, by: addY) {
            for x in stride(from: 0, to: imageW, by: addX) {
                let byteIndex = bytesPerRow*y + bytesPerPixel*x
                let red   = CGFloat(bufferData[byteIndex]) / 255.0
                let green = CGFloat(bufferData[byteIndex + 1]) / 255.0
                let blue  = CGFloat(bufferData[byteIndex + 2]) / 255.0
                let alpha = CGFloat(bufferData[byteIndex + 3]) / 255.0
                
                if alpha == 0 || (ignoredWhite && (red+green+blue == 3)) || (ignoredBlack && (red+green+blue == 0)) {
                    continue
                }
                let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
                let point = CGPoint(x: x, y: y)
                var particle = BZParticle(color: color, point: point)
                if let custom = customColor {
                    particle.customColor = custom
                }
                if randomPointRange > 0 {
                    particle.randomPointRange = randomPointRange
                }
                result.append(particle)
            }
        }
        free(rawData)
        return result
    }
    
    func pause() {
        displayLink?.isPaused = true
    }
    
    func resume() {
        displayLink?.isPaused = false
    }
    
    func reset() {
        displayLink?.invalidate()
        displayLink = nil
        animationTime = 0
    }
    
    func restart() {
        self.reset()
        displayLink = CADisplayLink(target: self, selector: #selector(BZEmitterLayer.emitterAnimation))
        displayLink?.add(to: .current, forMode: .commonModes)
    }
}
