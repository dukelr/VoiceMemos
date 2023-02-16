
import UIKit
import AVFoundation

//MARK: - private extensions

private extension String {
    static let titleText = "Voice Memos"
    static let hintText = "Tap the Record button to start a Voice Memo"
    static let messageForAlert = "The app needs access to the microphone"
    static let ok = "OK"
    static let cancel = "Cancel"
    static let dateFormat = "dd.MM.yyyy_HH:mm"
    static let pathExtension = "m4a"
    static let dot = "."
    static let underscore = "_"
    static let space = " "
    static let empty = ""
    
    static func getNewNameRecording(_ number: Int) -> String {
        "New_Recording_\(number)_"
    }
}

private extension Double {
    static let durationForAnimate = 0.3
    static let secondsInMinute = 60.0
}

private extension CGFloat {
    static let heightForRow = 70.0
}

class VoiceMemosViewController: UIViewController {
    
    //MARK: var/let
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordSession: AVAudioSession?
    private let hintLabel = UILabel()
    private let topContainerView = UIView()
    private let bottomContainerView = UIView()
    private let recordingNameLabel = UILabel()
    private let recordingDurationLabel = UILabel()
    private let recordButton = UIButton()
    private let listRecordingsTableView = UITableView()
    private var recordingsArray = [Recording]()
    private var timer = Timer()
    private var countRecordings = 0
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        startRecording(!sender.isSelected)
    }
    
    //MARK: - setup UI funcs
    
    private func setupSubviews() {
        if let count = StorageManager.shared.loadCountRecordings() {
            countRecordings = count
        }
        if listRecordingsTableView.numberOfRows(inSection: .zero) == .zero {
            hintLabel.isHidden = true
        } else {
            hintLabel.isHidden = false
        }
        view.backgroundColor = .black
        addSubviews()
        checkPermission()
        updateListRecordings()
    }
    
    private func addSubviews() {
        addTitleLabel()
        addContainerViews()
        addRecordingLabels()
        addRecordButton()
        addTableView()
        addHintLabel()
    }
    
    private func addTitleLabel() {
        let offset = CGFloat(20)
        let titleLabel = UILabel(
            frame: CGRect(
                x: offset,
                y: offset * 4,
                width: view.frame.width,
                height: offset
            )
        )
        titleLabel.text = .titleText
        titleLabel.font = .helveticaBolt
        titleLabel.textColor = .white
        view.addSubview(titleLabel)
    }
    
    private func addHintLabel() {
        let size = CGFloat(20)
        let alpha = 0.7
        hintLabel.frame = CGRect(
            x: .zero,
            y: view.frame.height / 2 - size / 2,
            width: view.frame.width,
            height: size
        )
        hintLabel.adjustsFontSizeToFitWidth = true
        hintLabel.textAlignment = .center
        hintLabel.text = .hintText
        hintLabel.textColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(hintLabel)
    }
    
    private func addContainerViews() {
        let size = view.frame.height / 8
        let alpha = 0.2
        topContainerView.frame.origin = view.frame.origin
        topContainerView.frame.size = CGSize(
            width: view.frame.width,
            height: size
        )
        view.addSubview(topContainerView)
        
        let height = 0.7
        let separatorView = UIView(
            frame: CGRect(
                x: .zero,
                y: size - height,
                width: view.frame.width,
                height: height
            )
        )
        separatorView.backgroundColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(separatorView)
        
        bottomContainerView.frame = CGRect(
            x: .zero,
            y: view.frame.height - size,
            width: view.frame.width,
            height: size)
        bottomContainerView.backgroundColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(bottomContainerView)
    }
    
    private func addRecordingLabels() {
        let size = CGFloat(25)
        recordingDurationLabel.frame = CGRect(
            x: .zero,
            y: bottomContainerView.frame.origin.y - size,
            width: view.frame.width,
            height: size)
        recordingDurationLabel.textColor = .white
        recordingDurationLabel.textAlignment = .center
        recordingDurationLabel.isHidden = true
        view.addSubview(recordingDurationLabel)
        
        recordingNameLabel.frame = recordingDurationLabel.frame
        recordingNameLabel.frame.origin.y -= size
        recordingNameLabel.textColor = .white
        recordingNameLabel.textAlignment = .center
        recordingNameLabel.isHidden = true
        view.addSubview(recordingNameLabel)
    }
    
    private func addRecordButton() {
        let offset = CGFloat(2.5)
        let size = CGFloat(50)
        let borderView = UIView()
        borderView.frame = CGRect(
            x: bottomContainerView.frame.width / 2 - size / 2,
            y: bottomContainerView.frame.origin.y + size / 2.5,
            width: size,
            height: size
        )
        borderView.backgroundColor = .white
        borderView.layer.cornerRadius = borderView.frame.width / 2
        view.addSubview(borderView)
        
        let backgroundView = UIView()
        backgroundView.frame.size = CGSize(
            width: borderView.frame.width - offset * 2,
            height: borderView.frame.height - offset * 2
        )
        backgroundView.center = borderView.center
        backgroundView.backgroundColor = .black
        backgroundView.layer.cornerRadius = backgroundView.frame.width / 2
        view.addSubview(backgroundView)
        
        recordButton.frame.size = CGSize(
            width: backgroundView.frame.width - offset * 2,
            height: backgroundView.frame.height - offset * 2
        )
        recordButton.addTarget(
            self,
            action: #selector(recordButtonPressed),
            for: .touchUpInside
        )
        recordButton.center = backgroundView.center
        recordButton.backgroundColor = .red
        recordButton.layer.cornerRadius = recordButton.frame.width / 2
        view.addSubview(recordButton)
    }
    
    private func addTableView() {
        let alpha = CGFloat(0.7)
        listRecordingsTableView.frame = CGRect(
            x: .zero,
            y: topContainerView.frame.height,
            width: view.frame.width,
            height: view.frame.height - topContainerView.frame.height - bottomContainerView.frame.height
        )
        listRecordingsTableView.separatorStyle = .singleLine
        listRecordingsTableView.separatorColor = .lightGray.withAlphaComponent(alpha)
        listRecordingsTableView.backgroundColor = view.backgroundColor
        view.addSubview(listRecordingsTableView)
        listRecordingsTableView.register(
            RecordingTableViewCell.self,
            forCellReuseIdentifier: RecordingTableViewCell.identifier
        )
        listRecordingsTableView.delegate = self
        listRecordingsTableView.dataSource = self
    }
    
    //MARK: - flow funcs
    
    func updateListRecordings() {
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
    
    private func checkPermission() {
        recordSession = AVAudioSession.sharedInstance()
        try? recordSession?.setCategory(.playAndRecord, mode: .default)
        try? recordSession?.setActive(true)
        recordSession?.requestRecordPermission() { [weak self] granted in
            if !granted {
                self?.showAlert()
            }
        }
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            print("No access")
        }
    }
    
    private func showAlert() {
        let alert = UIAlertController(
            title: .titleText,
            message: .messageForAlert,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: .ok,
                style: .default
            )
        )
        alert.addAction(
            UIAlertAction(
                title: .cancel,
                style: .cancel
            )
        )
        present(alert, animated: true)
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
    
    private func startRecording(_ start: Bool) {
        recordingNameLabel.text = String.getNewNameRecording(countRecordings).replacingOccurrences(of: String.underscore, with: String.space)
        recordingDurationLabel.text = .zeroTime
        toggleRecordButton()
        showRecordingLabels(recordButton.isSelected)
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
            listRecordingsTableView.reloadData()
            countRecordings += 1
            StorageManager.shared.saveCountRecordings(countRecordings)
        }
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
                    let seconds = 60.0
                    self.recordingDurationLabel.text = String(
                        format: .recordingDurationFormat,
                        Int(recorder.currentTime / seconds),
                        Int(recorder.currentTime.truncatingRemainder(dividingBy: seconds))
                    )
                    recorder.updateMeters()
                }
            }
        } else {
            timer.invalidate()
        }
        
    }
    
    private func showRecordingLabels(_ show: Bool) {
        let offset = recordingNameLabel.frame.height * 2.5
        if show {
            UIView.animate(withDuration: .durationForAnimate) { [weak self] in
                guard let self = self else { return }
                
                self.bottomContainerView.frame.origin.y -= offset
                self.bottomContainerView.frame.size.height += offset
                self.listRecordingsTableView.frame.size.height -= offset
            } completion: { [weak self] _ in
                guard let self = self else { return }
                
                self.recordingNameLabel.isHidden = false
                self.recordingDurationLabel.isHidden = false
            }
        } else {
            UIView.animate(withDuration: .durationForAnimate) { [weak self] in
                guard let self = self else { return }
                
                self.recordingNameLabel.isHidden = true
                self.recordingDurationLabel.isHidden = true
                self.listRecordingsTableView.frame.size.height += offset
                self.bottomContainerView.frame.origin.y += offset
                self.bottomContainerView.frame.size.height -= offset
            }
        }
    }
    
    private func toggleRecordButton() {
        let offset = CGFloat(10)
        let cornerRadius = CGFloat(3)
        let center = recordButton.center
        
        if !recordButton.isSelected {
            UIView.animate(withDuration: .durationForAnimate) { [weak self] in
                guard let self = self else { return }

                self.recordButton.frame.origin.x -= offset
                self.recordButton.frame.origin.y -= offset
                self.recordButton.frame.size.width -= offset * 2
                self.recordButton.frame.size.height -= offset * 2
                self.recordButton.center = center
                self.recordButton.layer.cornerRadius = cornerRadius
            }
        } else {
            UIView.animate(withDuration: .durationForAnimate) { [weak self] in
                guard let self = self else { return }

                self.recordButton.frame.origin.x += offset
                self.recordButton.frame.origin.y += offset
                self.recordButton.frame.size.width += offset * 2
                self.recordButton.frame.size.height += offset * 2
                self.recordButton.center = center
                self.recordButton.layer.cornerRadius = self.recordButton.frame.width / 2
            }
        }
        recordButton.isSelected.toggle()
    }
    
    private func pushAudioPlayerViewController(for recording: Recording) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: AudioPlayerViewController.identifier) as? AudioPlayerViewController else { return }
        controller.recording = recording
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

