//
//  PlayerVideoViewController.swift
//  PlayerVideo
//
//  Created by David Alejandro on 2/17/16.
//  Copyright © 2016 David Alejandro. All rights reserved.
//

import AVFoundation.AVPlayer
import UIKit

private extension Selector {
    static let playerItemDidPlayToEndTime = #selector(PlayerView.playerItemDidPlayToEndTime(aNotification:))
}

public typealias PVStatus = AVPlayer.Status
public typealias PVItemStatus = AVPlayerItem.Status
public typealias PVTimeRange = CMTimeRange
public typealias PVPlayer = AVQueuePlayer
public typealias PVPlayerItem = AVPlayerItem

public protocol PlayerViewDelegate: class {
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: Error?)
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?)
    func playerVideo(player: PlayerView, loadedTimeRanges: [PVTimeRange])
    func playerVideo(player: PlayerView, duration: Double)
    func playerVideo(player: PlayerView, currentTime: Double)
    func playerVideo(player: PlayerView, rate: Float)
    func playerVideo(playerFinished player: PlayerView)
}

public extension PlayerViewDelegate {
    func playerVideo(_: PlayerView, statusPlayer _: PVStatus, error _: Error?) {}
    
    func playerVideo(_: PlayerView, statusItemPlayer _: PVStatus, error _: Error?) {}
    
    func playerVideo(_: PlayerView, loadedTimeRanges _: [PVTimeRange]) {}
    
    func playerVideo(_: PlayerView, duration _: Double) {}
    
    func playerVideo(_: PlayerView, currentTime _: Double) {}
    
    func playerVideo(_: PlayerView, rate _: Float) {}
    
    func playerVideo(playerFinished _: PlayerView) {}
}

public enum PlayerViewFillMode {
    case resizeAspect
    case resizeAspectFill
    case resize
    
    init?(videoGravity: AVLayerVideoGravity) {
        switch videoGravity {
        case .resizeAspect:
            self = .resizeAspect
        case .resizeAspectFill:
            self = .resizeAspectFill
        case .resize:
            self = .resize
        default:
            return nil
        }
    }
    
    var AVLayerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .resizeAspect:
            return .resizeAspect
        case .resizeAspectFill:
            return .resizeAspectFill
        case .resize:
            return .resize
        }
    }
}

open class PlayerView: UIView {
    public var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    open override class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    fileprivate var timeObserverToken: AnyObject?
    fileprivate weak var lastPlayerTimeObserve: PVPlayer?
    
    fileprivate var urlsQueue: Array<URL>?
    
    // MARK: - Public Variables
    
    open weak var delegate: PlayerViewDelegate?
    
    open var loopVideosQueue = false
    
