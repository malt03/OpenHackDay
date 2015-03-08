//
//  ViewController.swift
//  OpenHackDay
//
//  Created by Koji Murata on 2015/03/07.
//  Copyright (c) 2015年 Koji Murata. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private let suuid = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    private let cuuid = CBUUID(string: "01501162-0F73-48A3-8B1C-E9857E43E3E6")
    private var p: CBPeripheral!
    private var c: CBCharacteristic!
    
    @IBOutlet weak var calculationView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playSlider: UISlider!
    @IBOutlet weak var playbackTimeLabel: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var angryAnimationImageView: UIImageView!
    @IBOutlet weak var angryParentView: UIView!
    @IBOutlet weak var iconAnimationImageView: UIImageView!
    private var openColorView: UIView!
    
    private var pauseImages = [UIImage]()
    private var playImages = [UIImage]()
    private var shuffleImages = [UIImage]()
    
    private var playing = true
    private var playbackTimeChanging = false
    private let tapDelay = 1.0
    private var tapTimer: NSTimer!
    private var tapCount = 0
    private var angryCount = 0
    
    private let fireWait = 0.5
    private var canTap = true
    var threshold = Int32(155)

    private let colors = [
        .lightGrayColor(),
        .redColor(),
        .greenColor(),
        .blueColor(),
        .cyanColor(),
        .yellowColor(),
        .magentaColor(),
        .orangeColor(),
        .purpleColor(),
        .brownColor(),
    ] as [UIColor]
    private var currentColorNum = 0
   
    let player = MPMusicPlayerController.iPodMusicPlayer()
    let query = MPMediaQuery.songsQuery()
    
    private var calculationViewShowing = false
    private var calculationViewController: CalculationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let ud = NSUserDefaults()
        if ud.objectForKey("threshold") != nil {
            threshold = Int32(ud.integerForKey("threshold"))
        }
        
        view.backgroundColor = colors[currentColorNum]
        
        openColorView = UIView(frame: CGRect(origin: view.center, size: CGSize.zeroSize))
        
        view.addSubview(openColorView!)
        view.sendSubviewToBack(openColorView!)
        
        playSlider.setThumbImage(UIImage(named: "slider")!, forState: .Normal)
        playSlider.setMinimumTrackImage(UIImage(named: "barMin")!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 5, 0, 0)), forState: .Normal)
        playSlider.setMaximumTrackImage(UIImage(named: "barMax")!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 0, 0, 5)), forState: .Normal)

        for i in 0...24 {
            pauseImages += [UIImage(named: "pause" + String(i))!]
            playImages += [UIImage(named: "play" + String(i))!]
            shuffleImages += [UIImage(named: "shuffle" + String(i))!]
        }
        iconAnimationImageView.animationDuration = 30.0 / 25.0
        iconAnimationImageView.animationRepeatCount = 1
        
        var angryImages = [UIImage]()
        for i in 0...5 {
            angryImages += [UIImage(named: "angry" + String(i))!]
        }
        angryAnimationImageView.animationImages = angryImages
        angryAnimationImageView.animationDuration = Double(angryImages.count) / 30
        angryAnimationImageView.animationRepeatCount = 0
        
        var kamuImages = [UIImage]()
        for i in 0...8 {
            kamuImages += [UIImage(named: "kamu" + String(i <= 4 ? 4-i : i-4))!]
        }
        animationImageView.animationImages = kamuImages
        animationImageView.animationDuration = Double(kamuImages.count) / 30
        animationImageView.animationRepeatCount = 1
        
        player.setQueueWithQuery(query)
        player.shuffleMode = MPMusicShuffleMode.Songs
        player.repeatMode = MPMusicRepeatMode.All
        player.play()
        titleLabel.text = player.nowPlayingItem.title

        checkCurrentTime()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        calculationViewController = segue.destinationViewController as CalculationViewController
        calculationViewController.rootViewController = self
    }
    
    private func checkCurrentTime() {
        if player.nowPlayingItem != nil && !calculationViewShowing {
            playSlider.maximumValue = Float(player.nowPlayingItem.playbackDuration)
            playSlider.value = Float(player.currentPlaybackTime)
            if !player.currentPlaybackTime.isNaN {
                let time = Int(player.currentPlaybackTime)
                playbackTimeLabel.text = NSString(format: "%02d:%02d", time/60, time%60)
            } else {
                playbackTimeLabel.text = "00:00"
            }
            titleLabel.text = player.nowPlayingItem.title
        }

        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue()) {
            if !self.playbackTimeChanging {
                self.checkCurrentTime()
            }
        }
    }

    @IBAction func changePlaybackTimeStart() {
        playbackTimeChanging = true
    }
    @IBAction func changePlaybackTimeFinish() {
        playbackTimeChanging = false
        checkCurrentTime()
    }
    
    @IBAction func changePlaybackTime(sender: UISlider) {
        player.currentPlaybackTime =  Double(sender.value)
    }
    
    func playOrStop() {
        tapCount = 0
        let delay = animationImageView.animationDuration - tapDelay
        if playing {
            player.pause()
            animationWithDelay(delay, iconAnimaion: pauseImages)
        } else {
            player.play()
            animationWithDelay(delay, iconAnimaion: playImages)
        }
        playing = !playing
    }

    func next() {
        tapCount = 0
        player.skipToNextItem()
        let delay = animationImageView.animationDuration - tapDelay
        animationWithDelay(delay, iconAnimaion: shuffleImages)
    }
    
    private func animationWithDelay(delay: Double, iconAnimaion: [UIImage]) {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue()) {
            self.animation(iconAnimaion)
        }
    }
    
    private func animation(iconAnimation: [UIImage]) {
        if !calculationViewShowing {
            currentColorNum++
            
            let duration = 0.2

            openColorView.backgroundColor = colors[currentColorNum % colors.count]
            openColorView.frame = CGRect(origin: view.center, size: .zeroSize)
            
            let anim = CABasicAnimation(keyPath: "cornerRadius")
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            anim.fromValue = 0
            anim.toValue = self.view.frame.height/2
            anim.duration = duration
            openColorView.layer.addAnimation(anim, forKey: "cornerRadius")
            
            UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.openColorView!.frame.size = CGSize(width: self.view.frame.height, height: self.view.frame.height)
                self.openColorView!.center = self.view.center
            }) { (_) in
                self.view.backgroundColor = self.colors[self.currentColorNum % self.colors.count]
                self.iconAnimationImageView.startAnimating()
            }
            
            iconAnimationImageView.animationImages = iconAnimation
            self.iconAnimationImageView.startAnimating()
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if !calculationViewShowing { tap() }
    }
    
    private var previousTouchPosX: CGFloat?
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if let ts = event.allTouches() {
            if ts.count >= 2 && !calculationViewShowing {
                let touch = ts.allObjects[0] as UITouch
                let point = touch.locationInView(view)
                if let x = previousTouchPosX {
                    if x > point.x {
                        calculationViewShowing = true
                        player.pause()
                        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {
                            self.calculationView.frame.origin.x = 0
                        }, completion: { (_) in
                            self.calculationViewController.startCalculate()
                        })
                    }
                }
                previousTouchPosX = point.x
            }
        }
    }
    
    func back() {
        calculationViewShowing = false
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {
            self.calculationView.frame.origin.x = self.view.frame.width
        }) { (_) in
            let ud = NSUserDefaults()
            ud.setInteger(Int(self.threshold), forKey: "threshold")
            self.player.play()
        }
    }

    private func tap() {
        if canTap && !calculationViewShowing {
            if angryCount++ == 0 {
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(8 * Double(NSEC_PER_SEC)))
                dispatch_after(delay, dispatch_get_main_queue()) {
                    self.angryCount = 0
                }
            }
            if angryCount == 7 {
                angryParentView.hidden = false
                angryAnimationImageView.startAnimating()
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
                dispatch_after(delay, dispatch_get_main_queue()) {
                    self.angryParentView.hidden = true
                    self.angryAnimationImageView.stopAnimating()
                }
            }
            
            canTap = false
            
            println("false")
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(fireWait * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_main_queue()) {
                println("true")
                self.canTap = true
            }
            
            if animationImageView.isAnimating() {
                animationImageView.stopAnimating()
            }
            animationImageView.startAnimating()
            switch ++tapCount {
            case 1:
                tapTimer = NSTimer.scheduledTimerWithTimeInterval(tapDelay, target: self, selector: Selector("playOrStop"), userInfo: nil, repeats: false)
            case 2:
                tapTimer.invalidate()
                tapTimer = NSTimer.scheduledTimerWithTimeInterval(tapDelay, target: self, selector: Selector("next"), userInfo: nil, repeats: false)
            default: break
            }
        }
    }
    
    //BLE
    func outputDebugMessage(message: String) {
        calculationViewController.setMessage(message)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch (central.state)
        {
        case .Unsupported:
            NSLog("State: Unsupported")
        case .Unauthorized:
            NSLog("State: Unauthorized")
        case .PoweredOff:
            NSLog("State: Powered Off")
        case .PoweredOn:
            NSLog("State: Powered On")
            outputDebugMessage("Powered On")
            centralManager.scanForPeripheralsWithServices([suuid], options: nil)
        case .Unknown:
            NSLog("State: Unknown")
        default: break
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        outputDebugMessage("Discovered Peripheral")
        println(peripheral)
        p = peripheral
        centralManager.stopScan()
        centralManager.connectPeripheral(p, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        outputDebugMessage("Connected Peripheral")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        println("success")
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        outputDebugMessage("Fail to Connect Peripheral")
        println("fatal")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if (error != nil) {
            outputDebugMessage("Fail to Discover Services")
            println("error: \(error)")
            return
        }
        
        if let services = peripheral.services as? [CBService] {
            for s in services {
                outputDebugMessage("Discover Services")
                println("yeah!")
                peripheral.discoverCharacteristics(nil, forService: s)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (error != nil) {
            println("error: \(error)")
            outputDebugMessage("Fail to Discover Characteristics")
            return
        }
        
        if let characteristics = service.characteristics as? [CBCharacteristic] {
            for characteristic in characteristics {
                outputDebugMessage("Discover Characteristics")
                c = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: c)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            println("Notify状態更新失敗...error: \(error)")
        }
        else {
            outputDebugMessage("Notify Update!")
            println("Notify状態更新成功！ isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            println("データ更新通知エラー: \(error)")
            outputDebugMessage("Fail to Update Value")
            return
        }
        
        var val = Int32(0)
        characteristic.value.getBytes(&val, length: sizeof(Int32))
        outputDebugMessage("Update Value:" + String(val))
        
        if calculationViewShowing {
            calculationViewController.setValue(val)
        } else {
            if val >= threshold {
                tap()
            }
        }
    }
}

