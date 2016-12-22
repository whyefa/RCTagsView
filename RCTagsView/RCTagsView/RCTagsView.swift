
//
//  RCTagsView.swift
//  RCTagsView
//
//  Created by Developer on 2016/12/5.
//  Copyright © 2016年 Beijing Haitao International Travel Service Co., Ltd. All rights reserved.
//  from: RKTagsView @ github

import UIKit

public enum RCTagsViewTextFieldAlign: Int { // align is relative to a last tag
    case top
    case center
    case bottom
}

var RCTagsViewAutomaticDimension: CGFloat = -0.0001 // use sizeToFit

@objc public protocol RCTagsViewDelegate: NSObjectProtocol {
    @objc optional func tagsView(tagsView: RCTagsView, buttonForTagAt index: Int) -> UIButton //used default tag button if not implemented 
    @objc optional func  tagsView(tagsView: RCTagsView, shouldAddTag text: String) -> Bool // called when 'space' key pressed. return false to ignore tag

    @objc optional func  tagsView(tagsView: RCTagsView, shouldSelectTagAt index: Int) -> Bool // called when tag pressed. return false to disallow selecting tag

    @objc optional func  tagsView(tagsView: RCTagsView, shouldDeselectTagAt index: Int) -> Bool //called when selected tag pressed. return false to disallow deslecting tag

    @objc optional func  tagsView(tagsView: RCTagsView, shouldRemoveTagAt index: Int) -> Bool // called when tag was added or removing tag

    @objc optional func  tagsViewDidChange(tagsView: RCTagsView) // called when tag was added or removed by user

    @objc optional func  tagsViewContentSizeDidChange(tagsView: RCTagsView)

}



public class RCTagsView: UIView {

    // MARK: - const
    let default_button_tag = -9999
    let default_button_horizontal_padding: CGFloat = 6
    let default_button_vertical_padding: CGFloat = 2
    let default_button_corner_radius: CGFloat = 6
    let default_button_border_width: CGFloat = 1

    // MARK: - public property
    // delegate 
    var delegate: RCTagsViewDelegate?

