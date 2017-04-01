//
//  ASPVideoPlayer.swift
//  ASPVideoPlayer
//
//  Created by Andrei-Sergiu Pițiș on 09/12/2016.
//  Copyright © 2016 Andrei-Sergiu Pițiș. All rights reserved.
//

import UIKit

/**
A video player implementation with basic functionality.
*/
@IBDesignable open class ASPVideoPlayer: UIView {
	
	//MARK: - Private Variables and Constants -
	
	fileprivate var videoPlayerView: ASPVideoPlayerView!
	
	//MARK: - Public Variables -
	
	/**
	Sets the controls to use for the player. By default the controls are ASPVideoPlayerControls.
	*/
	open var videoPlayerControls: ASPBasicControls! {
		didSet {
			videoPlayerControls.videoPlayer = videoPlayerView
			updateControls()
		}
	}
	
	/**
	The duration of the fade animation.
	*/
	open var fadeDuration = 0.3
	
	/**
	An array of URLs that the player will load. Can be local or remote URLs.
	*/
	open var videoURLs: [URL] = [] {
		didSet {
			videoPlayerView.videoURL = videoURLs.first
		}
	}
	
	/**
	The gravity of the video. Adjusts how the video fills the space of the container.
	*/
	open var gravity: ASPVideoPlayerView.PlayerContentMode {
		set {
			videoPlayerView.gravity = newValue
		}
		get {
			return videoPlayerView.gravity
		}
	}
	
	/**
	Sets wether the playlist should loop. Once the last video has finished playing, the first one will start.
	*/
	open var shouldLoop: Bool {
		set {
			videoPlayerView.shouldLoop = newValue
		}
		get {
			return videoPlayerView.shouldLoop
		}
	}
	
	/**
	Sets the color of the controls.
	*/
	override open var tintColor: UIColor! {
		didSet {
			videoPlayerControls.tintColor = tintColor
		}
	}
	
	//MARK: - Superclass methods -
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		commonInit()
	}
	
	//MARK: - Private methods -
	
	@objc internal func toggleControls() {
		if videoPlayerControls.alpha == 1.0 && videoPlayerView.status == .playing {
			hideControls()
		} else {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ASPVideoPlayer.hideControls), object: nil)
			showControls()
			
			if videoPlayerView.status == .playing {
				perform(#selector(ASPVideoPlayer.hideControls), with: nil, afterDelay: 3.0)
			}
		}
	}
	
	internal func showControls() {
		UIView.animate(withDuration: fadeDuration, animations: {
			self.videoPlayerControls.alpha = 1.0
		})
	}
	
	@objc internal func hideControls() {
		UIView.animate(withDuration: fadeDuration, animations: {
			self.videoPlayerControls.alpha = 0.0
		})
	}
	
	private func updateControls() {
		videoPlayerControls.tintColor = tintColor
		
		videoPlayerControls.newVideo = { [weak self] in
			if let videoURL = self?.videoPlayerView.videoURL {
				if let currentURLIndex = self?.videoURLs.index(of: videoURL) {
					self?.videoPlayerControls.nextButtonHidden = currentURLIndex == (self?.videoURLs.count ?? 0) - 1
					self?.videoPlayerControls.previousButtonHidden = currentURLIndex == 0
				}
			}
		}
		
		videoPlayerControls.finishedVideo = { [weak self] in
			if let videoURL = self?.videoPlayerView.videoURL {
				if videoURL == self?.videoURLs.last {
					if self?.videoPlayerView.shouldLoop == true {
						self?.videoPlayerView.videoURL = self?.videoURLs.first
					}
				} else {
					let currentURLIndex = self?.videoURLs.index(of: videoURL)
					let nextURL = self?.videoURLs[currentURLIndex! + 1]
					
					self?.videoPlayerView.videoURL = nextURL
				}
			}
		}
		
		videoPlayerControls.didPressNextButton = { [weak self] in
			if let videoURL = self?.videoPlayerView.videoURL {
				if let currentURLIndex = self?.videoURLs.index(of: videoURL), currentURLIndex + 1 < (self?.videoURLs.count ?? 0) {
					let nextURL = self?.videoURLs[currentURLIndex + 1]
					
					self?.videoPlayerView.videoURL = nextURL
				}
			}
		}
		
		videoPlayerControls.didPressPreviousButton = { [weak self] in
			if let videoURL = self?.videoPlayerView.videoURL {
				if let currentURLIndex = self?.videoURLs.index(of: videoURL), currentURLIndex > 0 {
					let nextURL = self?.videoURLs[currentURLIndex - 1]
					
					self?.videoPlayerView.videoURL = nextURL
				}
			}
		}
		
		videoPlayerControls.interacting = { [unowned self] (isInteracting) in
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ASPVideoPlayer.hideControls), object: nil)
			if isInteracting == true {
				self.showControls()
			} else {
				if self.videoPlayerView.status == .playing {
					self.perform(#selector(ASPVideoPlayer.hideControls), with: nil, afterDelay: 3.0)
				}
			}
		}
	}
	
	private func commonInit() {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ASPVideoPlayer.toggleControls))
		tapGestureRecognizer.delegate = self
		addGestureRecognizer(tapGestureRecognizer)
		
		videoPlayerView = ASPVideoPlayerView()
		videoPlayerControls = ASPVideoPlayerControls(videoPlayer: videoPlayerView)
		
		videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
		videoPlayerControls.translatesAutoresizingMaskIntoConstraints = false
		
		videoPlayerControls.backgroundColor = UIColor.black.withAlphaComponent(0.15)
		
		updateControls()
		
		addSubview(videoPlayerView)
		addSubview(videoPlayerControls)
		
		setupLayout()
	}
	
	private func setupLayout() {
		let viewsDictionary: [String: Any] = ["videoPlayerView":videoPlayerView,
		                                      "videoPlayerControls":videoPlayerControls]
		
		var constraintsArray = [NSLayoutConstraint]()
		
		constraintsArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[videoPlayerView]|", options: [], metrics: nil, views: viewsDictionary))
		constraintsArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[videoPlayerView]|", options: [], metrics: nil, views: viewsDictionary))
		constraintsArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[videoPlayerControls]|", options: [], metrics: nil, views: viewsDictionary))
		constraintsArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[videoPlayerControls]|", options: [], metrics: nil, views: viewsDictionary))
		
		addConstraints(constraintsArray)
	}
}

extension ASPVideoPlayer: UIGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if let view = touch.view, view.isDescendant(of: self) == true, view != videoPlayerView, view != videoPlayerControls || touch.location(in: videoPlayerControls).y > videoPlayerControls.bounds.size.height - 50 {
			return false
		} else {
			return true
		}
	}
}
