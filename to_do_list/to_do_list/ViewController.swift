//
//  ViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 10/10/21.
//

import RealmSwift
import UIKit
import Foundation
import DropDown

/*
 - show to do list items
 - to add new items
 - to show previous items
 
 - item
 - due date
 */

class checkListItem: Object, Codable {
    @objc dynamic var item: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var budget: Double = 0.0
    @objc dynamic var checkIn: Bool = false
    @objc dynamic var finished: Bool = false
    @objc dynamic var startTime: Date = Date()
    @objc dynamic var timeSpent: TimeInterval = 0.0
    @objc dynamic var tag: Int = 0
    let KR = List<String>() // Will implement methods for OKR later.

    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case item, date, budget, checkIn, finished, startTime, timeSpent, tag, KR
    }

    // MARK: - Codable Initializer
    required public convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        item = try container.decode(String.self, forKey: .item)
        date = try container.decode(Date.self, forKey: .date)
        budget = try container.decode(Double.self, forKey: .budget)
        checkIn = try container.decode(Bool.self, forKey: .checkIn)
        finished = try container.decode(Bool.self, forKey: .finished)
        startTime = try container.decode(Date.self, forKey: .startTime)
        timeSpent = try container.decode(TimeInterval.self, forKey: .timeSpent)
        tag = try container.decode(Int.self, forKey: .tag)
        KR.append(objectsIn: try container.decode([String].self, forKey: .KR))
    }

    // MARK: - Encode to JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(item, forKey: .item)
        try container.encode(date, forKey: .date)
        try container.encode(budget, forKey: .budget)
        try container.encode(checkIn, forKey: .checkIn)
        try container.encode(finished, forKey: .finished)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(timeSpent, forKey: .timeSpent)
        try container.encode(tag, forKey: .tag)
        try container.encode(Array(KR), forKey: .KR)
    }
}

// MARK: - Daily Performance Evaluation
class dailyPerfEval: Object, Codable {
    @objc dynamic var tot_finish: Double = 0.0
    @objc dynamic var tot_time: Double = 0.0
    @objc dynamic var date: Date = Date()
    let tagLog = List<Double>() // Breakdown of time use into areas
    let tagLogDone = List<Double>() // Breakdown of finished tasks into areas

    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case tot_finish, tot_time, date, tagLog, tagLogDone
    }

    // MARK: - Initializer
    override init() {
        super.init()
        tagLog.append(objectsIn: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        tagLogDone.append(objectsIn: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    }

    // MARK: - Codable Initializer
    required public convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tot_finish = try container.decode(Double.self, forKey: .tot_finish)
        tot_time = try container.decode(Double.self, forKey: .tot_time)
        date = try container.decode(Date.self, forKey: .date)
        tagLog.append(objectsIn: try container.decode([Double].self, forKey: .tagLog))
        tagLogDone.append(objectsIn: try container.decode([Double].self, forKey: .tagLogDone))
    }

    // MARK: - Encode to JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tot_finish, forKey: .tot_finish)
        try container.encode(tot_time, forKey: .tot_time)
        try container.encode(date, forKey: .date)
        try container.encode(Array(tagLog), forKey: .tagLog)
        try container.encode(Array(tagLogDone), forKey: .tagLogDone)
    }
}

// When you open the realm, specify that the schema
// is now using a newer version.
let config = Realm.Configuration(
    schemaVersion: 6)

let tagDic = [0: " ", 1:"Lab", 2: "Research", 3: "Side", 4: "Study", 5: "Person"]


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    
    @IBOutlet var table: UITableView!
    //@IBOutlet var scroll: UIScrollView!
    
    private let realm = try! Realm(configuration: config)
    
    private let dateFormatter = DateFormatter()
    
    private var data = [checkListItem]()
    
    private var perfData = [dailyPerfEval]()
    
    private var deleteIndex:Set<Int> = []
    
    private let center = UNUserNotificationCenter.current()
    
    var timer: Timer!
    
    // Dropdown menu
    let menu: DropDown = {
        let menu = DropDown()
        menu.dataSource = [
            "Postpone",
            "Delete",
            "Statistics",
            "Schedule",
            "Export Data",
            "Import Data"
        ]
        return menu
    } ()
    
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
        
