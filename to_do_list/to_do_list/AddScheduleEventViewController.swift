//
//  AddScheduleEventViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 1/15/23.
//

import Foundation
import UIKit
import EventKit
import SwiftUI

class AddScheduleEventViewController: UIViewController, UITextFieldDelegate {
    
    private var store = EKEventStore()
    
    public var completionHandler: (() -> Void)?
    
    @IBOutlet weak var itemNameField: UITextField!
    
    @IBOutlet weak var itemLocationField: UITextField!

    @IBOutlet weak var allDay: UISwitch!
    
    @IBOutlet weak var startDateTime: UIDatePicker!
    
    @IBOutlet weak var endDateTimeField: UIDatePicker!
    
    @IBOutlet weak var repeatPeriodField: UITextField!
    
    var periodUnit = EKRecurrenceFrequency.daily
    
    @IBOutlet weak var periodUnitBut: UIButton!
    
    @IBOutlet weak var repeatEndTimeField: UIDatePicker!
    
    @IBOutlet weak var returnTimesField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemNameField.delegate = self
        itemLocationField.delegate = self
        repeatPeriodField.delegate = self
        returnTimesField.delegate = self
        
        periodUnitBut.menu = UIMenu(children: [
            UIAction(title: "days", handler: { action in
                self.periodUnit = EKRecurrenceFrequency.daily
            }),
            UIAction(title: "weeks", handler: { action in
                self.periodUnit = EKRecurrenceFrequency.weekly
            }),
            UIAction(title: "months", handler: { action in
                self.periodUnit = EKRecurrenceFrequency.monthly
            })]
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        
    }
    
    
    @IBAction func didTapAllDay(_ sender: Any) {
        if allDay.isOn {
            startDateTime.datePickerMode = UIDatePicker.Mode.date
            endDateTimeField.datePickerMode = UIDatePicker.Mode.date
        } else {
            startDateTime.datePickerMode = UIDatePicker.Mode.dateAndTime
            endDateTimeField.datePickerMode = UIDatePicker.Mode.dateAndTime
        }
        viewDidLoad()
    }
    
    // Text field behavior
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    }
    
    @objc func didTapSave() {
        let title = self.itemNameField.text
        let location = self.itemLocationField.text
        let start = startDateTime.date
        let end = endDateTimeField.date
        
        // Repeat options
        let period = Int(repeatPeriodField.text ?? "0")
        let repeatTime = Int(returnTimesField.text ?? "0")
        let repeatEndTime = repeatEndTimeField.date
        
        // Build EK event
        store.requestAccess(to: .event) { success , error in
            if success, error == nil {
                DispatchQueue.main.async {
                    let store = self.store
                    
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.calendar = store.defaultCalendarForNewEvents
                    newEvent.title = title
                    newEvent.startDate = start
                    newEvent.endDate = end
                    newEvent.location = location
                    newEvent.isAllDay = self.allDay.isOn
                    
                    if (period ?? 0 > 0 && (repeatTime ?? 0 > 0 || repeatEndTime.timeIntervalSince(end) > 86400)) {
                        if (repeatTime ?? 0 > 0) {
                            let repeatEnd = EKRecurrenceEnd(occurrenceCount: repeatTime ?? 0)
                            let recurrenceRule = EKRecurrenceRule(recurrenceWith: self.periodUnit, interval: period!, end: repeatEnd)
                            newEvent.recurrenceRules?.append(recurrenceRule)
                        } else if (repeatEndTime.timeIntervalSince(end) > 86400) {
                            let repeatEnd = EKRecurrenceEnd(end: repeatEndTime)
                            let recurrenceRule = EKRecurrenceRule(recurrenceWith: self.periodUnit, interval: period!, end: repeatEnd)
                            newEvent.recurrenceRules?.append(recurrenceRule)
                        }
                    }
                    try! store.save(newEvent, span: .thisEvent)
                    try! store.commit()
                }
            }
        }
        // Go back to previous page
        completionHandler?()
        navigationController?.popToRootViewController(animated: true)
    }
    
}
