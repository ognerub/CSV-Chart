import UIKit
import Charts

final class ChartViewController: UIViewController, ChartViewDelegate {
    
    private var dataEntries: [(date: String, value: Double)] = []
    
    private lazy var lineChart: LineChartView = {
        let chart = LineChartView()
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .blueColor
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.setTitle("Add", for: .normal)
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.text = "Please add CSV file"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var mainImageView: UIImageView = {
        let image = UIImage.mainImage
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        switch orientation {
        case .portrait:
            configureConstraintsPortrait()
        case .landscapeLeft:
            configureConstraintsLanscape()
        case .landscapeRight:
            configureConstraintsLanscape()
        default:
            configureConstraintsPortrait()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLineChart()
        updateChartWithData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            removeAllContent()
            configureConstraintsLanscape()
            reloadChart()
        } else {
            removeAllContent()
            configureConstraintsPortrait()
            reloadChart()
        }
    }
    
    private func removeAllContent() {
        [lineChart,button,label,mainImageView].forEach {
            $0.removeFromSuperview()
        }
    }
    
    @objc
    private func buttonTapped() {
        loadCSV()
    }
    
    private func reloadChart() {
        lineChart.zoomToCenter(scaleX: 0, scaleY: 0)
        lineChart.invalidateIntrinsicContentSize()
    }

    func configureLineChart() {
        lineChart.xAxis.valueFormatter = DateValueFormatter() // Custom formatter for X-axis dates
        lineChart.xAxis.labelPosition = .bottom
        lineChart.rightAxis.enabled = false
    }

    func updateChartWithData() {
        var chartDataEntries: [ChartDataEntry] = []

        dataEntries.forEach { dataEntry in
            let date = DateValueFormatter.date(from: dataEntry.date)
            let chartEntry = ChartDataEntry(x: date.timeIntervalSince1970, y: dataEntry.value)
            chartDataEntries.append(chartEntry)
        }

        let dataSet = LineChartDataSet(entries: chartDataEntries, label: "hr value")
        dataSet.colors = [NSUIColor.blue] // Set line color

        let data = LineChartData(dataSet: dataSet)
        lineChart.data = data
    }
}

// MARK: - UIDocumentPickerDelegate
extension ChartViewController: UIDocumentPickerDelegate {
    private func loadCSV() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text", "public.data"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // TODO: - maybe show alert?
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        do {
            let data = try String(contentsOf: selectedURL, encoding: .utf8)
            let csvToStruct = parseCSVData(data: data)
            var yValues: [Double] = []
            csvToStruct.forEach { value in
                    let date = value.time
                    let hrValue = Double(value.hrValue)
                    dataEntries.append((date, hrValue ?? 0))
                    yValues.append(hrValue ?? 0)
            }
            guard let minimumValue = yValues.min() else { return }
            lineChart.leftAxis.axisMinimum = minimumValue
            updateChartWithData()
            mainImageView.removeFromSuperview()
        } catch {
            // TODO: - maybe show alert?
        }
    }
    
    private func parseCSVData(data: String) -> [Chart] {
        var csvToStruct = [Chart]()
        var rows = data.components(separatedBy: "\n")
        rows.removeFirst()
        rows.forEach { row in
            let csvColumns = row.components(separatedBy: ";")
            let chartStruct = Chart(raw: csvColumns)
            if chartStruct.time != "" {
                csvToStruct.append(chartStruct)
            }
        }
        return csvToStruct
    }
}

private extension ChartViewController {
    func configureConstraintsPortrait() {
        view.addSubview(lineChart)
        NSLayoutConstraint.activate([
            lineChart.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            lineChart.heightAnchor.constraint(equalToConstant: view.frame.width - 20),
            lineChart.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            lineChart.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: lineChart.bottomAnchor, constant: 10),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: lineChart.topAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.widthAnchor.constraint(equalToConstant: 200),
            label.heightAnchor.constraint(equalToConstant: 50)
        ])
        if dataEntries.isEmpty {
            configureMainImageConstraints()
        }
    }
    
    func configureMainImageConstraints() {
        view.addSubview(mainImageView)
        NSLayoutConstraint.activate([
            mainImageView.centerXAnchor.constraint(equalTo: lineChart.centerXAnchor),
            mainImageView.centerYAnchor.constraint(equalTo: lineChart.centerYAnchor)
        ])
    }

    func configureConstraintsLanscape() {
        view.addSubview(lineChart)
        NSLayoutConstraint.activate([
            lineChart.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            lineChart.heightAnchor.constraint(equalToConstant: view.frame.height - 20),
            lineChart.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            lineChart.widthAnchor.constraint(equalToConstant: view.frame.height - 20)
        ])

        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: lineChart.trailingAnchor, constant: 10),
            button.centerYAnchor.constraint(equalTo: lineChart.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -50)
        ])
        if dataEntries.isEmpty {
            configureMainImageConstraints()
        }
    }
}