//MARK: - Extensions UITableViewDelegate, UITableViewDataSource

extension VoiceMemosViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordingsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else { return UITableViewCell() }
        cell.configure(with: recordingsArray[indexPath.item])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try? FileManager.default.removeItem(at: recordingsArray[indexPath.row].url)
            recordingsArray.remove(at: indexPath.item)
            updateListRecordings()
            listRecordingsTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        .heightForRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushAudioPlayerViewController(for: recordingsArray[indexPath.item])
    }
}

//MARK: - Extensions AVAudioPlayerDelegate, AVAudioRecorderDelegate

extension VoiceMemosViewController: AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            startRecording(false)
        }
    }
}

//MARK: - Extensions AudioPlayerViewControllerDelegate

extension VoiceMemosViewController: AudioPlayerViewControllerDelegate {
    
    func recordingRemoved(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.url)
        recordingsArray = recordingsArray.filter { $0.name != recording.name }
        updateListRecordings()
        listRecordingsTableView.reloadData()
    }
}

//MARK: - SwiftUI PreviewProvider

import SwiftUI
struct ListProvider: PreviewProvider {
    static var previews: some View {
        ContainterView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainterView: UIViewControllerRepresentable {
        
        let listVC = VoiceMemosViewController()
        func makeUIViewController(context: UIViewControllerRepresentableContext<ListProvider.ContainterView>) -> VoiceMemosViewController {
            return listVC
        }
        
        func updateUIViewController(_ uiViewController: ListProvider.ContainterView.UIViewControllerType, context: UIViewControllerRepresentableContext<ListProvider.ContainterView>) {
        }
    }
}
