import UIKit
import Charts

final class DateValueFormatter: IndexAxisValueFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    let axisDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    class func date(from dateString: String) -> Date {
        return dateFormatter.date(from: dateString) ?? Date()
    }

    override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return axisDateFormat.string(from: date)
    }
}
