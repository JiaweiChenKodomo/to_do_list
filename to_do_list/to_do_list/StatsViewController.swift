//
//  StatsViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 10/13/21.
//

import UIKit

import Charts
import TinyConstraints

import Foundation

import RealmSwift

import SpriteKit

class StatsViewController: UIViewController, ChartViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, AxisValueFormatter {
    
    // IValueFormatter formats value ticks on the plot.
    var textField = UITextField()
    
    //var textFieldUp = UITextField()
    
    var textFieldMid = UITextField()
    
    var textFieldPeriod = UITextField()
    
    var startDatePicker = UIDatePicker()
    var endDatePicker = UIDatePicker()
    
    private let fromLabel = UILabel()
    private let toLabel = UILabel()
    
    var days = 14
    
    var wdays = 7
    
    var period = 7
    
    var yStart = 400
    var yOffset = 60
    
    var aboveAverageStreak = 0
    var workStreak = 0
    
    var streakTextField = UITextField()
    var workStreakTextField = UITextField()
    
    let emitterNode = SKEmitterNode(fileNamed: "snow1.sks")!
    
    var animationLoaded = false
    var addAnimation = false
    
    private let realm = try! Realm()
    
    var scrollView: UIScrollView!
    
    lazy var lineChart: LineChartView = {
        let chartView = LineChartView()
        // background color is necessary. 
        chartView.backgroundColor = .systemBackground
        
        chartView.animate(yAxisDuration: 0.5, easingOption: .easeInCubic)
        
        chartView.rightAxis.enabled = false
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        
        // Set legend here.
        chartView.legend.form = .default
        
        return chartView
    }()
    
    let format : DateFormatter = {
        let format = DateFormatter()
     
        // 2) Set the current timezone to .current, or America/Chicago.
        format.timeZone = .current
         
        // 3) Set the format of the altered date.
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return format
        
    }()
    
    private func addSnow() {
        let skView = SKView(frame: view.frame)
        skView.backgroundColor = .clear
        let scene = SKScene(size: view.frame.size)
        scene.backgroundColor = .clear
        skView.presentScene(scene)
        skView.isUserInteractionEnabled = false
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.addChild(emitterNode)
        emitterNode.position.y = scene.frame.maxY
        emitterNode.particlePositionRange.dx = scene.frame.width
        scrollView.addSubview(skView)
    }
    
//    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
//        return String(Int(value) % period)
//    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(Int(value) % period)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //dbg_gen_test_data()
        //Try loading data first.
        //setData(days: days, wdays: wdays)
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: todayStart)!
        }() // This is in fact today's end.

        let twoWeeksAgoEnd: Date = {
            let components = DateComponents(day: -days)
            return Calendar.current.date(byAdding: components, to: todayEnd)!
        }()
        setData3(startDay: twoWeeksAgoEnd, endDay: todayEnd, wdays: wdays)
        
        // Do any additional setup after loading the view.
        //
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.contentSize = CGSizeMake(view.bounds.size.width, CGFloat(yStart + yOffset * 6))
        view.addSubview(scrollView)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(lineChart)
        //scrollView.contentOffset = CGPoint(x: 0, y: 150)
        
        //view.addSubview(lineChart)
        //lineChart.centerInSuperview()
        lineChart.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.width)
        //lineChart.width(to: scrollView)
        lineChart.width(to: scrollView, multiplier: 0.95)
        lineChart.heightToWidth(of: view)
        
