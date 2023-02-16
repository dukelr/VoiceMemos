
import UIKit

class RecordingTableViewCellDelegate {
}

class RecordingTableViewCell: UITableViewCell {
    
    static let identifier = "RecordTableViewCell"
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with recording: Recording) {
        dateLabel.text = recording.date
        nameLabel.text = recording.name
        durationLabel.text = recording.duration
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        addSubviews()
    }
    
    private func addSubviews() {
        let offset = CGFloat(15)
        let fontSize = 20.0
        nameLabel.frame = CGRect(
            x: offset,
            y: offset,
            width: frame.width,
            height: frame.height
        )
        nameLabel.frame.size.height /= 2
        nameLabel.textColor = .white
        nameLabel.font = .helveticaBolt?.withSize(fontSize)
        addSubview(nameLabel)
        
        let alpha = 0.5
        dateLabel.frame = CGRect(
            x: nameLabel.frame.origin.x,
            y: nameLabel.frame.height + offset,
            width: frame.width / 2,
            height: nameLabel.frame.height
        )
        dateLabel.textColor = .lightGray.withAlphaComponent(alpha)
        dateLabel.font = .helvetica
        addSubview(dateLabel)
        
        durationLabel.frame = dateLabel.frame
        durationLabel.frame.origin.x = durationLabel.frame.width * 1.5
        durationLabel.textAlignment = .right
        durationLabel.textColor = dateLabel.textColor
        durationLabel.font = .helvetica
        addSubview(durationLabel)
    }
}
