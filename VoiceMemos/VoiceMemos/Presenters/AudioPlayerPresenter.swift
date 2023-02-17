
import Foundation
import AVFoundation

protocol AudioPlayerPresenterDelegate: AnyObject {
    func recordingStartedPlaying(_ playing: Bool)
    func recordingRemoved(_ recording: Recording)
    func valuesDurationUpdated()
}

final class AudioPlayerPresenter {
    
    enum Rewinding {
        case backward
        case forward
        case slider
    }
    
    weak var delegate: AudioPlayerPresenterDelegate?
    private var audioPlayer: AVAudioPlayer?
    private var recordingDurationTimer: Timer?
    var recording: Recording
    
    init(recording: Recording) {
        self.recording = recording
        
        audioPlayer = try? AVAudioPlayer(contentsOf: recording.url)
    }
    
    func stopAudioPlayer() {
        audioPlayer?.stop()
    }
    
    func removeRecording() {        
        delegate?.recordingRemoved(recording)
    }
    
    func getCurrentTimeRecording() -> Float {
        guard let audioPlayer = audioPlayer else { return .zero}
        
        return Float(audioPlayer.currentTime)
    }
    
    func getElapsedDurationRecording() -> String {
        guard let audioPlayer = audioPlayer else { return "" }
        
        return String(
            format: .recordingDurationFormat,
            Int(audioPlayer.currentTime / .secondsInMinute),
            Int(audioPlayer.currentTime.truncatingRemainder(dividingBy: .secondsInMinute))
        )
    }
    
    func getRemainingDurationRecording() -> String {
        guard let audioPlayer = audioPlayer else { return "" }
        
        return String(
            format: .recordingDurationFormat,
            Int((audioPlayer.duration / .secondsInMinute) - (audioPlayer.currentTime / .secondsInMinute)),
            Int((audioPlayer.duration.truncatingRemainder(dividingBy: .secondsInMinute)) - (audioPlayer.currentTime.truncatingRemainder(dividingBy: .secondsInMinute)))
        )
    }
    
    func getFullDurationRecording() -> Float {
        guard let audioPlayer = audioPlayer else { return .zero}
        
        return Float(audioPlayer.duration)
    }
    
    func rewindRecording(_ rewinding: Rewinding, sliderValue: Float? = nil) {
        let seconds = Double(15)
        switch rewinding {
        case .backward:
            audioPlayer?.currentTime -= seconds
        case .forward:
            audioPlayer?.currentTime += seconds
        case .slider:
            guard let sliderValue = sliderValue else { return }
            
            if audioPlayer?.duration == Double(sliderValue) {
                return
            }
            playRecording(true)
            audioPlayer?.currentTime = Double(sliderValue)
            delegate?.valuesDurationUpdated()
        }
    }
    
    func playRecording(_ play: Bool) {
        if play {
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startTimer()
        } else {
            audioPlayer?.pause()
            recordingDurationTimer?.invalidate()
        }
    }
    
    private func startTimer() {
        guard let audioPlayer = audioPlayer else { return }
        
        let timeInterval = 0.1
        recordingDurationTimer?.invalidate()
        recordingDurationTimer = .scheduledTimer(
            withTimeInterval: timeInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
                        
            if !audioPlayer.isPlaying {
                self.delegate?.recordingStartedPlaying(false)
            }
            self.delegate?.recordingStartedPlaying(true)
        }
    }
}
