//
//  ViewController.swift
//  PlayerVideo
//
//  Created by David Alejandro on 2/17/16.
//  Copyright © 2016 David Alejandro. All rights reserved.
//

import UIKit
import PlayerView
import AVFoundation


private extension Selector {
    static let changeFill = #selector(ViewController.changeFill(sender:))
}


class ViewController: UIViewController {
    
    @IBOutlet var slider: UISlider!
    
    @IBOutlet var progressBar: UIProgressView!
    
    @IBOutlet var playerVideo: PlayerView!
    
    @IBOutlet var rateLabel: UILabel!
    
    @IBOutlet var playButton: UIButton!
    
    
    var duration: Float!
    var isEditingSlider = false
    let tap = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerVideo.delegate = self
        let url1 = NSURL(string: "http://techslides.com/demos/sample-videos/small.mp4")!
//        let url = NSURL(string: "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_30mb.mp4")!

        playerVideo.urls = [url1,url1] as [URL]
        playerVideo.loopVideosQueue = true
        playerVideo.play()

        tap.numberOfTapsRequired = 2
        tap.addTarget(self, action: .changeFill)
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func sliderChange(_ sender: UISlider) {
        playerVideo.currentTime = Double(sender.value)
    }
    
    @IBAction func sliderBegin(_ sender: UISlider) {
        print("beginEdit")
        isEditingSlider = true
    }
    
    @IBAction func sliderEnd(_ sender: Any) {
        print("endEdit")
        isEditingSlider = false
    }
    
    
    
    @IBAction func backwardTouch(_ sender: Any) {
        playerVideo.rate = playerVideo.rate - 0.5
    }
    
    @IBAction func playTouch(_ sender: Any) {
        if playerVideo.rate == 0 {
            playerVideo.play()
        } else {
            playerVideo.pause()
        }
    }
    
    @IBAction func fowardTouch(_ sender: Any) {
        playerVideo.rate = playerVideo.rate + 0.5
    }
    
   @objc func changeFill(sender: AnyObject) {
        switch playerVideo.fillMode {
        case .some(.resizeAspect):
                playerVideo.fillMode = .resizeAspectFill
        case .some(.resizeAspectFill):
            playerVideo.fillMode = .resize
        case .some(.resize):
            playerVideo.fillMode = .resizeAspect
        default:
            break
        }
    }
}


extension ViewController: PlayerViewDelegate {
    
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: Error?) {
        print(statusPlayer)
    }
    
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
        
    }
    func playerVideo(player: PlayerView, loadedTimeRanges: [PVTimeRange]) {
        
        let durationTotal = loadedTimeRanges.reduce(0) { (actual, range) -> Double in
            return actual + range.end.seconds
        }
        let dur2 = Float(durationTotal)
        let progress = dur2 / 1
        progressBar?.progress = progress
        
        if loadedTimeRanges.count > 1 {
            print(loadedTimeRanges.count)
        }
    }
    func playerVideo(player: PlayerView, duration: Double) {
        self.duration = Float(duration)
        slider?.maximumValue = Float(duration)
    }
    
    func playerVideo(player: PlayerView, currentTime: Double) {
        if !isEditingSlider {
            slider.value = Float(currentTime)
        }
    }
    
    func playerVideo(player: PlayerView, rate: Float) {
        rateLabel.text = "x\(rate)"
        
        
        let buttonImageName = rate == 0.0 ? "PlayButton" : "PauseButton"
        
        let buttonImage = UIImage(named: buttonImageName)
        
        playButton.setImage(buttonImage, for: .normal)
    }
    
    func playerVideo(playerFinished player: PlayerView) {
        player.next()
        player.play()
        print("video has finished")
    }
}
