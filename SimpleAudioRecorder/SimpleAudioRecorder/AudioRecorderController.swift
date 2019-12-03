//
//  ViewController.swift
//  AudioRecorder
//
//  Created by Paul Solt on 10/1/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AudioRecorderController: UIViewController {
    
	// Playback
	var audioPlayer: AVAudioPlayer?
	
	// Recording
	
	
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
	
	private lazy var timeFormatter: DateComponentsFormatter = {
		let formatting = DateComponentsFormatter()
		formatting.unitsStyle = .positional // 00:00  mm:ss
		// NOTE: DateComponentFormatter is good for minutes/hours/seconds
		// DateComponentsFormatter not good for milliseconds, use DateFormatter instead)
		formatting.zeroFormattingBehavior = .pad
		formatting.allowedUnits = [.minute, .second]
		return formatting
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()


        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
		
		loadAudio()
	}
	
	private func loadAudio() {
		// piano.mp3
		
		// Will crash, good for finding bugs early during development, but
		// risky if you're shipping an app to the App Store (1 star reviews)
		let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
		
		// create the player
		audioPlayer = try! AVAudioPlayer(contentsOf: songURL) // RISKY: will crash if not there
	}
	
	@IBAction func playButtonPressed(_ sender: Any) {
		playPause()
	}

	// Playback
	// What functions do I need?

	var isPlaying: Bool {
		audioPlayer?.isPlaying ?? false
	}

	func play() {
		audioPlayer?.play()
	}

	func pause() {
		audioPlayer?.pause()
	}

	func playPause() {
		if isPlaying {
			pause()
		} else {
			play()
		}
	}

	/// TODO: Update the UI for the playback
	
    
    @IBAction func recordButtonPressed(_ sender: Any) {
    
    }
	
	
}

