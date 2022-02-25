//
//  StatsViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 10/13/21.
//

import UIKit

import Charts
import TinyConstraints

import RealmSwift

class StatsViewController: UIViewController, ChartViewDelegate, UITextFieldDelegate {
    
    var textField = UITextField()
    
    var textFieldUp = UITextField()
    
    var days = 14
    
    private let realm = try! Realm()
    
    lazy var lineChart: LineChartView = {
        let chartView = LineChartView()
        // background color is necessary. 
        chartView.backgroundColor = .systemBackground
        
        chartView.animate(yAxisDuration: 0.5, easingOption: .easeInCubic)
        
        chartView.rightAxis.enabled = false
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //dbg_gen_test_data()
        //Try loading data first.
        setData(days: days)
        
        // Do any additional setup after loading the view.
        view.addSubview(lineChart)
        lineChart.centerInSuperview()
        lineChart.width(to: view)
        lineChart.heightToWidth(of: view)
        
        let claerBut = UIButton(type: .system)
        claerBut.frame = CGRect(x: 255, y: 700, width: 100, height: 50)
        claerBut.setTitle("Delete", for: .normal)
        claerBut.layer.borderWidth = 1.0
        claerBut.layer.borderColor = UIColor.blue.cgColor
        claerBut.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        self.view.addSubview(claerBut)
        
        let plotBut = UIButton(type: .system)
        plotBut.frame = CGRect(x: 255, y: 600, width: 100, height: 50)
        plotBut.setTitle("Plot", for: .normal)
        plotBut.layer.borderWidth = 1.0
        plotBut.layer.borderColor = UIColor.blue.cgColor
        plotBut.addTarget(self, action: #selector(didTapPlot), for: .touchUpInside)
        self.view.addSubview(plotBut)
        
        textField.delegate = self
        textField.frame = CGRect(x: 15, y: 700, width: 200, height: 50)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.text = "Put # of records to keep"
        self.view.addSubview(textField)
        
        textFieldUp.delegate = self
        textFieldUp.frame = CGRect(x: 15, y: 600, width: 200, height: 50)
        textFieldUp.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldUp.text = "Put # of records to plot"
        self.view.addSubview(textFieldUp)
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
    
    func setData(days: Int) {
        
        if days <= 0 {
            return
        }
        
        // day interval
        let todayStart = Calendar.current.startOfDay(for: Date())
        let yesterday: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: todayStart)!
        }() // This is in fact today's end.
        
        let twoWeeksAgoEnd: Date = {
          let components = DateComponents(day: -days)
          return Calendar.current.date(byAdding: components, to: yesterday)!
        }()
        
//        print("***")
//        print(format.string(from: twoWeeksAgoEnd))
//        print(format.string(from: yesterday))
        
        let dayEval14 = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", twoWeeksAgoEnd, yesterday)
        
        if dayEval14.isEmpty {
            let yVal = [ChartDataEntry(x: 0, y: 0.0)]
            
            let set1 = LineChartDataSet(entries: yVal, label: "Finished")
            set1.setColor(.blue)
            set1.setCircleColor(.blue)
            let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
            set2.setColor(.red)
            set2.setCircleColor(.red)
            
            let set3 = LineChartDataSet(entries: yVal, label: "Average Time Spent")
            set3.setColor(.red)
            set3.lineDashLengths = [5]
            set3.drawCirclesEnabled = false
            let set4 = LineChartDataSet(entries: yVal, label: "Average Finished")
            set4.setColor(.blue)
            set4.lineDashLengths = [5]
            set4.drawCirclesEnabled = false
            
            let data = LineChartData(dataSets: [set1, set2, set3, set4])
            
            lineChart.data = data
            return
        }
        
        var yVal = [ChartDataEntry]()
        yVal.reserveCapacity(days)
        var yVal2 = [ChartDataEntry]()
        yVal2.reserveCapacity(days)
        var aa = 0.0
        var prevTime = Calendar.current.startOfDay(for:twoWeeksAgoEnd)
//        print("##########")
        for dayEval in dayEval14 {
//            print(format.string(from: dayEval.date))
//            print(dayEval.tot_time)
            // add n zero days if current dayEval is more than 24 hours after the previous dayVal. Do this first.
            let diffTime = Calendar.current.dateComponents([.day, .hour, .minute], from: prevTime, to: Calendar.current.startOfDay(for: dayEval.date))
            if diffTime.day ?? 0 > 1 {
                // add n zero days where n is the no. of difference in days.
                var bb = 1 // Start with 1, because, e.g., records are on 11 and 14, then only need to pad 2.
                while bb < diffTime.day! {
                    yVal.append(ChartDataEntry(x: aa, y: 0.0))
                    yVal2.append(ChartDataEntry(x: aa, y: 0.0))
                    aa += 1.0
                    bb += 1
                }
            }
            
            yVal.append(ChartDataEntry(x: aa, y: dayEval.tot_time))
            yVal2.append(ChartDataEntry(x: aa, y: dayEval.tot_finish))
            aa += 1.0
            
            prevTime = Calendar.current.startOfDay(for: dayEval.date)
            
        }
        
        let dayNo = yVal.count
        
        var aveFinished = 0.0
        var aveSpent = 0.0
        
        
        for chartData in yVal {
            aveSpent += chartData.y
        }
        for chartData in yVal2 {
            aveFinished += chartData.y
        }
        
        aveSpent /= Double(dayNo)
        aveFinished /= Double(dayNo)
        
        var yAveSpent = [ChartDataEntry]()
        yAveSpent.reserveCapacity(2)
        yAveSpent.append(ChartDataEntry(x: 0, y: aveSpent))
        yAveSpent.append(ChartDataEntry(x: Double(dayNo - 1), y: aveSpent))
        var yAveFinished = [ChartDataEntry]()
        yAveFinished.reserveCapacity(2)
        yAveFinished.append(ChartDataEntry(x: 0, y: aveFinished))
        yAveFinished.append(ChartDataEntry(x: Double(dayNo - 1), y: aveFinished))
        
        
        let set1 = LineChartDataSet(entries: yVal2, label: "Finished")
        set1.setColor(.blue)
        set1.setCircleColor(.blue)
        let set2 = LineChartDataSet(entries: yVal, label: "Time Spent")
        set2.setColor(.red)
        set2.setCircleColor(.red)
        
        let set3 = LineChartDataSet(entries: yAveSpent, label: "Average Time Spent")
        set3.setColor(.red)
        set3.lineDashLengths = [5]
        set3.drawCirclesEnabled = false
        let set4 = LineChartDataSet(entries: yAveFinished, label: "Average Finished")
        set4.setColor(.blue)
        set4.lineDashLengths = [5]
        set4.drawCirclesEnabled = false
        
        
        
        let data = LineChartData(dataSets: [set1, set2, set3, set4])
        
        lineChart.data = data
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
//
//        let newDayEval2 = dailyPerfEval()
//        newDayEval2.tot_time = 10
//        newDayEval2.tot_finish = 4
//        newDayEval2.date = dayBeforeYesterday
//        realm.add(newDayEval2)
//
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
        
        let daysToKeep = Int(textField.text!) ?? 14
        
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
        
        let daysToPlot = Int(textFieldUp.text!) ?? 14
        
        setData(days: daysToPlot)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