    open var player: PVPlayer? {
        get {
            return playerLayer.player as? PVPlayer
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    open var fillMode: PlayerViewFillMode! {
        didSet {
            playerLayer.videoGravity = fillMode.AVLayerVideoGravity
        }
    }
    
    open var currentTime: Double {
        get {
            guard let player = player else {
                return 0
            }
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            guard let timescale = player?.currentItem?.duration.timescale else {
                return
            }
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: timescale)
            player!.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    open var interval = CMTimeMake(value: 1, timescale: 60) {
        didSet {
            if rate != 0 {
                addCurrentTimeObserver()
            }
        }
    }
    
    open var rate: Float {
        get {
            guard let player = player else {
                return 0
            }
            return player.rate
        }
        set {
            if newValue == 0 {
                removeCurrentTimeObserver()
            } else if rate == 0, newValue != 0 {
                addCurrentTimeObserver()
            }
            
            player?.rate = newValue
        }
    }
    
    // MARK: private Functions
    
    /**
     Add all observers for a PVPlayer
     */
    public  func addObserversPlayer(_ avPlayer: PVPlayer) {
        avPlayer.addObserver(self, forKeyPath: "status", options: [.new], context: &statusContext)
        avPlayer.addObserver(self, forKeyPath: "rate", options: [.new], context: &rateContext)
        avPlayer.addObserver(self, forKeyPath: "currentItem", options: [.old, .new], context: &playerItemContext)
    }
    
    /**
     Remove all observers for a PVPlayer
     */
    public  func removeObserversPlayer(_ avPlayer: PVPlayer) {
        avPlayer.removeObserver(self, forKeyPath: "status", context: &statusContext)
        avPlayer.removeObserver(self, forKeyPath: "rate", context: &rateContext)
        avPlayer.removeObserver(self, forKeyPath: "currentItem", context: &playerItemContext)
        
        if let timeObserverToken = timeObserverToken {
            avPlayer.removeTimeObserver(timeObserverToken)
        }
    }
    
    public func addObserversVideoItem(_ playerItem: PVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: [], context: &loadedContext)
        playerItem.addObserver(self, forKeyPath: "duration", options: [], context: &durationContext)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: &statusItemContext)
        NotificationCenter.default.addObserver(self, selector: .playerItemDidPlayToEndTime, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    public func removeObserversVideoItem(playerItem: PVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: &loadedContext)
        playerItem.removeObserver(self, forKeyPath: "duration", context: &durationContext)
        playerItem.removeObserver(self, forKeyPath: "status", context: &statusItemContext)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    public func removeCurrentTimeObserver() {
        if let timeObserverToken = self.timeObserverToken {
            lastPlayerTimeObserve?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }
    
    public func addCurrentTimeObserver() {
        removeCurrentTimeObserver()
        
        lastPlayerTimeObserve = player
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ -> () in
            if let mySelf = self {
                self?.delegate?.playerVideo(player: mySelf, currentTime: mySelf.currentTime)
            }
            } as AnyObject?
    }
    
    @objc func playerItemDidPlayToEndTime(aNotification: NSNotification) {
        // notification of player to stop
        let item = aNotification.object as! PVPlayerItem
        if loopVideosQueue, player?.items().count == 1,
            let urlsQueue = urlsQueue {
            addVideosOnQueue(urlsQueue, afterItem: item)
        }
        delegate?.playerVideo(playerFinished: self)
    }
    
    // MARK: public Functions
    
    public func play() {
        rate = 1
    }
    
    public func pause() {
        rate = 0
    }
    
    public func stop() {
        currentTime = 0
        pause()
    }
    
    public func next() {
        player?.advanceToNextItem()
    }
    
    public func resetPlayer() {
        urlsQueue = nil
        guard let player = player else {
            return
        }
        player.pause()
        
        removeObserversPlayer(player)
        if let playerItem = player.currentItem {
            removeObserversVideoItem(playerItem: playerItem)
        }
        self.player = nil
    }
    
    public func availableDuration() -> PVTimeRange {
        let range = player?.currentItem?.loadedTimeRanges.first
        if let range = range {
            return range.timeRangeValue
        }
        return PVTimeRange.zero
    }
    
    public func screenshot() throws -> UIImage? {
        guard let time = player?.currentItem?.currentTime() else {
            return nil
        }
        
        return try screenshotCMTime(cmTime: time)?.0
    }
    
    public func screenshotTime(time: Double? = nil) throws -> (UIImage, photoTime: CMTime)? {
        guard let timescale = player?.currentItem?.duration.timescale else {
            return nil
        }
        
        let timeToPicture: CMTime
        if let time = time {
            timeToPicture = CMTimeMakeWithSeconds(time, preferredTimescale: timescale)
        } else if let time = player?.currentItem?.currentTime() {
            timeToPicture = time
        } else {
            return nil
        }
        return try screenshotCMTime(cmTime: timeToPicture)
    }
    
    private func screenshotCMTime(cmTime: CMTime) throws -> (UIImage, photoTime: CMTime)? {
        guard let player = player, let asset = player.currentItem?.asset else {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        var timePicture = CMTime.zero
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        
        let ref = try imageGenerator.copyCGImage(at: cmTime, actualTime: &timePicture)
        let viewImage: UIImage = UIImage(cgImage: ref)
        return (viewImage, timePicture)
    }
    
    public var url: URL? {
        didSet {
            guard let url = url else {
                urls = nil
                return
            }
            urls = [url]
        }
    }
    
    public var urls: [URL]? {
        willSet(newUrls) {
            resetPlayer()
            guard let urls = newUrls else {
                return
            }
            // reset before put another URL
            
            urlsQueue = urls
            let playerItems = urls.map { (url) -> PVPlayerItem in
                return PVPlayerItem(url: url)
            }
            
            let avPlayer = PVPlayer(items: playerItems)
            player = avPlayer
            
            avPlayer.actionAtItemEnd = .pause
            
            let playerItem = avPlayer.currentItem!
            
            addObserversPlayer(avPlayer)
            addObserversVideoItem(playerItem)
            
            // Do any additional setup after loading the view, typically from a nib.
        }
    }
    
    public func addVideosOnQueue(_ urls: [URL], afterItem: PVPlayerItem? = nil) {
        // on last item on player
        let item = afterItem ?? player?.items().last
        urlsQueue?.append(contentsOf: urls)

        urls.forEach({ url in
            let itemNew = PVPlayerItem(url: url)
            player?.insert(itemNew, after: item)
        })
    }
    
    public convenience init() {
        self.init(frame: CGRect.zero)
        
        fillMode = .resizeAspect
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        fillMode = .resizeAspect
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        fillMode = .resizeAspect
    }
    
    deinit {
        delegate = nil
        resetPlayer()
    }
    
    // MARK: private variables for context KVO
    
    fileprivate var statusContext = true
    fileprivate var statusItemContext = true
    fileprivate var loadedContext = true
    fileprivate var durationContext = true
    fileprivate var currentTimeContext = true
    fileprivate var rateContext = true
    fileprivate var playerItemContext = true
    
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {
        
        if context == &statusContext {
            guard let avPlayer = player else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            delegate?.playerVideo(self, statusPlayer: avPlayer.status, error: avPlayer.error)
            
        } else if context == &loadedContext {
            let playerItem = player?.currentItem
            
            guard let times = playerItem?.loadedTimeRanges else {
                return
            }
            
            let values = times.map({ $0.timeRangeValue })
            delegate?.playerVideo(player: self, loadedTimeRanges: values)
            
        } else if context == &durationContext {
            if let currentItem = player?.currentItem {
                delegate?.playerVideo(player: self, duration: currentItem.duration.seconds)
            }
            
        } else if context == &statusItemContext {
            // status of item has changed
            if let currentItem = player?.currentItem {
                delegate?.playerVideo(player: self, statusItemPlayer: currentItem.status, error: currentItem.error)
            }
            
        } else if context == &rateContext {
            guard let newRateNumber = (change?[NSKeyValueChangeKey.newKey] as? NSNumber) else {
                return
            }
            let newRate = newRateNumber.floatValue
            if newRate == 0 {
                removeCurrentTimeObserver()
            } else {
                addCurrentTimeObserver()
            }
            
            delegate?.playerVideo(player: self, rate: newRate)
            
        } else if context == &playerItemContext {
            guard let oldItem = (change?[NSKeyValueChangeKey.oldKey] as? PVPlayerItem) else {
                return
            }
            removeObserversVideoItem(playerItem: oldItem)
            guard let newItem = (change?[NSKeyValueChangeKey.newKey] as? PVPlayerItem) else {
                return
            }
            addObserversVideoItem(newItem)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