    var font: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            inputTextField.font = font
            for button in mutableTagButtons {
                if button.tag == default_button_tag {
                    button.titleLabel?.font = font
                    button.sizeToFit()
                    setNeedsLayout()
                }
            }
        }
    }// default is font as flowing

    var isEditable: Bool = true {
        didSet {
            if isEditable {
                inputTextField.isHidden = false
                becomeFirstResponderButton.isHidden = inputTextField.isFirstResponder
            } else {
                endEditing(true)
                inputTextField.text = ""
                inputTextField.isHidden = true
                becomeFirstResponderButton.isHidden = true
            }
            setNeedsLayout()
        }
    }// default is true


    var isSelectable: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }// default is true

    var isMultipleSelectable: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }// default is true

    var selectBeforeRemoveOnDeleteBackward: Bool = true // default is true

    var deselectAllOnEditing: Bool = true // default is true

    var deslectAllOnEndEditing: Bool = true // default is true

    var isScrollsHorizontally: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }// default is false

    var lineSpacing: CGFloat = 2 {
        didSet {
            setNeedsLayout()
        }
    }// default is 2

    var interitemSpacing: CGFloat = 4 {
        didSet {
            setNeedsLayout()
        }
    }// default is 2

    var tagButtonHeight: CGFloat! {
        didSet {
            setNeedsLayout()
        }
    }// default is auto

    var textFieldHeight: CGFloat! {
        didSet {
            setNeedsLayout()
        }
    }// default is auto

    var textFieldAlign: RCTagsViewTextFieldAlign = .center {
        didSet {
            setNeedsLayout()
        }
    }// default is center

    var deliminater: CharacterSet = CharacterSet.whitespaces // defailt is whitespaceCharacterSet

    var textField: UITextField {
        get {
            return inputTextField
        }
    }

    // MARK: - private properties
    fileprivate var mutableTags = [String]()

    fileprivate var mutableTagButtons = [UIButton]()

    fileprivate var scrollView: UIScrollView!

    fileprivate var inputTextField: RCInputTextField!

    fileprivate var becomeFirstResponderButton: UIButton!

    fileprivate var needScrollToBottomAfterLayout: Bool = true

    override public var tintColor: UIColor! {
        didSet {
            inputTextField.tintColor = tintColor
            for button in mutableTagButtons {
                if button.tag == default_button_tag {
                    button.tintColor = tintColor
                    button.layer.borderColor = tintColor.cgColor
                    button.backgroundColor = button.isSelected ? tintColor : nil
                    button.setTitleColor(tintColor, for: .normal)
                }
            }
        }
    }




    // MARK: - public methods
    func indexForTag(atScrollView point: CGPoint) -> Int {
        for index in 0..<mutableTagButtons.count {
            if mutableTagButtons[index].frame.contains(point) {
                return index
            }
        }
        return NSNotFound
    }

    func buttonForTag(at index: Int) -> UIButton? {
        if index >= 0 && index < mutableTagButtons.count {
            return mutableTagButtons[index]
        }
        return nil
    }

    func reloadButtons() {
        let allTags = tags
        removeAllTags()
        for tag in allTags {
            addTag(title: tag)
        }
    }

    func  addTag(title: String) {
        insertTag(title: title, at: mutableTags.count)
    }

    func insertTag(title: String, at index: Int) {
        if index >= 0 && index <= mutableTags.count {
            mutableTags.insert(title, at: index)
            var tagButton: UIButton
            let buttonForTagMethod = delegate?.tagsView(tagsView:buttonForTagAt:)
            if buttonForTagMethod != nil {
                tagButton = (delegate?.tagsView!(tagsView: self, buttonForTagAt: index))!
            } else {
                tagButton = UIButton(type: .custom)
                tagButton.layer.cornerRadius = default_button_corner_radius
                tagButton.layer.borderColor = tintColor.cgColor
                tagButton.layer.borderWidth = default_button_border_width
                tagButton.titleLabel?.font = font
                tagButton.tintColor = tintColor
                tagButton.titleLabel?.lineBreakMode = .byTruncatingTail
                tagButton.setTitle(title, for: .normal)
                tagButton.setTitleColor(tintColor, for: .normal)
                tagButton.setTitleColor(.white, for: .selected)
                tagButton.contentEdgeInsets = UIEdgeInsetsMake(default_button_vertical_padding, default_button_horizontal_padding, default_button_vertical_padding, default_button_horizontal_padding)
                tagButton.tag = default_button_tag
            }
            tagButton.sizeToFit()
            tagButton.isExclusiveTouch = true
            tagButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
            mutableTagButtons.insert(tagButton, at: index)
            scrollView.addSubview(tagButton)
            setNeedsLayout()
        }
    }

    func moveTag(from index: Int, toIndex: Int) {
        if index >= 0 && index <= mutableTags.count && toIndex >= 0 && toIndex <= mutableTags.count && index != toIndex {
            let tag = mutableTags[index]
            let button = mutableTagButtons[index]
            mutableTags.remove(at: index)
            mutableTagButtons.remove(at: index)
            mutableTags.insert(tag, at: toIndex)
            mutableTagButtons.insert(button, at: toIndex)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    func removeTag(at index: Int) {
        if index >= 0 && index < mutableTags.count {
            mutableTags.remove(at: index)
            mutableTagButtons[index].removeFromSuperview()
            mutableTagButtons.remove(at: index)
            setNeedsLayout()
        }
    }

    func removeAllTags() {
        mutableTags.removeAll()
        for button in mutableTagButtons {
            button.removeFromSuperview()
        }
        mutableTagButtons.removeAll()
        setNeedsLayout()
    }

    func selectTag(at index: Int) {
        if index >= 0 && index < mutableTagButtons.count {
            if !isMultipleSelectable {
                deselectAll()
            }
            mutableTagButtons[index].isSelected = true
            if mutableTagButtons[index].tag == default_button_tag {
                mutableTagButtons[index].backgroundColor = tintColor
            }
        }
    }

    func deselectTag(at index: Int) {
        if index >= 0 && index < mutableTagButtons.count {
            mutableTagButtons[index].isSelected = false
            if mutableTagButtons[index].tag == default_button_tag {
                mutableTagButtons[index].backgroundColor = nil
            }
        }
    }

    func selectAll() {
        for index in 0..<mutableTagButtons.count {
            selectTag(at: index)
        }
    }

    func deselectAll() {
        for index in 0..<mutableTagButtons.count {
            deselectTag(at: index)
        }
    }


    // MARK: - init 
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    func setup() {
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = nil
        self.addSubview(scrollView)

        inputTextField = RCInputTextField()
        inputTextField.tagsView = self
        inputTextField.tintColor = self.tintColor
        inputTextField.autocapitalizationType = .none
        inputTextField.addTarget(self, action: #selector(inputTextFieldChanged), for: .editingChanged)
        inputTextField.addTarget(self, action: #selector(inputTestFieldEditingDidBegin), for: .editingDidBegin)
        inputTextField.addTarget(self, action: #selector(intputTextFieldEditingDidEnd), for: .editingDidEnd)
        scrollView.addSubview(inputTextField)

        becomeFirstResponderButton = UIButton(frame: self.bounds)
        becomeFirstResponderButton.backgroundColor = nil
        becomeFirstResponderButton.addTarget(inputTextField, action: #selector(becomeFirstResponder), for: .touchUpInside)
        scrollView.insertSubview(becomeFirstResponderButton, at: 0)

        tagButtonHeight = RCTagsViewAutomaticDimension
        textFieldHeight = RCTagsViewAutomaticDimension
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        var contentWidth: CGFloat = bounds.width - scrollView.contentInset.left - scrollView.contentInset.right
        var lowerFrame:CGRect = .zero
        //layout tag buttons 
        var previousButtonFrame: CGRect = .zero
        for button in mutableTagButtons {
            var buttonFrame = originalFrame(view: button)
            if isScrollsHorizontally || previousButtonFrame.maxX + interitemSpacing + buttonFrame.width <= contentWidth {
                buttonFrame.origin.x = previousButtonFrame.maxX

                if buttonFrame.origin.x > 0 {
                    buttonFrame.origin.x += interitemSpacing
                }
                buttonFrame.origin.y = previousButtonFrame.minY
                if isScrollsHorizontally && buttonFrame.maxX > bounds.width {
                    contentWidth = buttonFrame.maxX + interitemSpacing
                }
            } else {
                buttonFrame.origin.x = 0
                buttonFrame.origin.y = max(lowerFrame.maxY, previousButtonFrame.maxY)
                if buttonFrame.origin.y > 0 {
                    buttonFrame.origin.y += lineSpacing
                }
                if buttonFrame.size.width > contentWidth {
                    buttonFrame.size.width = contentWidth
                }
            }
            if tagButtonHeight > RCTagsViewAutomaticDimension {
                buttonFrame.size.height = tagButtonHeight
            }
            setView(button, originalFrame: buttonFrame)
            previousButtonFrame = buttonFrame
            if lowerFrame.maxY < buttonFrame.maxY {
                lowerFrame = buttonFrame
            }
        }
        if isEditable {
            inputTextField.sizeToFit()
            var textFieldFrame = originalFrame(view: inputTextField)
            if textFieldHeight > RCTagsViewAutomaticDimension {
                textFieldFrame.size.height = textFieldHeight
            }
            if mutableTagButtons.count == 0 {
                textFieldFrame.origin.x = 0
                textFieldFrame.origin.y = 0
                textFieldFrame.size.width = contentWidth
                lowerFrame = textFieldFrame
            } else if (isScrollsHorizontally || previousButtonFrame.maxX + interitemSpacing + textFieldFrame.width <= contentWidth) {
                textFieldFrame.origin.x = interitemSpacing + previousButtonFrame.maxX
                switch textFieldAlign {
                case .top:
                    textFieldFrame.origin.y = previousButtonFrame.minY
                    break
                case .center:
                    textFieldFrame.origin.y = previousButtonFrame.minY + (previousButtonFrame.height-textFieldFrame.size.height)/2
                    break
                case .bottom:
                    textFieldFrame.origin.y = previousButtonFrame.maxY - textFieldFrame.height
                    break
                }
                if isScrollsHorizontally {
                    textFieldFrame.size.width = inputTextField.bounds.width
                    if textFieldFrame.maxX > bounds.width {
                        contentWidth += textFieldFrame.width
                    }
                } else {
                    textFieldFrame.size.width = contentWidth - textFieldFrame.origin.x
                }

                if lowerFrame.maxY < textFieldFrame.maxY {
                    lowerFrame = textFieldFrame
                }
            } else {
                textFieldFrame.origin.x = 0
                switch textFieldAlign {
                case .top:
                    textFieldFrame.origin.y = previousButtonFrame.maxY + lineSpacing
                    break
                case .center:
                    textFieldFrame.origin.y = previousButtonFrame.maxY + lineSpacing + (previousButtonFrame.height - textFieldFrame.height)/2
                    break
                case .bottom:
                    textFieldFrame.origin.y = previousButtonFrame.maxY + lineSpacing + (previousButtonFrame.height - textFieldFrame.height)/2
                    break
                }
                textFieldFrame.size.width = contentWidth
                let nextButtonFrame = CGRect(x: 0, y: previousButtonFrame.maxY + lineSpacing, width: 0, height: previousButtonFrame.size.height)
                lowerFrame = textFieldFrame.maxY < nextButtonFrame.maxY ?  nextButtonFrame : textFieldFrame
            }
            setView(inputTextField, originalFrame: textFieldFrame)
        }
        //set content size
        let oldContentSize = contentSize
        scrollView.contentSize = CGSize(width: contentWidth, height: lowerFrame.maxY)
        if (isScrollsHorizontally && contentWidth > bounds.width) || (!isScrollsHorizontally && oldContentSize.height != contentSize.height) {
            invalidateIntrinsicContentSize()
            let contentSizeChanged = delegate?.tagsViewContentSizeDidChange(tagsView:)
            if contentSizeChanged != nil {
                delegate?.tagsViewDidChange!(tagsView: self)
            }
        }
        // lay out becomeFirstResponder button 
        becomeFirstResponderButton.frame = CGRect(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top, width: contentSize.width, height: contentSize.height)
        scrollView.bringSubview(toFront: becomeFirstResponderButton)
    }

    
    override public var intrinsicContentSize: CGSize {
        get {
            return contentSize
        }
    }

    // MARK: - property accessors

    fileprivate var tags: [String] {
        get {
            return mutableTags
        }
    }

    fileprivate var selectedTagIndexes: [Int] {
        get {
            var mutableIndexes = [Int]()
            for i in 0..<mutableTagButtons.count {
                if mutableTagButtons[i].isSelected {
                    mutableIndexes.append(i)
                }
            }
            return mutableIndexes
        }
    }

    var contentSize: CGSize {
        get {
            return CGSize(width: isScrollsHorizontally ? (scrollView.contentSize.width + scrollView.contentInset.left + scrollView.contentInset.right) : bounds.width, height: scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom)
        }
    }

    // MARK: - handlers 

    func inputTextFieldChanged() {
        if deselectAllOnEditing {
            deselectAll()
        }
        var tags = (inputTextField.text!).components(separatedBy: deliminater)
        inputTextField.text = tags.last
        tags.removeLast()
        for tag in tags {
            if tag == "" {
                continue
            }
            let addTag = delegate?.tagsView(tagsView:shouldAddTag:)
            if (addTag != nil && !(delegate?.tagsView!(tagsView: self, shouldAddTag: tag))!) {
                continue
            }
            self.addTag(title: tag)
            let tagsViewDidChange = delegate?.tagsViewDidChange(tagsView:)
            if tagsViewDidChange != nil {
                delegate?.tagsViewDidChange!(tagsView: self)
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
        weak var weakSelf: RCTagsView! = self
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute:{
            if weakSelf.isScrollsHorizontally {
                if weakSelf.scrollView.contentSize.width > weakSelf.bounds.width  {
                    let leftOffset = CGPoint(x: weakSelf.scrollView.contentSize.width - weakSelf.bounds.width, y: -weakSelf.scrollView.contentInset.top)
                    weakSelf.scrollView.setContentOffset(leftOffset, animated: true)
                }
            }else {
                if weakSelf.scrollView.contentInset.top + weakSelf.scrollView.contentSize.height > weakSelf.bounds.size.height {
                    let bottomOffset = CGPoint(x: -weakSelf.scrollView.contentInset.left, y: weakSelf.scrollView.contentSize.height - weakSelf.bounds.height - (-weakSelf.scrollView.contentInset.top))
                    weakSelf.scrollView.setContentOffset(bottomOffset, animated: true)
                }
            }
        })
    }

    func inputTestFieldEditingDidBegin() {
        becomeFirstResponderButton.isHidden = true
    }

    func intputTextFieldEditingDidEnd() {
        if inputTextField.text!.characters.count > 0 {
            inputTextField.text = inputTextField.text! + "  "
            inputTextFieldChanged()
        }
        if deslectAllOnEndEditing {
            deselectAll()
        }
        becomeFirstResponderButton.isHidden = !isEditable
    }

    fileprivate func shouldInputTextDeleteBackward() -> Bool{
        let tagIndexes = selectedTagIndexes
        if tagIndexes.count > 0 {
            var i = tagIndexes.count-1
            while i >= 0 {
                let shouldRemoveTagMethod = delegate?.tagsView(tagsView:shouldRemoveTagAt:)
                if shouldRemoveTagMethod != nil && !(delegate?.tagsView!(tagsView: self, shouldRemoveTagAt: i))! {
                    continue
                }
                removeTag(at: tagIndexes[i])
                let tagsViewDidChange = delegate?.tagsViewDidChange(tagsView:)
                if  tagsViewDidChange != nil {
                    delegate?.tagsViewDidChange!(tagsView: self)
                }
                i -= 1
            }
            return false
        } else if inputTextField.text! == "" && mutableTags.count > 0 {
            let lastTagIndex = mutableTags.count - 1
            if selectBeforeRemoveOnDeleteBackward {
                let method = delegate?.tagsView(tagsView:shouldSelectTagAt:)
                if method != nil && (delegate?.tagsView!(tagsView: self, shouldSelectTagAt: lastTagIndex))! {
                    return false
                } else {
                    selectTag(at: lastTagIndex)
                    return false
                }
            } else {
                let method = delegate?.tagsView(tagsView:shouldRemoveTagAt:)
                if method != nil  && !(delegate?.tagsView!(tagsView: self, shouldRemoveTagAt: lastTagIndex))! {
                    return false
                } else {
                    removeTag(at: lastTagIndex)
                    let tasViewDidChange = delegate?.tagsViewDidChange(tagsView:)
                    if tasViewDidChange != nil {
                        delegate?.tagsViewDidChange!(tagsView: self)
                    }
                    return false
                }
            }
        } else {
            return true
        }
    }

    func tapped(button: UIButton) {
        if isSelectable {
            let buttonIndex: Int! = mutableTagButtons.index(of: button)
            if button.isSelected {
                let shouldDeselectMethod = delegate?.tagsView(tagsView:shouldDeselectTagAt:)
                if shouldDeselectMethod != nil && !(delegate?.tagsView!(tagsView: self, shouldDeselectTagAt: buttonIndex))!{
                    return
                }
                deselectTag(at: buttonIndex)
            } else {
                let shouldSelectMethod = delegate?.tagsView(tagsView:shouldSelectTagAt:)
                if shouldSelectMethod != nil && (delegate?.tagsView!(tagsView: self, shouldSelectTagAt: buttonIndex))! {
                    return
                }
                selectTag(at: buttonIndex)
            }
        }
    }

    // MARK: - internal helpers
    func originalFrame(view: UIView) -> CGRect{
        if CGAffineTransform.identity == view.transform {
            return view.frame
        } else {
            let currentTransform = view.transform
            view.transform = CGAffineTransform.identity
            let originalFrame = view.frame
            view.transform = currentTransform
            return originalFrame
        }
    }

    func setView(_ view: UIView, originalFrame: CGRect) {
        if CGAffineTransform.identity == view.transform {
            view.frame = originalFrame
        } else {
            let currentTransform = view.transform
            view.transform = CGAffineTransform.identity
            view.frame = originalFrame
            view.transform = currentTransform
        }
    }

}


//MARK: - RCInputTextField
class RCInputTextField: UITextField {
    var tagsView: RCTagsView?

    override func deleteBackward() {
        if self.tagsView!.shouldInputTextDeleteBackward() {
            super.deleteBackward()
        }
    }
}



