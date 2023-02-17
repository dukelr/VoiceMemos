
import UIKit
import AVFoundation

//MARK: - Protocols

protocol AudioPlayerViewControllerDelegate: AnyObject {
    func audioPlayerViewControllerClosed(withRemoved recording: Recording)
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

final class AudioPlayerViewController: UIViewController {
    
    //MARK: - var/let
    
    static let identifier = "AudioPlayerViewController"
    weak var delegate: AudioPlayerViewControllerDelegate?
    private let slider = UISlider()
    private let playButton = UIButton()
    private let nameRecordingLabel = UILabel()
    private let elapsedDurationRecordingLabel = UILabel()
    private let remainingDurationRecordingLabel = UILabel()
    var presenter: AudioPlayerPresenter?
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPresenter()
        setupSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        presenter?.playRecording(!sender.isSelected)
        sender.isSelected.toggle()
    }
    
    @IBAction func sliderValuerChanged(_ sender: UISlider) {
        playButton.isSelected = true
        presenter?.rewindRecording(.slider, sliderValue: slider.value)
    }
    
    @IBAction func flashForwardButtonPressed(_ sender: UIButton) {
        presenter?.rewindRecording(.forward)
    }
    
    @IBAction func flashBackwardButtonPressed(_ sender: UIButton) {
        presenter?.rewindRecording(.backward)
    }
    
    @IBAction func trashButtonPressed(_ sender: UIButton) {
        showAlert()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        popToVoiceMemosViewController()
    }
    
    //MARK: - flow funcs

    private func setupPresenter() {
        presenter?.delegate = self
    }
    
    private func setupSubviews() {
        addSubviews()
        view.backgroundColor = .black
        nameRecordingLabel.text = presenter?.recording.name
        elapsedDurationRecordingLabel.text = .zeroTime
        remainingDurationRecordingLabel.text = presenter?.recording.duration

        if let maximumValue = presenter?.getFullDurationRecording() {
            slider.maximumValue = maximumValue
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
    
    private func setupDurationLabelsAndSlider() {
        slider.value = presenter?.getCurrentTimeRecording() ?? .zero
        elapsedDurationRecordingLabel.text = presenter?.getElapsedDurationRecording()
        remainingDurationRecordingLabel.text = presenter?.getRemainingDurationRecording()
    }
    
    private func showAlert() {
        let alert = UIAlertController(
            title: presenter?.recording.name,
            message: .alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: .remove,
                style: .destructive)
            { [weak self] _ in
                guard let self = self else { return }
                
                self.presenter?.removeRecording()
            }
        )
        alert.addAction(
            UIAlertAction(
                title: .cancel,
                style: .cancel
            )
        )
        present(alert, animated: true)
        presenter?.stopAudioPlayer()
    }
    
    private func popToVoiceMemosViewController() {
        presenter?.stopAudioPlayer()
        navigationController?.popToRootViewController(animated: true)
    }
}

extension AudioPlayerViewController: AudioPlayerPresenterDelegate {
    func valuesDurationUpdated() {
        setupDurationLabelsAndSlider()
    }
    
    func recordingStartedPlaying(_ playing: Bool) {
        if playing {
            setupDurationLabelsAndSlider()
        } else {
            playButton.isSelected = false
        }
    }
    
    func recordingRemoved(_ recording: Recording) {
        delegate?.audioPlayerViewControllerClosed(withRemoved: recording)
        popToVoiceMemosViewController()
    }
}
