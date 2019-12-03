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
	var audioRecorder: AVAudioRecorder?
	
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
		updateViews()
	}
	
	private func loadAudio() {
		// piano.mp3
		
		// Will crash, good for finding bugs early during development, but
		// risky if you're shipping an app to the App Store (1 star reviews)
		let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
		
		// create the player
		audioPlayer = try! AVAudioPlayer(contentsOf: songURL) // RISKY: will crash if not there
		audioPlayer?.delegate = self
	}
	
	@IBAction func playButtonPressed(_ sender: Any) {
		playPause()
	}

	// Playback
	// What functions do I need?

	var timer: Timer?
	
	var isPlaying: Bool {
		audioPlayer?.isPlaying ?? false
	}

	func play() {
		audioPlayer?.play()
		startTimer()
		updateViews()
	}

	private func startTimer() {
		cancelTimer()
		timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer(timer:)), userInfo: nil, repeats: true)
	}

	@objc private func updateTimer(timer: Timer) {
		updateViews()
	}

	func pause() {
		audioPlayer?.pause()
		cancelTimer()
		updateViews()
	}

	private func cancelTimer() {
		timer?.invalidate()
		timer = nil
	}

	func playPause() {
		if isPlaying {
			pause()
		} else {
			play()
		}
	}

	/// TODO: Update the UI for the playback
	private func updateViews() {
		let playButtonTitle = isPlaying ? "Pause" : "Play"
		playButton.setTitle(playButtonTitle, for: .normal)
		
		let elapsedTime = audioPlayer?.currentTime ?? 0
		timeLabel.text = timeFormatter.string(from: elapsedTime)
		
		timeSlider.minimumValue = 0
		timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
		timeSlider.value = Float(elapsedTime)
		
		let recordButtonTitle = isRecording ? "Stop Recording" : "Record"
		recordButton.setTitle(recordButtonTitle, for: .normal)
	}
    
	@IBAction func recordButtonPressed(_ sender: Any) {
		recordToggle()
	}

	// Record

	var recordURL: URL?
	
	var isRecording: Bool {
		return audioRecorder?.isRecording ?? false
	}

	func record() {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		// Filename (ISO8601 format for time)
		let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
		
		// 2019-12-03T13:42:27-05:00.caf
		let file = documentsDirectory.appendingPathComponent(name).appendingPathExtension("caf")

		print("record URL: \(file)")
		
		// 44.1 KHz is CD quality audio
		let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
		
		audioRecorder = try! AVAudioRecorder(url: file, format: format) // FIXME: error handling
		recordURL = file
		audioRecorder?.delegate = self
		audioRecorder?.record()
		updateViews()
	}

	func stopRecording() {
		audioRecorder?.stop()
		audioRecorder = nil
		updateViews()
	}

	func recordToggle() {
		if isRecording {
			stopRecording()
		} else {
			record()
		}
	}
}

extension AudioRecorderController: AVAudioPlayerDelegate {
	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		if let error = error {
			print("Audio playback error: \(error)")
		}
	}
	
	// TODO: Cancel timer?
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		updateViews()	// TODO: is this on the main thread?
	}
}

extension AudioRecorderController: AVAudioRecorderDelegate {
	func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
		if let error = error {
			print("Record error: \(error)")
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		print("Recording finished")
		// TODO: Create player with new file URL
		
		if let recordURL = recordURL {
			audioPlayer = try! AVAudioPlayer(contentsOf: recordURL) // FIXME: make safer
		}
	}
}