//        textFieldUp.delegate = self
//        textFieldUp.frame = CGRect(x: 15, y: yStart, width: 200, height: 50)
//        textFieldUp.borderStyle = UITextField.BorderStyle.roundedRect
//        textFieldUp.text = "Put # of records to plot"
//        //self.view.addSubview(textFieldUp)
//        scrollView.addSubview(textFieldUp)
        
        streakTextField.text = "Above-average streak: " + String(aboveAverageStreak)
        streakTextField.frame = CGRect(x: 30, y: yStart - 20, width: 320, height: 50)
        scrollView.addSubview(streakTextField)
        
        workStreakTextField.text = "Working streak: " + String(workStreak)
        workStreakTextField.frame = CGRect(x: 30, y: yStart + 20, width: 320, height: 50)
        scrollView.addSubview(workStreakTextField)
        
        fromLabel.text = "From (exclusive):"
        fromLabel.frame = CGRect(x: 30, y: yStart + yOffset, width: 320, height: 50)
        scrollView.addSubview(fromLabel)
        
        startDatePicker.setDate(Date().addingTimeInterval(-1209600), animated: true)
        startDatePicker.frame = CGRect(x: 165, y: yStart + yOffset, width: 320, height: 50)
        startDatePicker.contentHorizontalAlignment = .left
        startDatePicker.datePickerMode = UIDatePicker.Mode.date
        scrollView.addSubview(startDatePicker)
        
        toLabel.text = "To (inclusive):"
        toLabel.frame = CGRect(x: 30, y: yStart + 2 * yOffset, width: 320, height: 50)
        scrollView.addSubview(toLabel)
        
        endDatePicker.setDate(Date(), animated: true)
        endDatePicker.frame = CGRect(x: 165, y: yStart + 2 * yOffset, width: 320, height: 50)
        endDatePicker.contentHorizontalAlignment = .left
        endDatePicker.datePickerMode = UIDatePicker.Mode.date
        scrollView.addSubview(endDatePicker)
        
        textFieldMid.delegate = self
        textFieldMid.frame = CGRect(x: 15, y: yStart + 3 * yOffset, width: 200, height: 50)
        textFieldMid.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldMid.text = "Put window size"
        //self.view.addSubview(textFieldUp)
        scrollView.addSubview(textFieldMid)
        
        let plotBut = UIButton(type: .system)
        plotBut.frame = CGRect(x: 255, y: yStart + 4 * yOffset, width: 100, height: 50)
        plotBut.setTitle("Plot", for: .normal)
        plotBut.layer.borderWidth = 1.0
        plotBut.layer.borderColor = UIColor.blue.cgColor
        plotBut.addTarget(self, action: #selector(didTapPlot), for: .touchUpInside)
        //self.view.addSubview(plotBut)
        scrollView.addSubview(plotBut)
        
        textFieldPeriod.delegate = self
        textFieldPeriod.frame = CGRect(x: 15, y: yStart + yOffset * 4, width: 200, height: 50)
        textFieldPeriod.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldPeriod.text = "Put period of x-label"
        //self.view.addSubview(textFieldUp)
        scrollView.addSubview(textFieldPeriod)
        
        
        
        textField.delegate = self
        textField.frame = CGRect(x: 15, y: yStart + yOffset * 5, width: 200, height: 50)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.text = "Put # of records to keep"
        //self.view.addSubview(textField)
        scrollView.addSubview(textField)
        
        let claerBut = UIButton(type: .system)
        claerBut.frame = CGRect(x: 255, y: yStart + yOffset * 5, width: 100, height: 50)
        claerBut.setTitle("Delete", for: .normal)
        claerBut.layer.borderWidth = 1.0
        claerBut.layer.borderColor = UIColor.blue.cgColor
        claerBut.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        //self.view.addSubview(claerBut)
        scrollView.addSubview(claerBut)
        
        // Add animation based on performance
        if (addAnimation && !animationLoaded) {
            addSnow()
            animationLoaded = true
        }
        
        
        // Set zooming behavior
        scrollView.delegate = self
        //scrollView.minimumZoomScale = 0.1
        //scrollView.maximumZoomScale = 4.0
        //scrollView.zoomScale = 1.0
        setZoomScale()
        
    }
    
    override func viewWillLayoutSubviews() {
        setZoomScale()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        // zoom for chart view
        return lineChart
    }
    
    func setZoomScale() {
        let chartViewSize = lineChart.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / chartViewSize.width
        let heightScale = scrollViewSize.height / chartViewSize.height
            
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.zoomScale = 1.0
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //print("Begin!")
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    

    
    func setData3(startDay: Date, endDay: Date, wdays: Int) {
        // startDay is excluded. endDay is included.
        // day interval
        let todayStart = Calendar.current.startOfDay(for: endDay)
        let todayEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: todayStart)!
        }() // This is in fact today's end.
        
        
        let fourWeeksAgoEnd: Date = {
          let components = DateComponents(day: (2 - wdays))
          return Calendar.current.date(byAdding: components, to: Calendar.current.startOfDay(for: startDay))!
        }()
        
        let dayEval14 = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", fourWeeksAgoEnd, todayEnd)
        
        if dayEval14.isEmpty {
            let yVal = [ChartDataEntry(x: 0, y: 0.0)]
            
            let set1 = LineChartDataSet(entries: yVal, label: "Finished")
            set1.setColor(.blue)
            set1.setCircleColor(.blue)
            let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
            set2.setColor(.red)
            set2.setCircleColor(.red)
            
            let data = LineChartData(dataSets: [set1, set2])
            
            lineChart.data = data
            return
        }
        
        let days = Int(todayEnd.timeIntervalSince(startDay) / (3600*24))
        
