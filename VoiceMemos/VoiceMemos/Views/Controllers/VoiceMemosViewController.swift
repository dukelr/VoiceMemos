
import UIKit

//MARK: - private extensions

private extension String {
    static let titleText = "Voice Memos"
    static let hintText = "Tap the Record button to start a Voice Memo"
    static let messageForAlert = "The app needs access to the microphone"
    static let ok = "OK"
    static let cancel = "Cancel"
}

private extension CGFloat {
    static let heightForRow = 70.0
}

final class VoiceMemosViewController: UIViewController {
    
    //MARK: var/let

    private let hintLabel = UILabel()
    private let topContainerView = UIView()
    private let bottomContainerView = UIView()
    private let recordingNameLabel = UILabel()
    private let recordingDurationLabel = UILabel()
    private let recordButton = UIButton()
    private let listRecordingsTableView = UITableView()
    private let presenter = VoiceMemosPresenter()
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPresenter()
        setupSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        presenter.startRecording(!sender.isSelected)
    }
    
    //MARK: - flow funcs
    
    private func setupPresenter() {
        presenter.delegate = self
        presenter.checkPermission { [weak self] granted in
            guard let self = self else { return }
            
            if !granted {
                self.showAlert()
            }
        }
    }
    
    private func setupSubviews() {
        if presenter.countRecordings == .zero {
            hintLabel.isHidden = false
        } else {
            hintLabel.isHidden = true
        }
        view.backgroundColor = .black
        addSubviews()
    }
    
    private func addSubviews() {
        addContainerViews()
        addTitleLabel()
        addRecordingLabels()
        addRecordButton()
        addTableView()
        addHintLabel()
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
        let alpha = 0.2
        topContainerView.frame = view.frame
        topContainerView.frame.size.height /= 8
        view.addSubview(topContainerView)
        
        let height = 0.7
        let separatorView = UIView(
            frame: CGRect(
                x: .zero,
                y: topContainerView.frame.height - height,
                width: view.frame.width,
                height: height
            )
        )
        separatorView.backgroundColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(separatorView)
        
        bottomContainerView.frame = CGRect(
            x: .zero,
            y: view.frame.height - topContainerView.frame.height,
            width: view.frame.width,
            height: topContainerView.frame.height)
        bottomContainerView.backgroundColor = .lightGray.withAlphaComponent(alpha)
        view.addSubview(bottomContainerView)
    }
    
    private func addTitleLabel() {
        let offset = CGFloat(20)
        let titleLabel = UILabel(
            frame: CGRect(
                x: offset,
                y: topContainerView.frame.height - offset * 2,
                width: view.frame.width,
                height: offset
            )
        )
        titleLabel.text = .titleText
        titleLabel.font = .helveticaBolt
        titleLabel.textColor = .white
        view.addSubview(titleLabel)
    }
    
    private func addRecordingLabels() {
        let height = CGFloat(25)
        recordingDurationLabel.frame = CGRect(
            x: .zero,
            y: bottomContainerView.frame.origin.y - height,
            width: view.frame.width,
            height: height)
        recordingDurationLabel.textColor = .white
        recordingDurationLabel.textAlignment = .center
        recordingDurationLabel.isHidden = true
        view.addSubview(recordingDurationLabel)
        
        recordingNameLabel.frame = recordingDurationLabel.frame
        recordingNameLabel.frame.origin.y -= height
        recordingNameLabel.textColor = .white
        recordingNameLabel.textAlignment = .center
        recordingNameLabel.isHidden = true
        view.addSubview(recordingNameLabel)
    }
    
    private func addRecordButton() {
        let offset = CGFloat(2.5)
        let height = CGFloat(50)
        let borderView = UIView()
        borderView.frame = CGRect(
            x: bottomContainerView.frame.width / 2 - height / 2,
            y: bottomContainerView.frame.origin.y + height / 2.5,
            width: height,
            height: height
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
        listRecordingsTableView.register(
            RecordingTableViewCell.self,
            forCellReuseIdentifier: RecordingTableViewCell.identifier
        )
        listRecordingsTableView.delegate = self
        listRecordingsTableView.dataSource = self
        view.addSubview(listRecordingsTableView)
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
        
        controller.delegate = self
        controller.presenter = AudioPlayerPresenter(recording: recording)
        navigationController?.pushViewController(controller, animated: true)
    }
}

//MARK: - Extensions UITableViewDelegate, UITableViewDataSource

extension VoiceMemosViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.recordingsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else { return UITableViewCell() }
        
        cell.configure(with: presenter.recordingsArray[indexPath.item])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presenter.removeRecording(at: indexPath.item) {
                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        .heightForRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushAudioPlayerViewController(for: presenter.recordingsArray[indexPath.item])
    }
}

//MARK: - Extensions AudioPlayerViewControllerDelegate

extension VoiceMemosViewController: AudioPlayerViewControllerDelegate {
    
    func audioPlayerViewControllerClosed(withRemoved recording: Recording) {
        guard let index = presenter.getIndexRecording(recording) else { return }
        presenter.removeRecording(at: index) { [weak self] in
            guard let self = self else { return }
            
            self.listRecordingsTableView.reloadData()
        }
    }
}

extension VoiceMemosViewController: VoiceMemosPresenterDelegate {
    
    func recordingStarted(_ recordingName: String) {
        recordingNameLabel.text = recordingName
        recordingDurationLabel.text = .zeroTime
        toggleRecordButton()
        showRecordingLabels(recordButton.isSelected)
    }
    
    func recordingFinished() {
        listRecordingsTableView.reloadData()
    }
    
    func timerStarted(_ duration: String) {
        recordingDurationLabel.text = duration
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
