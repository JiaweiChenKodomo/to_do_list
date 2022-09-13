//
//  ViewViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 10/10/21.
//

import RealmSwift
import UIKit
import EventKit
import EventKitUI

class ViewViewController: UIViewController, EKEventEditViewDelegate, UIScrollViewDelegate, UNUserNotificationCenterDelegate {
    
    public var item: checkListItem?
    
    public var deletionHandler: (() -> Void)?
    
    private var scrollView: UIScrollView!
    
    private let store =  EKEventStore()
    
    private let center = UNUserNotificationCenter.current()
    
    private var canNotify = true;
    
    private let xOffSet = 10;
    private let yOffSet = 40;
    
    private let TvBLabel = UILabel()
    private let TLabel = UILabel()
    private let ElapsedTimeLabel = UILabel()
    private let lastCheckInTimeLabel = UILabel()
    
    private let itemLabel = UILabel()
    private let dateLabel = UILabel()
    private let BLabel = UILabel()
    private let taskLabel = UILabel()
    private let deadlineLabel = UILabel()
    private let BGTLabel = UILabel()
    private let IPTLabel = UILabel()
    private let IPTBGTLabel = UILabel()
    private let TFCLabel = UILabel()
    private let TFCOLabel = UILabel()
    
    private let checkInBut = UIButton(type: .system)
    private let checkTimeBut = UIButton(type: .system)
    private let checkOutBut = UIButton(type: .system)
    private let finishBut = UIButton(type: .system)
    private let partialFinishBut = UIButton(type: .system)
    private let modBut = UIButton(type: .system)
    private let addCalBut = UIButton(type: .system)
    private let focusBut = UIButton(type: .system)
    
    var timer: Timer!
    