//        print("***")
//        print(format.string(from: fourWeeksAgoEnd))
//        print(format.string(from: todayEnd))
//        print(days)
        
        var rawVal = [Double]()
        rawVal.reserveCapacity(days+wdays-1)
        var rawVal2 = [Double]()
        rawVal2.reserveCapacity(days+wdays-1)
        for _ in stride(from: 0, to: days+wdays-1, by: 1) {
            rawVal.append(0.0)
            rawVal2.append(0.0)
        }
        
        var yVal = [ChartDataEntry]()
        yVal.reserveCapacity(days)
        var yVal2 = [ChartDataEntry]()
        yVal2.reserveCapacity(days)
        var aveVal = [ChartDataEntry]()
        aveVal.reserveCapacity(days)
        var aveVal2 = [ChartDataEntry]()
        aveVal2.reserveCapacity(days)
        var aveVal3 = [ChartDataEntry]()
        aveVal3.reserveCapacity(days) // Equal-weight average
        var aveVal4 = [ChartDataEntry]()
        aveVal4.reserveCapacity(days) // Equal-weight average
        
        var weights = [Double]()
        var weights2 = [Double]()
        var sumWeight = 0.0
        weights.reserveCapacity(wdays)
        weights2.reserveCapacity(wdays)
        
        if (wdays == 1) {
            weights.append(1.0)
            weights2.append(1.0)
        } else {
            for aa in stride(from: 0, to: wdays, by: 1) {
                let a = 4.0 / (Double(wdays) - 1.0)
                let z = a * Double(aa) - 2.0
                weights.append(1.0 / (1.0 + exp(-z)))
                sumWeight += 1.0 / (1.0 + exp(-z))
                weights2.append(1.0 / Double(wdays))
            }
            
            for aa in stride(from: 0, to: wdays, by: 1) {
                weights[aa] /= sumWeight
            }
        }
        
        // rawVal and rawVal2 are already zero. Now hash all data in dayEval to the corresponding slots.
        for dayEval in dayEval14 {
            
            let diffTime = Calendar.current.dateComponents([.day, .hour, .minute], from: fourWeeksAgoEnd, to: Calendar.current.startOfDay(for: dayEval.date))
            let index = diffTime.day ?? 0
            
//            print("***")
//            print(days)
//            print(wdays)
//            print(format.string(from: fourWeeksAgoEnd))
//            print(format.string(from: dayEval.date))
//            print(diffTime.day)
            
            rawVal[index] += dayEval.tot_time
            rawVal2[index] += dayEval.tot_finish
            
        }
        
        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
            yVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa]))
