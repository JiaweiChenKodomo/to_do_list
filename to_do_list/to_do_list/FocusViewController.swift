//
//  FocusViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 2/5/22.
//


import UIKit
import SwiftUI

class FocusViewController: UIViewController {
    
    //public var item: checkListItem?
    
    public var completionHandler: (() -> Void)?
    
    public var startFocus: Date?
    
    public var checkInTime: Date?
    
    var timer: Timer!
    
    let formatter = DateComponentsFormatter()
    
    
    @IBOutlet var label: UILabel!
    @IBOutlet var label2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let time_elapsed = -(self.startFocus?.timeIntervalSinceNow ?? 0)
        let time_elapsed2 = -(self.checkInTime?.timeIntervalSinceNow ?? 0)
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [ .pad ]
        
        let formattedString = formatter.string(from: TimeInterval(time_elapsed))!
        let formattedString2 = formatter.string(from: TimeInterval(time_elapsed2))!
        
        label.text = formattedString
        label2.text = formattedString2
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        
        
    }
    
    @objc func step() {
        let time_elapsed = -(self.startFocus?.timeIntervalSinceNow ?? 0)
        let time_elapsed2 = -(self.checkInTime?.timeIntervalSinceNow ?? 0)
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [ .pad ]
        
        let formattedString = formatter.string(from: TimeInterval(time_elapsed))!
        let formattedString2 = formatter.string(from: TimeInterval(time_elapsed2))!
        
        label.text = formattedString
        label2.text = formattedString2
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