    private let realm = try! Realm()
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY/MM/dd, HH:mm"
        return dateFormatter
    }()
    
    let timeFormatter: DateComponentsFormatter = {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = [ .pad ]
        return timeFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Assing self delegate on userNotificationCenter
        self.center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            
            if let error = error {
                print("Error: ", error)
            }
            
            self.canNotify = granted
        }
        
        itemLabel.text = item?.item
        let numberOfLines = (itemLabel.text?.count ?? 0) / 35 + 1
        let textHeight = (numberOfLines) * 21
        let deltaY = 21
        
        //scrollView = UIScrollView(frame: view.bounds)
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: Int(view.bounds.width), height: Int(view.bounds.height)))
        //scrollView.contentSize = view.bounds.size
        let maxHeight = max(yOffSet + deltaY*7 + textHeight + 350, Int(view.bounds.height)+1)
        scrollView.contentSize = CGSize.init(width: view.bounds.size.width, height: CGFloat(maxHeight))
        // A right combination of contentOffset and contentSize is the most important for scrollView.
        scrollView.contentOffset = CGPoint(x: 0, y: 15)
        
        
        itemLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY, width: 350-xOffSet*2, height: textHeight)
        itemLabel.lineBreakMode = .byWordWrapping
        itemLabel.numberOfLines = numberOfLines
        scrollView.addSubview(itemLabel)
        
        dateLabel.frame = CGRect(x: 106+xOffSet, y: yOffSet + deltaY*2 + textHeight, width: 334-xOffSet*2, height: 21)
        scrollView.addSubview(dateLabel)
        
        TvBLabel.frame = CGRect(x: 137+xOffSet, y: yOffSet + deltaY*5 + textHeight, width: 286-xOffSet*2, height: 21)
        scrollView.addSubview(TvBLabel)
        
        TLabel.frame = CGRect(x: 78+xOffSet, y: yOffSet + deltaY*4 + textHeight, width: 351-xOffSet*2, height: 21)
        scrollView.addSubview(TLabel)
        
        BLabel.frame = CGRect(x: 95+xOffSet, y: yOffSet + deltaY*3 + textHeight, width: 339-xOffSet*2, height: 21)
        scrollView.addSubview(BLabel)
        
        ElapsedTimeLabel.frame = CGRect(x: 190+xOffSet, y: yOffSet + deltaY*6 + textHeight, width: 152-xOffSet*2, height: 21)
        scrollView.addSubview(ElapsedTimeLabel)
        
        lastCheckInTimeLabel.frame = CGRect(x: 190+xOffSet, y: yOffSet + deltaY*7 + textHeight, width: 152-xOffSet*2, height: 21)
        scrollView.addSubview(lastCheckInTimeLabel)
        
        dateLabel.text = Self.dateFormatter.string(from: item!.date)
        lastCheckInTimeLabel.text = Self.dateFormatter.string(from: item!.startTime)
        BLabel.text = String(format: "%.2f hours", item!.budget)
        if item!.checkIn {
            TvBLabel.text = item!.budget > 0 ? String(format: "%.2f", (item!.timeSpent - item!.startTime.timeIntervalSinceNow / 3600.0) / item!.budget) : "0.0"
            TLabel.text = String(format: "%.2f hours", item!.timeSpent - item!.startTime.timeIntervalSinceNow / 3600.0)
            
            ElapsedTimeLabel.text = timeFormatter.string(from: TimeInterval(-item!.startTime.timeIntervalSinceNow))
            // Updates at each second.
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        } else {
            TvBLabel.text = item!.budget > 0 ? String(format: "%.2f", item!.timeSpent / item!.budget) : "0.0"
            TLabel.text = String(format: "%.2f hours", item!.timeSpent)
            ElapsedTimeLabel.text = String(format: "%.2f hours", 0.0)
            //print("Checked out")
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(didTapDelete))
        
        taskLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet, width: 40, height: 21)
        taskLabel.textAlignment = .left
        taskLabel.text = "Task:"
        scrollView.addSubview(taskLabel)
        
        deadlineLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*2 + textHeight, width: 76, height: 21)
        deadlineLabel.textAlignment = .left
        deadlineLabel.text = "Deadline:"
        scrollView.addSubview(deadlineLabel)
        
        BGTLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*3 + textHeight, width: 65, height: 21)
        BGTLabel.textAlignment = .left
        BGTLabel.text = "Budget:"
        scrollView.addSubview(BGTLabel)
        
        IPTLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*4 + textHeight, width: 48, height: 21)
        IPTLabel.textAlignment = .left
        IPTLabel.text = "Input:"
        scrollView.addSubview(IPTLabel)
        
        IPTBGTLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*5 + textHeight, width: 107, height: 21)
        IPTBGTLabel.textAlignment = .left
        IPTBGTLabel.text = "Input/Budget:"
        scrollView.addSubview(IPTBGTLabel)
        
        TFCLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*6 + textHeight, width: 160, height: 21)
        TFCLabel.textAlignment = .left
        TFCLabel.text = "Time from Check-in:"
        scrollView.addSubview(TFCLabel)
        
        TFCOLabel.frame = CGRect(x: 30+xOffSet, y: yOffSet + deltaY*7 + textHeight, width: 160, height: 21)
        TFCOLabel.textAlignment = .left
        TFCOLabel.text = "Last Checked Time:"
        scrollView.addSubview(TFCOLabel)
        
        checkInBut.frame = CGRect(x: 15, y: yOffSet + deltaY*7 + textHeight + 50, width: 100, height: 50)
        checkInBut.setTitle("Check-in", for: .normal)
        checkInBut.layer.borderWidth = 1.0
        checkInBut.layer.borderColor = UIColor.blue.cgColor
        checkInBut.addTarget(self, action: #selector(didCheckIn), for: .touchUpInside)
        //self.view.addSubview(checkInBut)
        scrollView.addSubview(checkInBut)
        
        checkTimeBut.frame = CGRect(x: 255, y: yOffSet + deltaY*7 + textHeight + 50, width: 100, height: 50)
        checkTimeBut.setTitle("Adjust Time", for: .normal)
        checkTimeBut.layer.borderWidth = 1.0
        checkTimeBut.layer.borderColor = UIColor.blue.cgColor
        checkTimeBut.addTarget(self, action: #selector(didAdjust), for: .touchUpInside)
        //self.view.addSubview(checkTimeBut)
        scrollView.addSubview(checkTimeBut)
        
        checkOutBut.frame = CGRect(x: 135, y: yOffSet + deltaY*7 + textHeight + 50, width: 100, height: 50)
        checkOutBut.setTitle("Check-out", for: .normal)
        checkOutBut.layer.borderWidth = 1.0
        checkOutBut.layer.borderColor = UIColor.blue.cgColor
        checkOutBut.addTarget(self, action: #selector(didCheckOut), for: .touchUpInside)
        //self.view.addSubview(checkOutBut)
        scrollView.addSubview(checkOutBut)
        
        finishBut.frame = CGRect(x: 15, y: yOffSet + deltaY*7 + textHeight + 150, width: 100, height: 50)
        finishBut.setTitle("Finish", for: .normal)
        finishBut.layer.borderWidth = 1.0
        finishBut.layer.borderColor = UIColor.blue.cgColor
        finishBut.addTarget(self, action: #selector(didFinish), for: .touchUpInside)
        //self.view.addSubview(finishBut)
        scrollView.addSubview(finishBut)
        
        partialFinishBut.frame = CGRect(x: 135, y: yOffSet + deltaY*7 + textHeight + 150, width: 130, height: 50)
        partialFinishBut.setTitle("Log Completion", for: .normal)
        partialFinishBut.layer.borderWidth = 1.0
        partialFinishBut.layer.borderColor = UIColor.blue.cgColor
        partialFinishBut.addTarget(self, action: #selector(didPartialFinish), for: .touchUpInside)
        //self.view.addSubview(partialFinishBut)
        scrollView.addSubview(partialFinishBut)
        
        modBut.frame = CGRect(x: 285, y: yOffSet + deltaY*7 + textHeight + 150, width: 70, height: 50)
        modBut.setTitle("Modify", for: .normal)
        modBut.layer.borderWidth = 1.0
        modBut.layer.borderColor = UIColor.blue.cgColor
        modBut.addTarget(self, action: #selector(didTapMod), for: .touchUpInside)
        //self.view.addSubview(modBut)
        scrollView.addSubview(modBut)
        
        addCalBut.frame = CGRect(x: 15, y: yOffSet + deltaY*7 + textHeight + 250, width: 130, height: 50)
        addCalBut.setTitle("Add to Calendar", for: .normal)
        addCalBut.layer.borderWidth = 1.0
        addCalBut.layer.borderColor = UIColor.blue.cgColor
        addCalBut.addTarget(self, action: #selector(didAddCal), for: .touchUpInside)
        //self.view.addSubview(addCalBut)
        scrollView.addSubview(addCalBut)
        
        focusBut.frame = CGRect(x: 165, y: yOffSet + deltaY*7 + textHeight + 250, width: 190, height: 50)
        focusBut.setTitle("Focus Mode", for: .normal)
        focusBut.layer.borderWidth = 1.0
        focusBut.layer.borderColor = UIColor.blue.cgColor
        focusBut.addTarget(self, action: #selector(didFocus), for: .touchUpInside)
        //self.view.addSubview(focusBut)
        scrollView.addSubview(focusBut)
        
        //print(self.view.subviews.count)
        for currentSubView in self.view.subviews {
            currentSubView.removeFromSuperview()
        }
        
        self.view.addSubview(scrollView)
        
    }
    
    
    @objc func step() {
        if !item!.checkIn {
            // Checked out. Stop the timer. Don't update anything now.
            timer.invalidate()
        } else {
            // Careful! Putting this outside adds additional time to displayed time usage when checked out.
            TvBLabel.text = item!.budget > 0 ? String(format: "%.2f", (item!.timeSpent - item!.startTime.timeIntervalSinceNow / 3600.0) / item!.budget) : "0.0"
            TLabel.text = String(format: "%.2f hours", item!.timeSpent - item!.startTime.timeIntervalSinceNow / 3600.0)
            
            ElapsedTimeLabel.text = timeFormatter.string(from: TimeInterval(-item!.startTime.timeIntervalSinceNow))
        }
        //print("stepped")
        
    }
    
    @objc private func didFocus() {
        if item!.finished {
            // Do nothing if task already finished. 
            return
        }
        if !item!.checkIn {
            // Check in first if not already.
            didCheckIn()
        }
        
        let alert = UIAlertController(title: "Target focus period?", message: "How long do you want to stay focused in minutes?", preferredStyle: .alert)
        
        alert.addTextField{ textField in
            textField.placeholder = "30.0"
        }
        
        var addedMinute = 0.0
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) {
            [weak alert] _ in
            guard let alertController = alert, let textField = alertController.textFields?.first else { return }
            
            //print("Current password \(String(describing: textField.text))")
            
            addedMinute = Double(textField.text!) ?? 30.0
            
            // Jump to Focus view
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "focus") as? FocusViewController else {
                return
            }
            //vc.item = item
            vc.title = "Focus View"
            vc.startFocus = Date()
            vc.checkInTime = self.item?.startTime
            vc.navigationItem.largeTitleDisplayMode = .never
            vc.completionHandler = self.deletionHandler
            vc.addedTime = addedMinute * 60.0
            self.navigationController?.pushViewController(vc, animated: true)
            
        }
        self.present(alert, animated: true)
        alert.addAction(confirmAction)
        
        
        
    }
    
    @objc private func didTapMod() {
        // Jump to Mod view
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "mod") as? ModViewController else {
            return
        }
        vc.item = item
        vc.title = "Modify Item"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completionHandler = deletionHandler
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didAddCal() {
        
        store.requestAccess(to: .event) { success , error in
            if success, error == nil {
                DispatchQueue.main.async {
                    let store = self.store
                    
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.title = self.item?.item
                    newEvent.startDate = self.item?.date
                    newEvent.endDate = self.item?.date.addingTimeInterval((self.item?.budget ?? 0.0) * 3600)
                    
                    let vc = EKEventEditViewController()
                    vc.eventStore = store
                    vc.event = newEvent
                    vc.editViewDelegate = self // This is important. 
                    
                    self.present(vc, animated: true, completion: nil)
                    
                }
            }
        }
        
        
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func center(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func center(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .badge])
    }
    
    
    @objc private func didTapDelete() {
        guard let myItem = self.item else {
            return
        }
        
        // Check if checked out. If not, check out first.
        if item!.checkIn {
            didCheckOut()
        }
        
        let alert = UIAlertController(title: "Delete this task?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
            self.realm.beginWrite()
            self.realm.delete(myItem)
            try! self.realm.commitWrite()
            self.deletionHandler?()
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    @objc private func didCheckIn() {
        guard let myItem = self.item else {
            return
        }
        
        if (myItem.checkIn || myItem.finished) {
            return
        }

        realm.beginWrite()
        
        myItem.startTime = Date()
        myItem.checkIn = true
        
        try! realm.commitWrite()
        
        deletionHandler?()
        
        // Enable or disable features based on the authorization.
        // Add notification at check-in.
        if self.canNotify {
            DispatchQueue.main.async {
                let content = UNMutableNotificationContent()
                content.body = myItem.item
                content.sound = UNNotificationSound.default
                
                let futureTime = (myItem.budget - myItem.timeSpent) * 3600.0
                
                let futureTime2 = myItem.date.timeIntervalSinceNow
                
                var addedTime = 0.0
                
                var alertMessage: String
                
                var setAlert: Bool
                
                if futureTime2 > 0 && futureTime > futureTime2 {
                    // If the deadline is not past and budget is not used up at the deadline, add notification at the deadline.
                    addedTime = futureTime2
                    content.title = "Current task passing deadline."
                    alertMessage = "Will push a notification when passing deadline."
                    setAlert = true
                } else if futureTime > 0 {
                    addedTime = futureTime
                    content.title = "Current task out of budgeted time."
                    alertMessage = "Will push a notification when out of budget."
                    setAlert = true
                } else {
                    // Out of budget and deadline is passed.
                    addedTime = 0.0
                    content.title = ""
                    alertMessage = "Need to assign more budget."
                    setAlert = false
                }
                
                if setAlert {
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: addedTime, repeats: false)
                    
                    let request = UNNotificationRequest(identifier: myItem.item,
                                content: content, trigger: trigger)

                    // Schedule the request with the system.
                    self.center.add(request) { (error) in
                        if let error = error {
                           
                            // Handle any errors.
                            print("Error: ", error)
                        }
                        
                    }
                }
                
                
                let alert = UIAlertController(title: "Checked in!", message: alertMessage, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            
        }
        // Update view.
        self.viewDidLoad()
        
    }
    
    @objc private func didAdjust() {
        // When adjusting time, need to check out, and can't have finished.
        // Added/subtracted time will be posted to the day the adjustment is made.
        guard let myItem = self.item else {
            return
        }
        
        if (myItem.checkIn || myItem.finished) {
            return
        }
        
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd: Date = {
          let components = DateComponents(day: 1, second: -1)
          return Calendar.current.date(byAdding: components, to: todayStart)!
        }()
        
        let dayEval = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", todayStart, todayEnd)

        realm.beginWrite()
        
        let alert = UIAlertController(title: "Adjust Spent Time!", message: "Input Added Time in Hour", preferredStyle: .alert)
        
        alert.addTextField{ textField in
            textField.placeholder = "Add Time"
            //textField.isSecureTextEntry = true
        }
        
        var addedHour = 0.0
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) {
            [weak alert] _ in
            guard let alertController = alert, let textField = alertController.textFields?.first else { return }
            
            //print("Current password \(String(describing: textField.text))")
            
            addedHour = Double(textField.text!) ?? 0.0
            
            myItem.timeSpent += addedHour;
            if addedHour < 0 {
                if (dayEval.first == nil) {
                    //reduces time of the previous days
                    var thisDayStart = Calendar.current.startOfDay(for: Date())
                    while addedHour < 0 {
                        let previousDayStart: Date = {
                            let components = DateComponents(day: -1)
                            return Calendar.current.date(byAdding: components, to: thisDayStart)!
                          }()
                        let previousDayEnd: Date = {
                            let components = DateComponents(second: -1)
                            return Calendar.current.date(byAdding: components, to: thisDayStart)!
                          }()
                        let prevDayEval = self.realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", previousDayStart, previousDayEnd)
                        if (prevDayEval.first != nil) {
                            let newAddedHour = addedHour + prevDayEval.first!.tot_time
                            prevDayEval.first?.tot_time = max(0.0, newAddedHour)
                            addedHour = newAddedHour
                        }
                        thisDayStart = previousDayStart
                    }
                    
                } else {
                    //print("original record %f", dayEval.first?.tot_time)
                    let newAddedHour = addedHour + dayEval.first!.tot_time
                    //print("new record %f", newAddedHour)
                    dayEval.first?.tot_time = max(0.0, newAddedHour)
                    addedHour = newAddedHour
                    //print("addded hour now %f", addedHour)
                    var thisDayStart = Calendar.current.startOfDay(for: Date())
                    while addedHour < 0 {
                        
                        let previousDayStart: Date = {
                            let components = DateComponents(day: -1)
                            return Calendar.current.date(byAdding: components, to: thisDayStart)!
                          }()
                        let previousDayEnd: Date = {
                            let components = DateComponents(second: -1)
                            return Calendar.current.date(byAdding: components, to: thisDayStart)!
                          }()
                        let prevDayEval = self.realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", previousDayStart, previousDayEnd)
                        if (prevDayEval.first != nil) {
                            let newAddedHour = addedHour + prevDayEval.first!.tot_time
                            prevDayEval.first?.tot_time = max(0.0, newAddedHour)
                            addedHour = newAddedHour
                        }
                        thisDayStart = previousDayStart
                    }
                }
            } else {
                if (dayEval.first == nil) {
                    //print("initializing record")
                    let newDayEval = dailyPerfEval()
                    newDayEval.tot_time += addedHour
                    newDayEval.date = Date() // set initial data on today.
                    self.realm.add(newDayEval)
                } else {
                    //print("original record %f", dayEval.first?.tot_time)
                    dayEval.first?.tot_time += addedHour
                }
            }
            
            try! self.realm.commitWrite()
            
            // Update view.
            self.viewDidLoad()
        }
        self.present(alert, animated: true)
        alert.addAction(confirmAction)
        
    }
    
    @objc private func didCheckOut() {
        guard let myItem = self.item else {
            return
        }
        
        if (!myItem.finished && myItem.checkIn) {
            // day interval for today
            let todayStart = Calendar.current.startOfDay(for: Date())
            let todayEnd: Date = {
              let components = DateComponents(day: 1, second: -1)
              return Calendar.current.date(byAdding: components, to: todayStart)!
            }()
            
            // suppose startTime was yesterday.
            let yesterdayStart = Calendar.current.startOfDay(for: myItem.startTime)
            
            let yesterdayEnd: Date = {
                let components = DateComponents(day: 1, second: -1)
                return Calendar.current.date(byAdding: components, to: yesterdayStart)!
            }()
            
            realm.beginWrite()
            
            if yesterdayEnd.timeIntervalSinceNow < 0 {
                // yesterdayEnd is earlier than now. Spaning two days. Ignore problem with multiple days: that is usually not possible.
                
                let elapsedTime = -myItem.startTime.timeIntervalSince(yesterdayEnd) / 3600.0
                myItem.timeSpent += elapsedTime;
                
                let dayEval = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", yesterdayStart, yesterdayEnd)
                
                if (dayEval.first == nil) {
                    //print("initializing record")
                    let newDayEval = dailyPerfEval()
                    newDayEval.tot_time += elapsedTime
                    newDayEval.date = myItem.startTime
                    realm.add(newDayEval)
                } else {
                    //print("original record %f", dayEval.first?.tot_time)
                    dayEval.first?.tot_time += elapsedTime
                }
                // Change startTime to today
                myItem.startTime = todayStart
            }
            
            let elapsedTime = -myItem.startTime.timeIntervalSinceNow / 3600.0
            
            let dayEval = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", todayStart, todayEnd)
            
            myItem.timeSpent += elapsedTime;
            myItem.checkIn = false
            
            if (dayEval.first == nil) {
                //print("initializing record")
                let newDayEval = dailyPerfEval()
                newDayEval.tot_time += elapsedTime
                realm.add(newDayEval)
            } else {
                //print("original record %f", dayEval.first?.tot_time)
                dayEval.first?.tot_time += elapsedTime
            }
            
            myItem.startTime = Date()
            
            try! realm.commitWrite()
            
            deletionHandler?()
            
            // Remove associated notifications on check-out
            if self.canNotify {
                DispatchQueue.main.async {
                    
                    self.center.removePendingNotificationRequests(withIdentifiers: [myItem.item])
                    
                }
            }
            
            let alert = UIAlertController(title: "Checked out!", message: "You worked for " + String(elapsedTime) + " hours", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
            
        }
        // Update view.
        self.viewDidLoad()
        
    }
    
    @objc private func didFinish() {
        guard let myItem = self.item else {
            return
        }
        
        if (!myItem.finished) {
            // day interval for today
            let todayStart = Calendar.current.startOfDay(for: Date())
            let todayEnd: Date = {
              let components = DateComponents(day: 1, second: -1)
              return Calendar.current.date(byAdding: components, to: todayStart)!
            }()
            
            let dayEval = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", todayStart, todayEnd)
            
            realm.beginWrite()
            
            myItem.finished = true
            
            if (myItem.checkIn) {
                
                // suppose startTime was yesterday.
                let yesterdayStart = Calendar.current.startOfDay(for: myItem.startTime)
                
                let yesterdayEnd: Date = {
                    let components = DateComponents(day: 1, second: -1)
                    return Calendar.current.date(byAdding: components, to: yesterdayStart)!
                }()
                
                if yesterdayEnd.timeIntervalSinceNow < 0 {
                    // yesterdayEnd is earlier than now. Spaning two days. Ignore problem with multiple days: that is usually not possible.
                    
                    let elapsedTime = -myItem.startTime.timeIntervalSince(yesterdayEnd) / 3600.0
                    myItem.timeSpent += elapsedTime;
                    
                    let dayEval2 = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", yesterdayStart, yesterdayEnd)
                    
                    if (dayEval2.first == nil) {
                        //print("initializing record")
                        let newDayEval = dailyPerfEval()
                        newDayEval.tot_time += elapsedTime
                        newDayEval.date = myItem.startTime
                        realm.add(newDayEval)
                    } else {
                        //print("original record %f", dayEval.first?.tot_time)
                        dayEval2.first?.tot_time += elapsedTime
                    }
                    // Change startTime to today
                    myItem.startTime = todayStart
                }
                
                let elapsedTime = -myItem.startTime.timeIntervalSinceNow / 3600.0
                
                myItem.timeSpent += elapsedTime;
                myItem.checkIn = false
                
                if (dayEval.first == nil) {
                    //print("initializing record")
                    let newDayEval = dailyPerfEval()
                    newDayEval.tot_time += elapsedTime
                    newDayEval.tot_finish += myItem.budget
                    realm.add(newDayEval)
                } else {
                    //print("original record %f", dayEval.first?.tot_time)
                    dayEval.first?.tot_time += elapsedTime
                    dayEval.first?.tot_finish += myItem.budget
                }
                
                // Remove associated notifications on check-out
                if self.canNotify {
                    DispatchQueue.main.async {
                        
                        self.center.removePendingNotificationRequests(withIdentifiers: [myItem.item])
                        
                    }
                }
                
            } else {
                dayEval.first?.tot_finish += myItem.budget
                //print(dayEval.first?.tot_finish)
            }
            myItem.startTime = Date()
            
            try! realm.commitWrite()
            
            deletionHandler?()
            
            let alert = UIAlertController(title: "Finished!", message: "You finished work equivalent of " + String(myItem.budget) + "hours.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
            
        }
        
    }
    
    @objc private func didPartialFinish() {
        guard let myItem = self.item else {
            return
        }
        
        if (!myItem.finished) {
            // day interval for today
            let todayStart = Calendar.current.startOfDay(for: Date())
            let todayEnd: Date = {
              let components = DateComponents(day: 1, second: -1)
              return Calendar.current.date(byAdding: components, to: todayStart)!
            }()
            
            let dayEval = realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", todayStart, todayEnd)
            
            realm.beginWrite()
            
            //myItem.finished = true //Logging partial completion won't apply finish tag now.
            
            var ratio = 1.0
            
            let alert = UIAlertController(title: "Log completion!", message: "Input finished ratio in decimal", preferredStyle: .alert)
            
            alert.addTextField{ textField in
                textField.placeholder = "Ratio"
                //textField.isSecureTextEntry = true
            }
            
            //alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            let confirmAction = UIAlertAction(title: "Log w/o finish", style: .default) {
                [self, weak alert] _ in
                guard let alertController = alert, let textField = alertController.textFields?.first else { return }
                
                //print("Current password \(String(describing: textField.text))")
                
                ratio = Double(textField.text!) ?? 0.0
                
                //print(ratio)
                                
                if (myItem.checkIn) {
                    
                    let yesterdayStart = Calendar.current.startOfDay(for: myItem.startTime)
                    let yesterdayEnd: Date = {
                        let components = DateComponents(day: 1, second: -1)
                        return Calendar.current.date(byAdding: components, to: yesterdayStart)!
                      }()
                    
                    if yesterdayEnd.timeIntervalSinceNow < 0 {
                        // yesterdayEnd is earlier than now. Spaning two days. Ignore problem with multiple days: that is usually not possible.
                        
                        let elapsedTime = -myItem.startTime.timeIntervalSince(yesterdayEnd) / 3600.0
                        myItem.timeSpent += elapsedTime;
                        
                        let dayEval2 = self.realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", yesterdayStart, yesterdayEnd)
                        
                        if (dayEval2.first == nil) {
                            //print("initializing record")
                            let newDayEval = dailyPerfEval()
                            newDayEval.tot_time += elapsedTime
                            newDayEval.date = myItem.startTime
                            self.realm.add(newDayEval)
                        } else {
                            //print("original record %f", dayEval.first?.tot_time)
                            dayEval2.first?.tot_time += elapsedTime
                        }
                        // Change startTime to today
                        myItem.startTime = todayStart
                    }
                    
                    let elapsedTime = -myItem.startTime.timeIntervalSinceNow / 3600.0
                    
                    myItem.timeSpent += elapsedTime;
                    myItem.checkIn = false
                    
                    if (dayEval.first == nil) {
                        //print("initializing record")
                        let newDayEval = dailyPerfEval()
                        newDayEval.tot_time += elapsedTime
                        newDayEval.tot_finish += myItem.budget * ratio
                        self.realm.add(newDayEval)
                    } else {
                        //print("original record %f", dayEval.first?.tot_time)
                        dayEval.first?.tot_time += elapsedTime
                        dayEval.first?.tot_finish += myItem.budget * ratio
                    }
                    
                    // Remove associated notifications on check-out
                    if self.canNotify {
                        DispatchQueue.main.async {
                            
                            self.center.removePendingNotificationRequests(withIdentifiers: [myItem.item])
                            
                        }
                    }
                    
                } else {
                    // Item not checked in. No guarantee that anything is checked in on the day logging this item. If today's record is not initiated, initiate it.
                    
                    if (dayEval.first == nil) {
                        //print("initializing record")
                        let newDayEval = dailyPerfEval()
                        newDayEval.tot_finish += myItem.budget * ratio
                        self.realm.add(newDayEval)
                    } else {
                        //print("original record %f", dayEval.first?.tot_time)
                        dayEval.first?.tot_finish += myItem.budget * ratio
                    }
                }
                
                // Subtract used budget from both the time spent and the budget to reflect the left over task load.
                let usedBudget = ratio * myItem.budget
                myItem.budget -= min(usedBudget, myItem.budget) // budget can only go to 0.
                myItem.timeSpent -= min(usedBudget, myItem.timeSpent) // time spent can only go to 0.
                myItem.startTime = Date()
                try! self.realm.commitWrite()
                // Update view.
                self.viewDidLoad()
            }
            
            let confirmAction2 = UIAlertAction(title: "Log & finish", style: .default) {
                [self, weak alert] _ in
                guard let alertController = alert, let textField = alertController.textFields?.first else { return }
                
                //print("Current password \(String(describing: textField.text))")
                
                ratio = Double(textField.text!) ?? 0.0
                
                //print(ratio)
                                
                if (myItem.checkIn) {
                    
                    let yesterdayStart = Calendar.current.startOfDay(for: myItem.startTime)
                    let yesterdayEnd: Date = {
                        let components = DateComponents(day: 1, second: -1)
                        return Calendar.current.date(byAdding: components, to: yesterdayStart)!
                      }()
                    
                    if yesterdayEnd.timeIntervalSinceNow < 0 {
                        // yesterdayEnd is earlier than now. Spaning two days. Ignore problem with multiple days: that is usually not possible.
                        
                        let elapsedTime = -myItem.startTime.timeIntervalSince(yesterdayEnd) / 3600.0
                        myItem.timeSpent += elapsedTime;
                        
                        let dayEval2 = self.realm.objects(dailyPerfEval.self).filter("date BETWEEN {%@, %@}", yesterdayStart, yesterdayEnd)
                        
                        if (dayEval2.first == nil) {
                            //print("initializing record")
                            let newDayEval = dailyPerfEval()
                            newDayEval.tot_time += elapsedTime
                            newDayEval.date = myItem.startTime
                            self.realm.add(newDayEval)
                        } else {
                            //print("original record %f", dayEval.first?.tot_time)
                            dayEval2.first?.tot_time += elapsedTime
                        }
                        // Change startTime to today
                        myItem.startTime = todayStart
                    }
                    
                    let elapsedTime = -myItem.startTime.timeIntervalSinceNow / 3600.0
                    
                    myItem.timeSpent += elapsedTime;
                    myItem.checkIn = false
                    
                    if (dayEval.first == nil) {
                        //print("initializing record")
                        let newDayEval = dailyPerfEval()
                        newDayEval.tot_time += elapsedTime
                        newDayEval.tot_finish += myItem.budget * ratio
                        self.realm.add(newDayEval)
                    } else {
                        //print("original record %f", dayEval.first?.tot_time)
                        dayEval.first?.tot_time += elapsedTime
                        dayEval.first?.tot_finish += myItem.budget * ratio
                    }
                    
                    // Remove associated notifications on check-out
                    if self.canNotify {
                        DispatchQueue.main.async {
                            
                            self.center.removePendingNotificationRequests(withIdentifiers: [myItem.item])
                            
                        }
                    }
                    
                } else {
                    // Item not checked in. No guarantee that anything is checked in on the day logging this item. If today's record is not initiated, initiate it.
                    
                    if (dayEval.first == nil) {
                        //print("initializing record")
                        let newDayEval = dailyPerfEval()
                        newDayEval.tot_finish += myItem.budget * ratio
                        self.realm.add(newDayEval)
                    } else {
                        //print("original record %f", dayEval.first?.tot_time)
                        dayEval.first?.tot_finish += myItem.budget * ratio
                    }
                }
                
                // Subtract used budget from both the time spent and the budget to reflect the left over task load.
                let usedBudget = ratio * myItem.budget
                myItem.budget -= min(usedBudget, myItem.budget) // budget can only go to 0.
                myItem.timeSpent -= min(usedBudget, myItem.timeSpent) // time spent can only go to 0.
                myItem.finished = true
                myItem.startTime = Date()
                try! self.realm.commitWrite()
                // Update view.
                self.viewDidLoad()
            }
            
            alert.addAction(confirmAction)
            alert.addAction(confirmAction2)
            
            self.present(alert, animated: true)
            
        }
        
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