//            print(rawVal[aa])
            yVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa]))
            aveVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa] * weights.last!))
            aveVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa] * weights.last!))
            aveVal3.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa] * weights2.last!))
            aveVal4.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa] * weights2.last!))
        } //Have to append to initialize the data.
        
        //print(weights)
        for aa in stride(from: 0, to: wdays - 1, by: 1) {
            for bb in 0..<min(aa+1, days) {
                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
                aveVal3[bb].y += rawVal[aa] * weights2[aa - bb]
                aveVal4[bb].y += rawVal2[aa] * weights2[aa - bb]
            }
        }
        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
            for bb in (aa-wdays+1+1)..<min(aa+1, days) {
                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
                aveVal3[bb].y += rawVal[aa] * weights2[aa - bb]
                aveVal4[bb].y += rawVal2[aa] * weights2[aa - bb]
            }
            
        }
              
        // Plot here.
        let set2 = LineChartDataSet(entries: yVal2, label: "Finished")
        set2.setColor(UIColor(red: 0.384, green: 0.792, blue: 0.314, alpha: 1))
        //set2.setCircleColor(.blue)
        set2.drawCirclesEnabled = false
        
        let set1 = LineChartDataSet(entries: yVal, label: "Time Spent")
        set1.setColor(UIColor(red: 0.831, green: 0.165, blue: 0.204, alpha: 1))
        //set1.setCircleColor(.red)
        set1.drawCirclesEnabled = false
        
        let set3 = LineChartDataSet(entries: aveVal, label: "Weighed Time Spent")
        set3.setColor(UIColor(red: 0.831, green: 0.165, blue: 0.204, alpha: 0.6))
        set3.lineDashLengths = [5]
        set3.lineWidth = 2.0
        set3.drawCirclesEnabled = false
        
        let set4 = LineChartDataSet(entries: aveVal2, label: "Weighed Finished")
        set4.setColor(UIColor(red: 0.384, green: 0.792, blue: 0.314, alpha: 0.6))
        set4.lineDashLengths = [5]
        set4.lineWidth = 2.0
        set4.drawCirclesEnabled = false
        
        let set5 = LineChartDataSet(entries: aveVal3, label: "Average Time Spent")
        set5.setColor(UIColor(red: 0.831, green: 0.165, blue: 0.204, alpha: 0.4))
        //set5.lineDashLengths = [20]
        set5.drawCirclesEnabled = false
        set5.lineWidth = 3.0
        
        let set6 = LineChartDataSet(entries: aveVal4, label: "Average Finished")
        set6.setColor(UIColor(red: 0.384, green: 0.792, blue: 0.314, alpha: 0.4))
        set6.drawCirclesEnabled = false
        set6.lineWidth = 3.0
        
        if ((yVal.last!.y > aveVal.last!.y || (yVal2.last!.y > aveVal2.last!.y)) && !animationLoaded) {
            addAnimation = true
        }
        
        aboveAverageStreak = 0
        workStreak = yVal.count - (yVal.lastIndex(where: {$0.y == 0}) ?? -1) - 1
        while (!aveVal.isEmpty) && (aveVal.last!.y <= yVal.last!.y || aveVal2.last!.y <= yVal2.last!.y) {
            aveVal.removeLast()
            yVal.removeLast()
            aveVal2.removeLast()
            yVal2.removeLast()
            aboveAverageStreak += 1
        }
        
        let data = LineChartData(dataSets: [set1, set2, set3, set4, set5, set6])
        
        lineChart.xAxis.valueFormatter = self
        lineChart.data = data
        
        self.streakTextField.text = "Above-average streak: " + String(aboveAverageStreak)
        self.workStreakTextField.text = "Working streak: " + String(workStreak)
    }
    
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
    