//        let statsBut = UIButton(type: .system)
//        statsBut.frame = CGRect(x: 145, y: 700, width: 100, height: 50)
//        statsBut.setTitle("Schedule", for: .normal)
//        statsBut.layer.borderWidth = 1.0
//        statsBut.layer.borderColor = UIColor.blue.cgColor
//        statsBut.addTarget(self, action: #selector(didTapSchedule), for: .touchUpInside)
//        self.view.addSubview(statsBut)
        
        // left bar buttom
        //navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapDelete))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapEdit))
        
        menu.anchorView = self.view
        menu.bottomOffset = CGPoint(x: 0, y:((table.frame.minY) + 52)) // 52 is the safty distance set in canvas. Should parameterize everything.
        menu.selectionAction = { rowSelected, _ in
            switch rowSelected {
            case 0:
                self.didTapPostpone()
            case 1:
                self.didTapDelete()
            case 2:
                self.didTapStat()
            case 3:
                self.didTapSchedule()
            case 4:
                self.exportData()
            case 5:
                self.importData()
            default:
                return
            }
            
        }
        
        menu.dismissMode = .onTap
        
        // add long press. From https://juejin.cn/post/6844903543237771272.
        table.isEditing = false
        
        table.allowsMultipleSelectionDuringEditing = true
        
        let longPress = UILongPressGestureRecognizer(target:self,
                                                     action:#selector(longPressed))
        longPress.delegate = self
        longPress.minimumPressDuration = 1.0
        table.addGestureRecognizer(longPress)
        
        dailyBackup()

        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.dailyBackup()
        }
            
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
    }
    
        
    @objc func appMovedToBackground() {
        dailyBackup()
    }
        
        
    // table function
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // view data on the first page. Note YY is for week-year. yy is for calendar year.
        dateFormatter.dateFormat = "yy/MM/dd"
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var colorSign = UIColor.clear
        
        var textCol = UIColor.label
        
        let tempText = dateFormatter.string(from: data[indexPath.row].date) + ", " + String(format: "%.1f", data[indexPath.row].budget) + ", "
        let tempText2 = (tagDic[data[indexPath.row].tag] ?? " ") + ", " + data[indexPath.row].item
        
        cell.textLabel?.text = tempText + tempText2
        
        if (data[indexPath.row].finished) {
            //doneString = "Done!"
            colorSign = UIColor.init(red: 0.384, green: 0.792, blue: 0.314, alpha: 0.8) // Green
            textCol = UIColor.darkText
        } else if (data[indexPath.row].checkIn) {
            colorSign = UIColor.init(red: 1.0, green: 0.847, blue: 0.153, alpha: 0.8) // Yellow
            textCol = UIColor.darkText
            
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 0.0) {
            //doneString = "Urgent!"
            colorSign = UIColor.init(red: 0.831, green: 0.165, blue: 0.204, alpha: 0.8) // Red
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * max(6.0, data[indexPath.row].budget)) {
            //doneString = "Attention!"
            colorSign = UIColor.init(red: 0.969, green: 0.549, blue: 0.216, alpha: 0.8) // Orange
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * max(24.0, data[indexPath.row].budget * 3.0)) {
            // * 3.0 because of assumption that one works 8 hours a day, so an 8-hour task spans one day. As a result, a task with a 16-hour budget due in 2 days is still treated as one needing attention today.
            //doneString = "Today!"
            //colorSign = UIColor.init(red: 0.416, green: 0.196, blue: 0.647, alpha: 0.8) // Dark purple
            colorSign = UIColor.init(red: 0.643, green: 0.196, blue: 0.647, alpha: 0.8) // Light purple
            textCol = UIColor.lightText
        } else if (data[indexPath.row].date.timeIntervalSinceNow <= 3600 * max(48.0, data[indexPath.row].budget * 3.0 * 2.0)) {
            //doneString = "Tomorrow!"
            // A taskwith with a 16-hour budget due in 4 days is treated as one needing attention "tomorrow", though it won't become more urgent tomorrow.
            colorSign = UIColor.init(red: 0.227, green: 0.376, blue: 0.847, alpha: 0.8) // Royal blue
            textCol = UIColor.lightText
        }
        
        cell.backgroundColor = colorSign
        cell.textLabel?.textColor = textCol
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !table.isEditing {
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
        } else {
            deleteIndex.insert(indexPath.row)
        }
        
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // This reverses the selection.
        deleteIndex.remove(indexPath.row)
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
    
    @objc func didTapSchedule() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "schedule") as? ScheduleViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
