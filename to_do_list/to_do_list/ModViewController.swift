//
//  ModViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 11/25/21.
//

import RealmSwift
import UIKit

class ModViewController: UIViewController, UITextFieldDelegate {
    
    public var item: checkListItem?

    @IBOutlet var textField: UITextField!
    @IBOutlet var textFieldBudget: UITextField!
    @IBOutlet var datePicker: UIDatePicker!
    
    var textTagPopUp = UIButton()
    
    var yOffset = 600
    var textHeight = 21
    var fieldHeight = 52
    var sSpacing = 5
    var bSpacing = 15
    var startY = 0
    var xOffset = 50
    
    var tagID = 0

    private let realm = try! Realm()
    public var completionHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.becomeFirstResponder()
        textField.delegate = self
        textField.text = item?.item
        datePicker.setDate(item!.date, animated: true)
        textFieldBudget.delegate = self
        textFieldBudget.text = String(format: "%.1f", item!.budget)
        
        textTagPopUp.frame = CGRect(x: xOffset, y: startY+yOffset, width: 100, height: textHeight)
        var menuChildren: [UIMenuElement] = []
        
        for idx in 0...5 {
            menuChildren.append(UIAction(title: tagDic[idx] ?? " ", handler: actionClosure))
        }
        textTagPopUp.menu = UIMenu(children: menuChildren)
        textTagPopUp.showsMenuAsPrimaryAction = true
        textTagPopUp.changesSelectionAsPrimaryAction = true
        textTagPopUp.setTitleColor(.blue, for: .normal)
        textTagPopUp.backgroundColor = .lightGray
        tagID = item?.tag ?? 0
        textTagPopUp.setTitle(tagDic[tagID], for: .normal)
        self.view.addSubview(textTagPopUp)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
    }
    
    func actionClosure(action: UIAction) {
        if let key = tagDic.first(where: { $0.value == action.title })?.key {
            // use key
            tagID = key
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    }
    
    @objc func didTapSaveButton() {
        if let text = textField.text, !text.isEmpty {
            let date = datePicker.date
            let budget = Double(textFieldBudget.text!) ?? 0.0
            
            // write new item to realm
            realm.beginWrite()
            
            item!.date = date
            item!.item = text
            item!.budget = budget
            item!.tag = tagID
            
            try! realm.commitWrite()

            completionHandler?()
            navigationController?.popToRootViewController(animated: true)
        }
        else {
            //print("Add something")
        }
    }
    
}