//    func dbg_gen_test_data() {
//        let todayStart = Calendar.current.startOfDay(for: Date())
//        let yesterday: Date = {
//            let components = DateComponents(day: -1, second: -1)
//            return Calendar.current.date(byAdding: components, to: todayStart)!
//        }()
//        let dayBeforeYesterday: Date = {
//            let components = DateComponents(day: -2, second: -1)
//            return Calendar.current.date(byAdding: components, to: todayStart)!
//        }()
//        let twoDaysBeforeYesterday: Date = {
//            let components = DateComponents(day: -2, second: -1)
//            return Calendar.current.date(byAdding: components, to: todayStart)!
//        }()
//        realm.beginWrite()
//        let newDayEval = dailyPerfEval()
//        newDayEval.tot_time = 10
//        newDayEval.tot_finish = 4
//        newDayEval.date = yesterday
//        realm.add(newDayEval)
//        let newDayEval2 = dailyPerfEval()
//        newDayEval2.tot_time = 10
//        newDayEval2.tot_finish = 4
//        newDayEval2.date = dayBeforeYesterday
//        realm.add(newDayEval2)
//        let newDayEval3 = dailyPerfEval()
//        newDayEval3.tot_time = 10
//        newDayEval3.tot_finish = 4
//        newDayEval3.date = twoDaysBeforeYesterday
//        realm.add(newDayEval3)
//
//        try! realm.commitWrite()
//    }
    
    @objc private func didTapClear() {
        // will delete records prior to predetermined date.
        
        let daysToKeep = Int(textField.text!) ?? 140
        
        // day interval
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        let twoWeeksAgoEnd: Date = {
          let components = DateComponents(day: -daysToKeep, second: -1)
          return Calendar.current.date(byAdding: components, to: todayStart)!
        }()
        
        let myItem = realm.objects(dailyPerfEval.self).filter("date <= %@", twoWeeksAgoEnd)
        
        let alert = UIAlertController(title: "Delete old records?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
            self.realm.beginWrite()
            self.realm.delete(myItem)
            try! self.realm.commitWrite()}))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)

        

        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func didTapPlot() {
        // will delete records prior to predetermined date.
        
        //let daysToPlot = Int(textFieldUp.text!) ?? 14
        
        var startDay = startDatePicker.date
        let endDay = endDatePicker.date
        
        if (endDay.timeIntervalSince(startDay) < 86400) {
            startDay = endDay.addingTimeInterval(-86400)
        } // At least one day prior to endDay.
        
        let window = Int(textFieldMid.text!) ?? 7
        period = Int(textFieldPeriod.text!) ?? 7
        if period <= 0 {
            period = 100
        }
        
        //setData(days: daysToPlot, wdays: window)
        //setData2(startDay: startDay, endDay: endDay, wdays: window)
        setData3(startDay: startDay, endDay: endDay, wdays: window)
        
    }
    
