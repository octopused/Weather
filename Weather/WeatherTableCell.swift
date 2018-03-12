//
//  WeatherTableCell.swift
//  Weather
//
//  Created by RuslanKa on 09.03.2018.
//

import UIKit

class WeatherTableCell: UITableViewCell {

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbDetail: UILabel!
    
    public var weatherInfo: WeatherInfo? {
        didSet { setUI() }
    }
    public var date: Date? {
        didSet { setUI() }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setUI() {
        if let date = date, let weatherInfo = weatherInfo {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let dateText = dateFormatter.string(from: date)
            
            lbTitle.text = "\(dateText) hr"
            lbDetail.text = weatherInfo.description
        }
    }
}
