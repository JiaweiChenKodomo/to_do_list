//
//  ViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 10/10/21.
//

import RealmSwift
import UIKit
import Foundation
/*
 - show to do list items
 - to add new items
 - to show previous items
 
 - item
 - due date
 */

class checkListItem: Object {
    @objc dynamic var item: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var budget: Double = 0.0
    @objc dynamic var checkIn: Bool = false
    @objc dynamic var finished: Bool = false
    @objc dynamic var startTime: Date = Date()
    @objc dynamic var timeSpent: TimeInterval = 0.0
    
    
//    let title: String
//    var isChecked: Bool = false
//
//    init(title: String) {
//        self.title = title
//    }
}

class dailyPerfEval: Object {
    @objc dynamic var tot_finish: Double = 0.0
    @objc dynamic var tot_time: Double = 0.0
    @objc dynamic var date: Date = Date()
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var table: UITableView!
    //@IBOutlet var scroll: UIScrollView!
    
    private let realm = try! Realm()
    
    private let dateFormatter = DateFormatter()
    
    private var data = [checkListItem]()
    
    private var perfData = [dailyPerfEval]()
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Read the data in Realm
        data = realm.objects(checkListItem.self).map({ $0 })
        data = data.sorted(by: {$0.date<$1.date}) //Now list ordered by deadline ASC
        
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.delegate = self
        table.dataSource = self
        
        // Updates every 0.5 minute.
        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        
//        let refreshBut = UIButton(type: .system)
//        refreshBut.frame = CGRect(x: 15, y: 700, width: 100, height: 50)
//        refreshBut.setTitle("Refresh", for: .normal)
//        refreshBut.layer.borderWidth = 1.0
//        refreshBut.layer.borderColor = UIColor.blue.cgColor
//        refreshBut.addTarget(self, action: #selector(refresh), for: .touchUpInside)
//        self.view.addSubview(refreshBut)
        
        let statsBut = UIButton(type: .system)
        statsBut.frame = CGRect(x: 145, y: 700, width: 100, height: 50)
        statsBut.setTitle("Stats", for: .normal)
        statsBut.layer.borderWidth = 1.0
        statsBut.layer.borderColor = UIColor.blue.cgColor
        statsBut.addTarget(self, action: #selector(didTapStat), for: .touchUpInside)
        self.view.addSubview(statsBut)
    }
    
    // table function
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // view data on the first page
        dateFormatter.dateFormat = "YY/MM/dd"
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var colorSign = UIColor.clear
        
        var textCol = UIColor.label
        
        cell.textLabel?.text = data[indexPath.row].item + ", " + String(format: "%.1f", data[indexPath.row].budget) + ", DL: " + dateFormatter.string(from: data[indexPath.row].date)
        
        if (data[indexPath.row].finished) {
            //doneString = "Done!"
            colorSign = UIColor.init(red: 0.384, green: 0.792, blue: 0.314, alpha: 1.0)
            textCol = UIColor.darkText
        } else if (data[indexPath.row].checkIn) {
            colorSign = UIColor.init(red: 1.0, green: 0.847, blue: 0.153, alpha: 1.0)
            textCol = UIColor.darkText
            
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 0.0) {
            //doneString = "Urgent!"
            colorSign = UIColor.init(red: 0.831, green: 0.165, blue: 0.204, alpha: 1.0)
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * 6.0) {
            //doneString = "Attention!"
            colorSign = UIColor.init(red: 0.969, green: 0.549, blue: 0.216, alpha: 1.0)
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * 24.0) {
            //doneString = "Today!"
            colorSign = UIColor.init(red: 0.416, green: 0.196, blue: 0.647, alpha: 1.0)
            textCol = UIColor.lightText
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * 48.0) {
            //doneString = "Tomorrow!"
            colorSign = UIColor.init(red: 0.643, green: 0.196, blue: 0.647, alpha: 1.0)
            textCol = UIColor.lightText
        }
        
        cell.backgroundColor = colorSign
        cell.textLabel?.textColor = textCol
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // open the screen to see the item in full or delete.
        let item = data[indexPath.row]

        guard let vc = storyboard?.instantiateViewController(identifier: "view") as? ViewViewController else {
            return
        }

        vc.item = item
        vc.deletionHandler = { [weak self] in
            self?.refresh()
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = item.item
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapAddButton() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "enter") as? EntryViewController else {
            return
        }
        vc.completionHandler = { [weak self] in
            self?.refresh()
        }
        vc.title = "New Item"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTapStat() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "stats") as? StatsViewController else {
            return
        }
        vc.title = "Statistics"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func refresh() {
        data = realm.objects(checkListItem.self).map({ $0 })
        data = data.sorted(by: {$0.date<$1.date}) //Now list ordered by deadline ASC
        table.reloadData()
    }

}