//    func setData(days: Int, wdays: Int) {
//
//        if days <= 0 || wdays <= 0 {
//            return
//        }
//
//        // day interval
//        let todayStart = Calendar.current.startOfDay(for: Date())
//        let todayEnd: Date = {
//            let components = DateComponents(day: 1, second: -1)
//            return Calendar.current.date(byAdding: components, to: todayStart)!
//        }() // This is in fact today's end.
//
//        let twoWeeksAgoEnd: Date = {
//          let components = DateComponents(day: -days)
//          return Calendar.current.date(byAdding: components, to: todayEnd)!
//        }()
//
//        let fourWeeksAgoEnd: Date = {
//          let components = DateComponents(day: (-days - wdays + 1))
//          return Calendar.current.date(byAdding: components, to: todayEnd)!
//        }()
//
//        //print("***")
////        print(format.string(from: twoWeeksAgoEnd))
//        //print(format.string(from: fourWeeksAgoEnd))
//        //print(format.string(from: todayEnd))
//
//        let dayEval14 = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", fourWeeksAgoEnd, todayEnd)
//
//        if dayEval14.isEmpty {
//            let yVal = [ChartDataEntry(x: 0, y: 0.0)]
//
//            let set1 = LineChartDataSet(entries: yVal, label: "Finished")
//            set1.setColor(.blue)
//            set1.setCircleColor(.blue)
//            let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
//            set2.setColor(.red)
//            set2.setCircleColor(.red)
//
//            let set3 = LineChartDataSet(entries: yVal, label: "Average Time Spent")
//            set3.setColor(.red)
//            set3.lineDashLengths = [5]
//            set3.drawCirclesEnabled = false
//            let set4 = LineChartDataSet(entries: yVal, label: "Average Finished")
//            set4.setColor(.blue)
//            set4.lineDashLengths = [5]
//            set4.drawCirclesEnabled = false
//
//            let data = LineChartData(dataSets: [set1, set2, set3, set4])
//
//            lineChart.data = data
//            return
//        }
//
//        var rawVal = [Double]()
//        rawVal.reserveCapacity(days+wdays-1)
//        var rawVal2 = [Double]()
//        rawVal2.reserveCapacity(days+wdays-1)
//
//        var yVal = [ChartDataEntry]()
//        yVal.reserveCapacity(days)
//        var yVal2 = [ChartDataEntry]()
//        yVal2.reserveCapacity(days)
//        var aveVal = [ChartDataEntry]()
//        aveVal.reserveCapacity(days)
//        var aveVal2 = [ChartDataEntry]()
//        aveVal2.reserveCapacity(days)
//
//        var weights = [Double]()
//        var sumWeight = 0.0
//        weights.reserveCapacity(wdays)
//
//        if (wdays == 1) {
//            weights.append(1.0)
//        } else {
//            for aa in stride(from: 0, to: wdays, by: 1) {
//                let a = 4.0 / (Double(wdays) - 1.0)
//                let z = a * Double(aa) - 2.0
//                weights.append(1.0 / (1.0 + exp(-z)))
//                sumWeight += 1.0 / (1.0 + exp(-z))
//            }
//
//            for aa in stride(from: 0, to: wdays, by: 1) {
//                weights[aa] /= sumWeight
//            }
//        }
//
//        var aa = 0.0
//        var prevTime = Calendar.current.startOfDay(for:fourWeeksAgoEnd)
//        //print("##########")
//        for dayEval in dayEval14 {
//            //print(format.string(from: dayEval.date))
//            //print(dayEval.tot_time)
//            // add n zero days if current dayEval is more than 24 hours after the previous dayVal. Do this first.
//            let diffTime = Calendar.current.dateComponents([.day, .hour, .minute], from: prevTime, to: Calendar.current.startOfDay(for: dayEval.date))
//            if diffTime.day ?? 0 > 1 {
//                // add n zero days where n is the no. of difference in days.
//                var bb = 1 // Start with 1, because, e.g., records are on 11 and 14, then only need to pad 2.
//                while bb < diffTime.day! {
//                    //print(diffTime.day!)
//                    rawVal.append(0.0)
//                    rawVal2.append(0.0)
//                    aa += 1.0
//                    bb += 1
//                }
//            }
//
//            rawVal.append(dayEval.tot_time)
//            rawVal2.append(dayEval.tot_finish)
//            aa += 1.0
//
//            prevTime = Calendar.current.startOfDay(for: dayEval.date)
//
//        } //raw data are zero-paded.
//        // The above step is not working for zeros at the end. So add zeros at the end.
//        while rawVal.count < days+wdays-1 {
//            rawVal.append(0.0)
//            rawVal2.append(0.0)
//        }
//
//        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
//            yVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa]))
//            //print(rawVal[aa])
//            yVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa]))
//            aveVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa] * weights.last!))
//            aveVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa] * weights.last!))
//        } //Have to append to initialize the data.
//
//        //print(weights)
//        for aa in stride(from: 0, to: wdays - 1, by: 1) {
//            for bb in 0..<min(aa+1, days) {
//                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
//                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
//            }
//        }
//        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
//            for bb in (aa-wdays+1+1)..<min(aa+1, days) {
//                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
//                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
//            }
//
//        }
//
//
//        let set1 = LineChartDataSet(entries: yVal2, label: "Finished")
//        set1.setColor(.blue)
//        set1.setCircleColor(.blue)
//        let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
//        set2.setColor(.red)
//        set2.setCircleColor(.red)
//
//        let set3 = LineChartDataSet(entries: aveVal, label: "Average Time Spent")
//        set3.setColor(.red)
//        set3.lineDashLengths = [5]
//        set3.drawCirclesEnabled = false
//        let set4 = LineChartDataSet(entries: aveVal2, label: "Average Finished")
//        set4.setColor(.blue)
//        set4.lineDashLengths = [5]
//        set4.drawCirclesEnabled = false
//
//        if ((yVal.last!.y > aveVal.last!.y || (yVal2.last!.y > aveVal2.last!.y)) && !animationLoaded) {
//            addAnimation = true
//        }
//
//        let data = LineChartData(dataSets: [set1, set2, set3, set4])
//
//        lineChart.xAxis.valueFormatter = self
//        lineChart.data = data
//    }
    
