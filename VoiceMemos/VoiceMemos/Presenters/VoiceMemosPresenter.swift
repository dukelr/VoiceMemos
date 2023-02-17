
import Foundation
import AVFoundation

private extension String {
    static let dateFormat = "dd.MM.yyyy_HH:mm"
    static let pathExtension = "m4a"
    static let dot = "."
    static let underscore = "_"
    static let space = " "
    static let empty = ""
    
    static func getNewNameRecording(_ number: Int) -> String {
        let name = "New_Recording_"
        if number < 10 {
            return name + "0\(number)_"
        } else {
            return name + "\(number)_"
        }
    }
}

protocol VoiceMemosPresenterDelegate: AnyObject {
    func recordingStarted(_ recordingName: String)
    func recordingFinished()
    func timerStarted(_ duration: String)
}

final class VoiceMemosPresenter: NSObject {
    
    weak var delegate: VoiceMemosPresenterDelegate?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordSession: AVAudioSession?
    private var timer: Timer?
    private(set) var recordingsArray = [Recording]()
    private(set) var countRecordings = 0

    override init() {
        super.init()
        if let count = StorageManager.shared.loadCountRecordings() {
            countRecordings = count
        }
        updateListRecordings()
    }
    
    func checkPermission(granted complition: @escaping (Bool) -> ()) {
        recordSession = AVAudioSession.sharedInstance()
        try? recordSession?.setCategory(.playAndRecord, mode: .default)
        try? recordSession?.setActive(true)
        recordSession?.requestRecordPermission() { granted in
            complition(granted)
        }
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            print("No access")
        }
    }
    
    func startRecording(_ start: Bool) {
        delegate?.recordingStarted(getNameRecording())
        if start {
            if let audioPlayer = audioPlayer,
               audioPlayer.isPlaying {
                audioPlayer.stop()
            }
            if audioRecorder == nil {
                setupRecorder()
                audioRecorder?.record()
                startTimer(true)
            }
        } else {
            audioRecorder?.stop()
            audioRecorder = nil
            startTimer(false)
            updateListRecordings()
            countRecordings += 1
            StorageManager.shared.saveCountRecordings(countRecordings)
            delegate?.recordingFinished()
        }
    }
    
    func removeRecording(at index: Int, _ complition: @escaping () -> ()) {
        try? FileManager.default.removeItem(at: recordingsArray[index].url)
        recordingsArray.remove(at: index)
        updateListRecordings()
        complition()
    }
    
    private func updateListRecordings() {
        do {
            guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            let urls = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            urls.filter { $0.pathExtension == .pathExtension }
                .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                .forEach { url in
                    audioPlayer = try? AVAudioPlayer(contentsOf: url)
                    guard let audioPlayer = audioPlayer else { return }
                    
                    var urlName = url.lastPathComponent
                        .replacingOccurrences(of: String.underscore, with: String.space)
                        .replacingOccurrences(of: .dot + .pathExtension, with: String.empty)
                    
                    var date = String.empty
                    (0...String.dateFormat.count).forEach { _ in
                        date.append(urlName.removeLast())
                    }
                    date = String(date.reversed())
                    
                    let duration = String(
                        format: .recordingDurationFormat,
                        Int(audioPlayer.duration / 60),
                        Int(audioPlayer.duration.truncatingRemainder(dividingBy: 60))
                    )
                    let recording = Recording(
                        name: urlName,
                        date: date,
                        duration: duration,
                        url: url
                    )
                    if recordingsArray.filter({ $0.name == recording.name }).isEmpty {
                        recordingsArray.insert(recording, at: .zero)
                    } else {
                        return
                    }
                }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupRecorder() {
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = .dateFormat
        let dateString = formatter.string(from: Date())
        let url = path.appendingPathComponent(.getNewNameRecording(countRecordings) + dateString + .dot + .pathExtension)
        let rateKey = 44100
        let numberOfChanelsKey = 2
        do {
            audioRecorder = try AVAudioRecorder(
                url: url,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: rateKey,
                    AVNumberOfChannelsKey: numberOfChanelsKey,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
            )
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            startRecording(false)
            print(#line, #function, error.localizedDescription)
        }
    }
    
    private func getNameRecording() -> String {
        String.getNewNameRecording(countRecordings).replacingOccurrences(of: String.underscore, with: String.space)
    }
    
    private func startTimer(_ start: Bool) {
        let timeInterval = 0.1
        if start {
            timer = .scheduledTimer(
                withTimeInterval: timeInterval,
                repeats: true
            ) { [weak self] _ in
                guard let self = self else { return }
                
                if let recorder = self.audioRecorder,
                   recorder.isRecording {
                    recorder.updateMeters()
                    self.delegate?.timerStarted(self.getCurrentDurationRecording(recorder))
                }
            }
        } else {
            timer?.invalidate()
        }
    }
    
    private func getCurrentDurationRecording(_ recorder: AVAudioRecorder) -> String {
        String(
            format: .recordingDurationFormat,
            Int(recorder.currentTime / 60),
            Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
        )
    }
    
    func getIndexRecording(_ recording: Recording) -> Int? {
        recordingsArray.firstIndex(where: { $0.name == recording.name })
    }
}

//MARK: - Extensions AVAudioPlayerDelegate, AVAudioRecorderDelegate

extension VoiceMemosPresenter: AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            startRecording(false)
        }
    }
}
