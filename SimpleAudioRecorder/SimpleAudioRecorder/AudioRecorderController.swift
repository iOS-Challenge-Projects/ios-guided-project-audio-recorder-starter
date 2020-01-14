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

	// Playback APIs
	
	// What are function names I need?
	
	// - get audio file
	// - play
	// - pause
	// - timestamp (current time?)
	// - is it playing?
	var audioPlayer: AVAudioPlayer?

	var timer: Timer?
	
	private func loadAudio() {
		// piano.mp3
		// App Bundle - readonly
		// Documents - readwrite
		
		// force unwrap is ok for demo/prototypes, but it's not safe for production
		let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
		
		audioPlayer = try! AVAudioPlayer(contentsOf: songURL) // FIXME: catch error and print
		audioPlayer?.delegate = self
	}
	
	var isPlaying: Bool {
		audioPlayer?.isPlaying ?? false
	}

	func play() {
		audioPlayer?.play()
		updateViews()
		startTimer()
	}

	func pause() {
		audioPlayer?.pause()
		updateViews()
		cancelTimer()
	}

	func playPause() {
		if isPlaying {
			pause()
		} else {
			play()
		}
	}

	private func startTimer() {
		cancelTimer()
		// 0.01s = faster update
		// 1s = slow update
		timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer(timer:)), userInfo: nil, repeats: true)
	}

	@objc private func updateTimer(timer: Timer) {
		updateViews()
	}

	private func cancelTimer() {
		timer?.invalidate()
		timer = nil
	}
	

	@IBAction func playButtonPressed(_ sender: Any) {
		playPause()
	}
	
	// Record APIs

	var audioRecorder: AVAudioRecorder?
	var recordURL: URL?
	
	var isRecording: Bool {
		return audioRecorder?.isRecording ?? false
	}

	func record() {
		let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
		let file = documents.appendingPathComponent(name).appendingPathExtension("caf")
		recordURL = file
		
		print("record: \(file)")
		
		// 44.1 KHz 44,100 samples per second, 1 microphone
		let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)! // FIXME: error handling
		
		audioRecorder = try! AVAudioRecorder(url: file, format: format) // FIXME: try!
		audioRecorder?.delegate = self
		audioRecorder?.record()
		updateViews()
	}

	func stop() {
		audioRecorder?.stop()
		audioRecorder = nil
		updateViews()
	}

	func recordToggle() {
		if isRecording {
			stop()
		} else {
			record()
		}
	}

	@IBAction func recordButtonPressed(_ sender: Any) {
		recordToggle()
	}
	
	private func updateViews() {
		let playButtonTitle = isPlaying ? "Pause" : "Play" // Pause or Play
		playButton.setTitle(playButtonTitle, for: .normal)
		
		let elapsedTime = audioPlayer?.currentTime ?? 0
		timeLabel.text = timeFormatter.string(from: elapsedTime)
		
		timeSlider.minimumValue = 0
		timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
		timeSlider.value = Float(elapsedTime)
		
		let recordButtonTitle = isRecording ? "Stop" : "Record"
		recordButton.setTitle(recordButtonTitle, for: .normal)
	}
}

extension AudioRecorderController: AVAudioPlayerDelegate {

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		updateViews()
	}

	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		if let error = error {
			print("Audio Player error: \(error)")
		}
	}
}

// TODO: Get permission to record audio

extension AudioRecorderController: AVAudioRecorderDelegate {
	
	func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
		if let error = error {
			print("Audio recorder error: \(error)")
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		
		// TODO: Update player to load our audio file
		
		print("Finished Recording")
		if let recordURL = recordURL {
			audioPlayer = try! AVAudioPlayer(contentsOf: recordURL) // FIXME: handle errors
		}
	}
}