//    func setData2(startDay: Date, endDay: Date, wdays: Int) {
//
//        // day interval
//        let todayStart = Calendar.current.startOfDay(for: endDay)
//        let todayEnd: Date = {
//            let components = DateComponents(day: 1, second: -1)
//            return Calendar.current.date(byAdding: components, to: todayStart)!
//        }() // This is in fact today's end.
//
//
//        let fourWeeksAgoEnd: Date = {
//          let components = DateComponents(day: (1 - wdays))
//          return Calendar.current.date(byAdding: components, to: Calendar.current.startOfDay(for: startDay))!
//        }()
//
//        let dayEval14 = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", fourWeeksAgoEnd, todayEnd)
//
//        if dayEval14.isEmpty {
//            let yVal = [ChartDataEntry(x: 0, y: 0.0)]
//
//            let set1 = LineChartDataSet(entries: yVal, label: "Finished")
//            set1.setColor(.blue)
//            set1.setCircleColor(.blue)
//            let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
//            set2.setColor(.red)
//            set2.setCircleColor(.red)
//
//            let set3 = LineChartDataSet(entries: yVal, label: "Average Time Spent")
//            set3.setColor(.red)
//            set3.lineDashLengths = [5]
//            set3.drawCirclesEnabled = false
//            let set4 = LineChartDataSet(entries: yVal, label: "Average Finished")
//            set4.setColor(.blue)
//            set4.lineDashLengths = [5]
//            set4.drawCirclesEnabled = false
//
//            let data = LineChartData(dataSets: [set1, set2, set3, set4])
//
//            lineChart.data = data
//            return
//        }
//
//        let days = Int(endDay.timeIntervalSince(startDay) / (3600*24))
//
////        print("***")
////        print(format.string(from: fourWeeksAgoEnd))
////        print(format.string(from: todayEnd))
////        print(days)
//
//        var rawVal = [Double]()
//        rawVal.reserveCapacity(days+wdays-1)
//        var rawVal2 = [Double]()
//        rawVal2.reserveCapacity(days+wdays-1)
//
//        var yVal = [ChartDataEntry]()
//        yVal.reserveCapacity(days)
//        var yVal2 = [ChartDataEntry]()
//        yVal2.reserveCapacity(days)
//        var aveVal = [ChartDataEntry]()
//        aveVal.reserveCapacity(days)
//        var aveVal2 = [ChartDataEntry]()
//        aveVal2.reserveCapacity(days)
//
//        var weights = [Double]()
//        var sumWeight = 0.0
//        weights.reserveCapacity(wdays)
//
//        if (wdays == 1) {
//            weights.append(1.0)
//        } else {
//            for aa in stride(from: 0, to: wdays, by: 1) {
//                let a = 4.0 / (Double(wdays) - 1.0)
//                let z = a * Double(aa) - 2.0
//                weights.append(1.0 / (1.0 + exp(-z)))
//                sumWeight += 1.0 / (1.0 + exp(-z))
//            }
//
//            for aa in stride(from: 0, to: wdays, by: 1) {
//                weights[aa] /= sumWeight
//            }
//        }
//
//        var aa = 0.0
//        var prevTime = Calendar.current.startOfDay(for:fourWeeksAgoEnd)
//        //print("##########")
//        for dayEval in dayEval14 {
//            //print(format.string(from: dayEval.date))
//            //print(dayEval.tot_time)
//            // add n zero days if current dayEval is more than 24 hours after the previous dayVal. Do this first.
//            let diffTime = Calendar.current.dateComponents([.day, .hour, .minute], from: prevTime, to: Calendar.current.startOfDay(for: dayEval.date))
//            if diffTime.day ?? 0 > 1 {
//                // add n zero days where n is the no. of difference in days.
//                var bb = 1 // Start with 1, because, e.g., records are on 11 and 14, then only need to pad 2.
//                while bb < diffTime.day! {
//                    //print(diffTime.day!)
//                    rawVal.append(0.0)
//                    rawVal2.append(0.0)
//                    aa += 1.0
//                    bb += 1
//                }
//            }
//
//            rawVal.append(dayEval.tot_time)
//            rawVal2.append(dayEval.tot_finish)
//            aa += 1.0
//
//            prevTime = Calendar.current.startOfDay(for: dayEval.date)
//
//        } //raw data are zero-paded.
//        // The above step is not working for zeros at the end. So add zeros at the end.
//        while rawVal.count < days+wdays-1 {
//            rawVal.append(0.0)
//            rawVal2.append(0.0)
//        }
//
//        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
//            yVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa]))
//            //print(rawVal[aa])
//            yVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa]))
//            aveVal.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal[aa] * weights.last!))
//            aveVal2.append(ChartDataEntry(x: Double(aa - wdays + 1), y: rawVal2[aa] * weights.last!))
//        } //Have to append to initialize the data.
//
//        //print(weights)
//        for aa in stride(from: 0, to: wdays - 1, by: 1) {
//            for bb in 0..<min(aa+1, days) {
//                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
//                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
//            }
//        }
//        for aa in stride(from: wdays - 1, to: days + wdays - 1, by: 1) {
//            for bb in (aa-wdays+1+1)..<min(aa+1, days) {
//                aveVal[bb].y += rawVal[aa] * weights[aa - bb]
//                aveVal2[bb].y += rawVal2[aa] * weights[aa - bb]
//            }
//
//        }
//
//
//        let set1 = LineChartDataSet(entries: yVal2, label: "Finished")
//        set1.setColor(.blue)
//        set1.setCircleColor(.blue)
//        let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
//        set2.setColor(.red)
//        set2.setCircleColor(.red)
//
//        let set3 = LineChartDataSet(entries: aveVal, label: "Average Time Spent")
//        set3.setColor(.red)
//        set3.lineDashLengths = [5]
//        set3.drawCirclesEnabled = false
//        let set4 = LineChartDataSet(entries: aveVal2, label: "Average Finished")
//        set4.setColor(.blue)
//        set4.lineDashLengths = [5]
//        set4.drawCirclesEnabled = false
//
//        if ((yVal.last!.y > aveVal.last!.y || (yVal2.last!.y > aveVal2.last!.y)) && !animationLoaded) {
//            addAnimation = true
//        }
//
//        let data = LineChartData(dataSets: [set1, set2, set3, set4])
//
//        lineChart.xAxis.valueFormatter = self
//        lineChart.data = data
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
