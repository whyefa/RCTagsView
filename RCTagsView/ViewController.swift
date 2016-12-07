//
//  ViewController.swift
//  RCTagsView
//
//  Created by Developer on 2016/12/5.
//  Copyright © 2016年 Beijing Haitao International Travel Service Co., Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, RCTagsViewDelegate {


    @IBOutlet weak var tagView: RCTagsView!

    @IBOutlet weak var tagHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
//        let tagv = RCTagsView(frame: CGRect(x: 30, y: 30, width: UIScreen.main.bounds.width, height: 120))
//        tagv.textField.placeholder = "Add tag"
//        tagv.textField.returnKeyType = .done
//        tagv.textField.delegate = self
//        tagv.addTag(title: "僵尸扥啊发发泛滥看老敬老")
//        view.addSubview(tagv)
        tagView.textField.placeholder = "Add tag ..."
        tagView.textField.returnKeyType = UIReturnKeyType.done
        tagView.textField.delegate = self

        let text = "AAA BBB CCC DDD EEE FFF GGG HHH III JJJ KKK LLL"
        tagView.removeAllTags()
        for word in text.components(separatedBy: " ") {
            if word.characters.count > 0 {
                tagView.addTag(title: word)
            }
        }
    }

    @IBAction func changeEditable(_ sender: UISwitch) {
        tagView.isEditable = sender.isOn
    }

    @IBAction func changeSelectable(_ sender: UISwitch) {
        tagView.isSelectable = sender.isOn
    }
    

    @IBAction func changeMulti(_ sender: UISwitch) {
        tagView.isMultipleSelectable = sender.isOn
    }


    @IBAction func changeButtonStyle(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            tagView.delegate = nil
        } else {
            tagView.delegate = self
        }
        tagView.reloadButtons()
    }

    @IBAction func changeHeightConstraint(_ sender: UISwitch) {
        tagHeight.priority = sender.isOn ? 999 : 1
        view.layoutIfNeeded()
    }


    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @IBAction func changeScrollDirection(_ sender: UISwitch) {
        tagView.isScrollsHorizontally = sender.isOn
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

