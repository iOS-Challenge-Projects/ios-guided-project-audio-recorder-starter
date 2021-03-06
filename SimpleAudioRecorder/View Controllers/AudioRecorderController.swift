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
    
    //MARK: - Properties
    private var audioRecoreder: AVAudioRecorder?
    
    private var isRecording: Bool {
        //give default value of false since is an optional
        audioRecoreder?.isRecording  ?? false
    }
    
    private var audioPlayer: AVAudioPlayer? {
        didSet {
            audioPlayer?.delegate = self
            //Enable audio animation
            audioPlayer?.isMeteringEnabled = true
        }
    }
    
    private var isPlaying: Bool {
        //give default value of false since is an optional
        audioPlayer?.isPlaying  ?? false
    }
    
    private var timer: Timer?
    
    private var recordingURL: URL?
    
    //MARK: - Outlets
    
    @IBOutlet var playButton: UIButton!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var timeElapsedLabel: UILabel!
    @IBOutlet var timeRemainingLabel: UILabel!
    @IBOutlet var timeSlider: UISlider!
    @IBOutlet var audioVisualizer: AudioVisualizer!
    
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
        updateViews()
        loadAudio()
        
        try? prepareAudioSession()
    }
    
    
    func updateViews() {
        //Set the state of the button = to isPlaying -> Bool
        playButton.isSelected = isPlaying
        recordButton.isSelected = isRecording
        
        //Update the Start label to show the timer
        let elapsedTime = audioPlayer?.currentTime ?? 0
        timeElapsedLabel.text = timeIntervalFormatter.string(from: elapsedTime)
        
        
        //Setupslider / progress bar
        timeSlider.value = Float(elapsedTime)
        timeSlider.minimumValue = 0 //Start
        let duration = audioPlayer?.duration ?? 0
        timeSlider.maximumValue = Float(duration)//Ends
    }
    
    // MARK: - Timer
    
 
    func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.030, repeats: true) { [weak self] (_) in
            guard let self = self else { return }
            
            self.updateViews()
            
//            if let audioRecorder = self.audioRecorder,
//                self.isRecording == true {
//
//                audioRecorder.updateMeters()
//                self.audioVisualizer.addValue(decibelValue: audioRecorder.averagePower(forChannel: 0))
//
//            }
            
            if let audioPlayer = self.audioPlayer,
                self.isPlaying == true {
            
                audioPlayer.updateMeters()
                self.audioVisualizer.addValue(decibelValue: audioPlayer.averagePower(forChannel: 0))
            }
        }
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
 
    
    
    // MARK: - Playback
    
    func loadAudio() {
        guard let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3") else {return}
        
        audioPlayer = try? AVAudioPlayer(contentsOf: songURL)

        
    }
    
 
    func prepareAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try session.setActive(true, options: []) // can fail if on a phone call, for instance
    }
 
    
    func play() {
        audioPlayer?.play()
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        cancelTimer()
    }
    
    
    // MARK: - Recording
    
    func createNewRecordingURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: .withInternetDateTime)
        let file = documents.appendingPathComponent(name, isDirectory: false).appendingPathExtension("caf")
        
        print("recording URL: \(file)")
        
        return file
    }
    
    func requestPermissionOrStartRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                guard granted == true else {
                    print("We need microphone access")
                    return
                }
                
                print("Recording permission has been granted!")
                // NOTE: Invite the user to tap record again, since we just interrupted them, and they may not have been ready to record
            }
        case .denied:
            print("Microphone access has been blocked.")
            
            let alertController = UIAlertController(title: "Microphone Access Denied", message: "Please allow this app to access your Microphone.", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Open Settings", style: .default) { (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        case .granted:
            startRecording()
        @unknown default:
            break
        }
    }
 
    func startRecording() {
       let recordingURL = createNewRecordingURL()
        
        //Setup AVAudio record
        //44_100 = 44.5KHz audio quality which is equivalent to FM radio
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        do{
            audioRecoreder = try AVAudioRecorder(url: recordingURL, format: audioFormat)
        }catch{
            print("Error Recording audio: \(error)")
        }
        audioRecoreder?.record()
        audioRecoreder?.delegate = self
        
        updateViews()
        
        self.recordingURL = recordingURL
    }
    
    func stopRecording() {
        audioRecoreder?.stop()
        updateViews()
    }
    
    // MARK: - Actions
    
    @IBAction func togglePlayback(_ sender: Any) {
        
        if isPlaying{
            pause()
        }else{
            play()
        }
        
        updateViews()
    }
    
    @IBAction func updateCurrentTime(_ sender: UISlider) {
        if isPlaying{
            pause()
        }
        audioPlayer?.currentTime = TimeInterval(timeSlider.value)
        updateViews()
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        if isRecording{
            stopRecording()
        }else{
            requestPermissionOrStartRecording()
        }
    }
}

//MARK: - AVAudioPlayerDelegate
extension AudioRecorderController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //Call updateViews so when the audio finishes it switches the play button from pause back to play
        updateViews()
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Error decoding audio \(error)")
        }
        updateViews()
    }
}

//MARK: - AVAudioRecorderDelegate
extension AudioRecorderController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        //FIXME: Create a do/catch block
        //Setup play to play the last recording
        if let recordingURL = recordingURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: recordingURL)
        }
        
        updateViews()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recorder Error: \(error)")
        }
    }
}
