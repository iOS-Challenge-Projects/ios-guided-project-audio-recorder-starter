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
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?
    
    var timer: Timer?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var audioVisualizer: AudioVisualizer!
	
	private lazy var timeIntervalFormatter: DateComponentsFormatter = {
        // NOTE: DateComponentFormatter is good for minutes/hours/seconds
        // DateComponentsFormatter is not good for milliseconds, use DateFormatter instead)
        
		let formatting = DateComponentsFormatter()
        formatting.unitsStyle = .positional // 00:00  mm:ss
		formatting.zeroFormattingBehavior = .pad
		formatting.allowedUnits = [.minute, .second]
		return formatting
	}()
    
    
    // MARK: - View Controller Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use a font that won't jump around as values change
        timeElapsedLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeElapsedLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
        
        loadAudio()
        updateViews()
    }

    // Called anytime this class is cleaned up (Nav controller, tab controller, table view)
    deinit {
        stopTimer()
    }
    
    // call this code using a Timer
    private func updateViews() {
        playButton.isSelected = isPlaying
        recordButton.isSelected = isRecording
        
        // update time (currentTime)

        let elapsedTime = audioPlayer?.currentTime ?? 0
        timeElapsedLabel.text = timeIntervalFormatter.string(from: elapsedTime)
        
        timeSlider.value = Float(elapsedTime)
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        
        let timeRemaining = (audioPlayer?.duration ?? 0) - elapsedTime
        timeRemainingLabel.text = timeIntervalFormatter.string(from: timeRemaining)
        
        // TODO: Deal with time rounding up/down between both time labels
        
    }

    // MARK: - Playback

    func loadAudio() {
        // app bundle is readonly folder
        let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!  // programmer error if this fails to load
        
        audioPlayer = try? AVAudioPlayer(contentsOf: songURL)  // FIXME: use better error handling
        audioPlayer?.isMeteringEnabled = true
        audioPlayer?.delegate = self
    }

    func startTimer() {
        // timers are automatically registered on run loop, so we need to cancel before adding a new one
        stopTimer()
        // Call every 30 ms (10-30)
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            
            self.updateViews()
            
            if let audioPlayer = self.audioPlayer {
                audioPlayer.updateMeters()
                self.audioVisualizer.addValue(decibelValue: audioPlayer.averagePower(forChannel: 0))
            }
            
            if let audioRecorder = self.audioRecorder {
                audioRecorder.updateMeters()
                self.audioVisualizer.addValue(decibelValue: audioRecorder.averagePower(forChannel: 0))
            }
        })
    }
    
    // Where should I call stop timer?
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    // What do I want to do?
    // pause it
    // volume
    // restart the audio
    // update the time/labels

    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    func play() {
        audioPlayer?.play()
        startTimer()
        updateViews()
    }

    func pause() {
        audioPlayer?.pause()
        stopTimer()
        updateViews()
    }

    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    
    // MARK: - Recording
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    func startRecording() {
        recordingURL = makeNewRecordingURL()
        if let recordingURL = recordingURL {
            print("URL: \(recordingURL)")
            
            // 44.1 KHz = FM quality audio
            let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)! // FIXME: can fail
            
            audioRecorder = try! AVAudioRecorder(url: recordingURL, format: format) // FIXME: Deal with errors fatalError()
            audioRecorder?.record()
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            updateViews()
            startTimer()
        }
    }
    
    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted == true else {
                    fatalError("We need microphone access")
                }
                self.startRecording()
            }
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        updateViews()
        stopTimer()
    }

    func toggleRecording() {
        if isRecording {
           stopRecording()
        } else {
           requestRecordPermission()
        }
    }
    
    func makeNewRecordingURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // 2020-01-18T23/10/40-08/00.caf
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
        let url = documents.appendingPathComponent(name).appendingPathExtension("caf")
        return url
    }
    
    
    // MARK: - Actions
    
    @IBAction func togglePlayback(_ sender: Any) {
        playPause()
    }
    
    @IBAction func updateCurrentTime(_ sender: UISlider) {
        
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        toggleRecording()
    }
}

extension AudioRecorderController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()
        stopTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("AudioPlayer Error: \(error)")
        }
    }
}

extension AudioRecorderController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag == true {
            // update player to load the new file
            
            if let recordingURL = recordingURL {
                audioPlayer = try? AVAudioPlayer(contentsOf: recordingURL)
                audioPlayer?.isMeteringEnabled = true
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("AudioRecorder error: \(error)")
        }
    }
}
