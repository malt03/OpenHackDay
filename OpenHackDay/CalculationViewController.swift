//
//  CalculationViewController.swift
//  OpenHackDay
//
//  Created by Koji Murata on 2015/03/08.
//  Copyright (c) 2015年 Koji Murata. All rights reserved.
//

import UIKit

class CalculationViewController: UIViewController {
    var rootViewController: ViewController!
    private var isCalculating = true
    @IBOutlet weak var over: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var kamuImages = [UIImage]()
        for i in 0...8 {
            kamuImages += [UIImage(named: "kamu" + String(i <= 4 ? 4-i : i-4))!]
        }
        animationImageView.animationImages = kamuImages
        animationImageView.animationDuration = Double(kamuImages.count) / 30
        animationImageView.animationRepeatCount = 1

        slider.setThumbImage(UIImage(named: "slider")!, forState: .Normal)
        slider.setMinimumTrackImage(UIImage(named: "barMin")!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 5, 0, 0)), forState: .Normal)
        slider.setMaximumTrackImage(UIImage(named: "barMax")!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 0, 0, 5)), forState: .Normal)
    }
    
    private var previousTouchPosX: CGFloat?
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if let ts = event.allTouches() {
            if ts.count >= 2 && !isCalculating {
                let touch = ts.allObjects[0] as UITouch
                let point = touch.locationInView(view)
                if let x = previousTouchPosX {
                    if x < point.x {
                        self.rootViewController.back()
                    }
                }
                previousTouchPosX = point.x
            }
        }
    }
    
    func setMessage(message: String) {
        messageLabel.text = message
    }
    
    func startCalculate() {
        slider.minimumValue = 0
        slider.value = 0
        countdownLabel.hidden = false
        over.hidden = false
        isCalculating = true
        countDown(5)
    }
    
    private func countDown(count: Int) {
        countdownLabel.text = String(count)
        if count == 0 {
            finishCalculate()
        } else {
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
            dispatch_after(delay, dispatch_get_main_queue()) {
                self.countDown(count-1)
            }
        }
    }
    
    func setValue(val: Int32) {
        if isCalculating {
            if val > 0 && slider.value < Float(val+1) {
                slider.minimumValue = Float(val - 50)
                slider.maximumValue = Float(val + 50)
                slider.value = Float(val+1)
                rootViewController.threshold = val+1
                thresholdLabel.text = String(val+1)
            }
        } else {
            if rootViewController.threshold <= val {
                if animationImageView.isAnimating() {
                    animationImageView.stopAnimating()
                }
                animationImageView.startAnimating()
            }
        }
    }
    
    private func finishCalculate() {
        over.hidden = true
        countdownLabel.hidden = true
        isCalculating = false
    }
    
    @IBAction func changeValue(sender: UISlider) {
        sender.value = Float(Int(sender.value))
        rootViewController.threshold = Int32(sender.value)
        thresholdLabel.text = String(rootViewController.threshold)
    }
    
    @IBAction func back() {
        rootViewController.back()
    }
}