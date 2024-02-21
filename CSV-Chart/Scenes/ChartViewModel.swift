import UIKit

struct Chart: Identifiable {
    var time: String = ""
    var hrValue: String = ""
    let id: UUID = UUID()
    
    init(raw: [String]) {
        time = raw[0]
        hrValue = raw[1]
    }
}