//        let vc = ScheduleViewController()
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTapDelete() {
        
        if deleteIndex.isEmpty {
            
            if(self.table!.isEditing == false) {
                self.table!.setEditing(true, animated:true)
                return
            }
            else {
                let alert = UIAlertController(title: "Select items to delete", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            
        }
        
        let alert = UIAlertController(title: "Delete those " + String(deleteIndex.count) + " tasks?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
            self.realm.beginWrite()
            for index in self.deleteIndex {
                
                let myItem = self.data[index]
                if (!myItem.finished && myItem.checkIn) {
                    // Check out first. Not able to do it correctly here, so prompt user to do it in the detailed page.
                    let alert2 = UIAlertController(title: "Check out this task first!", message: myItem.item, preferredStyle: .alert)
                    
                    alert2.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    
                    self.present(alert2, animated: true)
                    
                } else {
                    self.realm.delete(myItem)
                }
                
            }
            try! self.realm.commitWrite()
            self.table.isEditing = false
            self.deleteIndex = [] // Important!
//            print(self.deleteIndex)
            self.refresh()
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {(action: UIAlertAction!) in
            
            self.table.isEditing = false
            self.deleteIndex = [] // Important!
        }))
        
        self.present(alert, animated: true)
    

    }
    
    @objc func didTapPostpone() {
        // postpone items in bulk.
        if deleteIndex.isEmpty {
            
            if(self.table!.isEditing == false) {
                self.table!.setEditing(true, animated:true)
                return
            }
            else {
                let alert = UIAlertController(title: "Select items to postpone", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            
            
        }
        
        let alert = UIAlertController(title: "Postpone those " + String(deleteIndex.count) + " tasks?", message: "How many days to postpone?", preferredStyle: .alert)
        
        alert.addTextField{ textField in
            textField.placeholder = "7"
        }
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
            
            let textField = alert.textFields?.first
            
            self.realm.beginWrite()
            
            let addedDays = Double(textField!.text!) ?? 7.0

            for index in self.deleteIndex {
                let myItem = self.data[index]
                myItem.date = myItem.date.addingTimeInterval(addedDays * 86400)
            }
            try! self.realm.commitWrite()
            self.table.isEditing = false
            self.deleteIndex = [] // Important!
//            print(self.deleteIndex)
            self.refresh()
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {(action: UIAlertAction!) in
            
            self.table.isEditing = false
            self.deleteIndex = [] // Important!
        }))
        
        self.present(alert, animated: true)

    }
    
    
    @objc func didTapEdit() {
        // Shows the drop down menu
        menu.show()
    }
    
    @objc func refresh() {
        // Will not refresh view if is editing.
        if !table.isEditing {
            data = realm.objects(checkListItem.self).map({ $0 })
            data = data.sorted(by: {$0.date<$1.date}) //Now list ordered by deadline ASC
            table.reloadData()
        }
    }

}

extension ViewController: UIGestureRecognizerDelegate {
    
    // long press to select. From https://juejin.cn/post/6844903543237771272
    @objc func longPressed(gestureRecognizer:UILongPressGestureRecognizer)
    {
        if (gestureRecognizer.state == .ended)
        {
            
            if(self.table!.isEditing == false) {
                self.table!.setEditing(true, animated:true)
            }
            else {
                self.table!.setEditing(false, animated:true)
                self.deleteIndex = [] // Important!
            }
        }
    }
}

// MARK: - JSON Backup / Export / Import

extension ViewController {

    func getExportFolder() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("Exports")

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder
    }

    func dailyBackup() {
        do {

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let checkItems = Array(realm.objects(checkListItem.self))
            let perfItems = Array(realm.objects(dailyPerfEval.self))

            let folder = getExportFolder()

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let dateStr = formatter.string(from: Date())

            let checkURL = folder.appendingPathComponent("checkListItems-\(dateStr).json")
            let perfURL = folder.appendingPathComponent("dailyPerfEval-\(dateStr).json")

            try encoder.encode(checkItems).write(to: checkURL)
            try encoder.encode(perfItems).write(to: perfURL)

            cleanOldBackups(folder: folder, prefix: "checkListItems-", keep: 2)
            cleanOldBackups(folder: folder, prefix: "dailyPerfEval-", keep: 2)
            
            print(checkURL.path)

            print("Backup completed")
            
            try "test".write(to: folder.appendingPathComponent("test.txt"),
                             atomically: true,
                             encoding: .utf8)

        } catch {
            print("Backup failed:", error)
        }
    }

    func cleanOldBackups(folder: URL, prefix: String, keep: Int) {

        guard let files = try? FileManager.default.contentsOfDirectory(at: folder,
            includingPropertiesForKeys: [.creationDateKey],
            options: []) else { return }

        let filtered = files.filter { $0.lastPathComponent.hasPrefix(prefix) }

        let sorted = filtered.sorted {
            let d0 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let d1 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return d0 < d1
        }

        if sorted.count > keep {
            for file in sorted.dropLast(keep) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    func exportData() {
        dailyBackup()

        let alert = UIAlertController(
            title: "Export Complete",
            message: "Backup saved to Files → On My iPhone → to_do_list → Exports",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func importData() {

        do {

            let folder = getExportFolder()

            let files = try FileManager.default.contentsOfDirectory(at: folder,
                includingPropertiesForKeys: [.creationDateKey],
                options: [])

            let checkFiles = files.filter { $0.lastPathComponent.hasPrefix("checkListItems-") }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }

            let perfFiles = files.filter { $0.lastPathComponent.hasPrefix("dailyPerfEval-") }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }

            guard let checkFile = checkFiles.first,
                  let perfFile = perfFiles.first else { return }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let checkItems = try decoder.decode([checkListItem].self, from: Data(contentsOf: checkFile))
            let perfItems = try decoder.decode([dailyPerfEval].self, from: Data(contentsOf: perfFile))

            try realm.write {

                for item in checkItems {
                    realm.add(item)
                }

                for item in perfItems {
                    realm.add(item)
                }

            }

            refresh()

        } catch {
            print("Import failed:", error)
        }
    }
}
