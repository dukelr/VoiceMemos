
import UIKit

final class RecordingTableViewCell: UITableViewCell {
    
    static let identifier = "RecordTableViewCell"
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    
    func configure(with recording: Recording) {
        addSubviews()
        backgroundColor = .clear
        selectionStyle = .none
        dateLabel.text = recording.date
        nameLabel.text = recording.name
        durationLabel.text = recording.duration
    }
    
    private func addSubviews() {
        let offset = CGFloat(10)
        let fontSize = Double(20)
        nameLabel.frame = CGRect(
            x: offset * 2,
            y: offset,
            width: frame.width,
            height: frame.height
        )
        nameLabel.frame.size.height /= 2
        nameLabel.textColor = .white
        nameLabel.font = .helveticaBolt?.withSize(fontSize)
        addSubview(nameLabel)
        
        let alpha = 0.5
        dateLabel.frame = nameLabel.frame
        dateLabel.frame.origin.y = nameLabel.frame.height
        dateLabel.frame.size.width /= 2
        dateLabel.textColor = .lightGray.withAlphaComponent(alpha)
        dateLabel.font = .helvetica
        addSubview(dateLabel)
        
        durationLabel.frame = dateLabel.frame
        durationLabel.frame.origin.x = dateLabel.frame.width - offset
        durationLabel.textAlignment = .right
        durationLabel.textColor = dateLabel.textColor
        durationLabel.font = .helvetica
        addSubview(durationLabel)
    }
}
