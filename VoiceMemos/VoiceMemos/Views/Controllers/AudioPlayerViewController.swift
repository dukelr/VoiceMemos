
import UIKit
import AVFoundation

//MARK: - Protocols

protocol AudioPlayerViewControllerDelegate: AnyObject {
    func recordingRemoved(_ recording: Recording)
}

//MARK: - private extensions

private extension CGFloat {
    static let sizeForButton = 33.0
}

private extension String {
    static let alertMessage = "Do you want to remove this recording?"
    static let remove = "Remove"
    static let cancel = "Cancel"
}

private extension UIImage {
    static let playImage = UIImage(systemName: "play.fill")
    static let pauseImage = UIImage(systemName: "pause.fill")
    static let forwardImage = UIImage(systemName: "goforward.15")
    static let backwardImage = UIImage(systemName: "gobackward.15")
    static let trashImage = UIImage(systemName: "trash")
    static let backImage = UIImage(systemName: "chevron.backward")
}

class AudioPlayerViewController: UIViewController {
    
    //MARK: - Enums
    
    private enum Rewinding {
        case backward
        case forward
        case slider
    }
    
    //MARK: - var/let
    
    static let identifier = "AudioPlayerViewController"
    private var audioPlayer: AVAudioPlayer?
    weak var delegate: AudioPlayerViewControllerDelegate?
    private let slider = UISlider()
    private let playButton = UIButton()
    private let nameRecordingLabel = UILabel()
    private let elapsedDurationRecordingLabel = UILabel()
    private let remainingDurationRecordingLabel = UILabel()
    private var recordingDurationTimer = Timer()
    var recording: Recording?
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        playRecording()
    }
    
    @IBAction func sliderValuerChanged(_ sender: UISlider) {
        rewindRecording(.slider)
    }
    
    @IBAction func flashForwardButtonPressed(_ sender: UIButton) {
        rewindRecording(.forward)
    }
    
    @IBAction func flashBackwardButtonPressed(_ sender: UIButton) {
        rewindRecording(.backward)
    }
    
    @IBAction func trashButtonPressed(_ sender: UIButton) {
        showAlert()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        popToVoiceMemosViewController()
    }
    
    //MARK: - setup UI funcs
    
    private func setupSubviews() {
        view.backgroundColor = .black
        addSubviews()
        if let recording = recording {
            nameRecordingLabel.text = recording.name
            elapsedDurationRecordingLabel.text = .zeroTime
            remainingDurationRecordingLabel.text = recording.duration
            audioPlayer = try? AVAudioPlayer(contentsOf: recording.url)
            
            if let audioPlayer = audioPlayer {
                slider.maximumValue = Float(audioPlayer.duration)
            }
        }
    }
    
    private func addSubviews() {
        addSlider()
        addNameRecordingLabel()
        addPlayButton()
        addFlashButtons()
        addDurationLabels()
        addTrashButton()
        addBackButton()
    }
    
    private func addSlider() {
        slider.frame = CGRect(
            x: .zero,
            y: .zero,
            width: view.frame.width - .sizeForButton,
            height: .sizeForButton
        )
        slider.center = view.center
        slider.addTarget(
            self,
            action: #selector(sliderValuerChanged),
            for: .valueChanged
        )
        slider.tintColor = .white
        view.addSubview(slider)
    }
    
    private func addNameRecordingLabel() {
        let size = CGFloat(75)
        nameRecordingLabel.frame = CGRect(
            x: view.frame.width / 2 - slider.frame.width / 2,
            y: slider.frame.origin.y - size,
            width: slider.frame.width,
            height: size
        )
        nameRecordingLabel.font = .helveticaBolt
        nameRecordingLabel.textColor = .white
        nameRecordingLabel.textAlignment = .center
        view.addSubview(nameRecordingLabel)
    }
    
    private func addPlayButton() {
        playButton.frame = CGRect(
            x: view.frame.width / 2 - .sizeForButton / 2,
            y: slider.frame.origin.y + slider.frame.height + .sizeForButton,
            width: .sizeForButton,
            height: .sizeForButton
        )
        playButton.addTarget(
            self,
            action: #selector(playButtonPressed),
            for: .touchUpInside
        )
        playButton.setBackgroundImage(.playImage, for: .normal)
        playButton.setBackgroundImage(.pauseImage, for: .selected)
        playButton.tintColor = .white
        view.addSubview(playButton)
    }
    
    private func addFlashButtons() {
        let flashForwardButton = UIButton(frame: playButton.frame)
        flashForwardButton.frame = playButton.frame
        flashForwardButton.frame.origin.x += .sizeForButton * 2
        flashForwardButton.addTarget(
            self,
            action: #selector(flashForwardButtonPressed),
            for: .touchUpInside
        )
        flashForwardButton.setBackgroundImage(.forwardImage, for: .normal)
        flashForwardButton.tintColor = .white
        view.addSubview(flashForwardButton)
        
        let flashBackwardButton = UIButton(frame: playButton.frame)
        flashBackwardButton.frame.origin.x -= .sizeForButton * 2
        flashBackwardButton.addTarget(
            self,
            action: #selector(flashBackwardButtonPressed),
            for: .touchUpInside
        )
        flashBackwardButton.setBackgroundImage(.backwardImage, for: .normal)
        flashBackwardButton.tintColor = .white
        view.addSubview(flashBackwardButton)
    }
    
    private func addDurationLabels() {
        let alpha = 0.5
        elapsedDurationRecordingLabel.frame = slider.frame
        elapsedDurationRecordingLabel.frame.origin.y += slider.frame.height
        elapsedDurationRecordingLabel.textColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(elapsedDurationRecordingLabel)
        
        remainingDurationRecordingLabel.frame = elapsedDurationRecordingLabel.frame
        remainingDurationRecordingLabel.textColor = elapsedDurationRecordingLabel.textColor
        remainingDurationRecordingLabel.textAlignment = .right
        view.addSubview(remainingDurationRecordingLabel)
    }
    
    private func addTrashButton() {
        let trashButton = UIButton()
        trashButton.frame.origin = CGPoint(
            x: elapsedDurationRecordingLabel.frame.width - .sizeForButton,
            y: view.frame.height - .sizeForButton * 3
        )
        trashButton.frame.size = playButton.frame.size
        trashButton.addTarget(
            self,
            action: #selector(trashButtonPressed),
            for: .touchUpInside
        )
        trashButton.setBackgroundImage(.trashImage, for: .normal)
        trashButton.tintColor = .white
        view.addSubview(trashButton)
    }
    
    private func addBackButton() {
        let backButton = UIButton()
        backButton.frame = CGRect(
            x: elapsedDurationRecordingLabel.frame.origin.x,
            y: .sizeForButton * 3,
            width: .sizeForButton / 2,
            height: .sizeForButton
        )
        backButton.addTarget(
            self,
            action: #selector(backButtonPressed),
            for: .touchUpInside
        )
        backButton.setBackgroundImage(.backImage, for: .normal)
        backButton.tintColor = .white
        view.addSubview(backButton)
    }
    
    //MARK: - flow funcs
    
    private func playRecording() {
        if !playButton.isSelected {
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startTimer()
        } else {
            audioPlayer?.pause()
            recordingDurationTimer.invalidate()
        }
        playButton.isSelected.toggle()
    }
    
    private func startTimer() {
        guard let audioPlayer = audioPlayer else { return }
        let timeInterval = 0.1
        let secondsInMinute = Double(60)
        recordingDurationTimer.invalidate()
        recordingDurationTimer = .scheduledTimer(
            withTimeInterval: timeInterval,
            repeats: true
        ) { [weak self] _ in
            if !audioPlayer.isPlaying {
                self?.playButton.isSelected = false
            }
            self?.slider.value = Float(audioPlayer.currentTime)
            self?.elapsedDurationRecordingLabel.text = String(
                format: .recordingDurationFormat,
                Int(audioPlayer.currentTime / secondsInMinute),
                Int(audioPlayer.currentTime.truncatingRemainder(dividingBy: secondsInMinute))
            )
            self?.remainingDurationRecordingLabel.text = String(
                format: .recordingDurationFormat,
                Int((audioPlayer.duration / secondsInMinute) - (audioPlayer.currentTime / secondsInMinute)),
                Int((audioPlayer.duration.truncatingRemainder(dividingBy: secondsInMinute)) - (audioPlayer.currentTime.truncatingRemainder(dividingBy: secondsInMinute)))
            )
        }
    }
    
    private func rewindRecording(_ rewinding: Rewinding) {
        let seconds = Double(15)
        switch rewinding {
        case .backward:
            audioPlayer?.currentTime -= seconds
        case .forward:
            audioPlayer?.currentTime += seconds
        case .slider:
            playButton.isSelected = false
            playRecording()
            audioPlayer?.currentTime = Double(slider.value)
        }
    }
    
    private func showAlert() {
        let alert = UIAlertController(
            title: recording?.name,
            message: .alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: .remove,
                style: .destructive)
            { [weak self] _ in
                self?.removeRecording()
            }
        )
        alert.addAction(
            UIAlertAction(
                title: .cancel,
                style: .cancel
            )
        )
        present(alert, animated: true)
        audioPlayer?.stop()
    }
    
    private func removeRecording() {
        if let recording = recording {
            delegate?.recordingRemoved(recording)
            popToVoiceMemosViewController()
        }
    }
    
    private func popToVoiceMemosViewController() {
        audioPlayer?.stop()
        navigationController?.popToRootViewController(animated: true)
    }
}
