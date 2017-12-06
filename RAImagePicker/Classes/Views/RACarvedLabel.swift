//
//  RACarvedLabel.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit

fileprivate typealias TextAttributes = [NSAttributedStringKey: Any]

/*
    RACarvedLabel: a label whose transparent text is carved into solid color.
        Note: text is always aligned to center.
 */
@IBDesignable
final class RACarvedLabel : UIView {
    
    @IBInspectable var text: String? {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    var font: UIFont? {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var verticalInset: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var horizontalInset: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _ = backgroundColor
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _ = backgroundColor
        isOpaque = false
    }
    
    override var backgroundColor: UIColor? {
        get { return UIColor.clear }
        set { super.backgroundColor = UIColor.clear }
    }
    
    fileprivate var textAttributes: TextAttributes {
        let activeFont = font ?? UIFont.systemFont(ofSize: 12, weight: .regular)
        return [
            NSAttributedStringKey.font: activeFont
        ]
    }
    
    fileprivate var attributedString: NSAttributedString {
        return NSAttributedString(string: text ?? "", attributes: textAttributes)
    }
    
    override func draw(_ rect: CGRect) {
        let color = tintColor!
        color.setFill()
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.fill()
        
        guard let context = UIGraphicsGetCurrentContext(), (text?.count ?? 0) > 0 else {
            return
        }
        
        let attributedString = self.attributedString
        let stringSize = attributedString.size()
        
        let xOrigin: CGFloat = max(horizontalInset, (rect.width - stringSize.width)/2)
        let yOrigin: CGFloat = max(verticalInset, (rect.height - stringSize.height)/2)
        
        context.saveGState()
        context.setBlendMode(.destinationOut)
        attributedString.draw(at: CGPoint(x: xOrigin, y: yOrigin))
        context.restoreGState()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let stringSize = attributedString.size()
        return CGSize(width: stringSize.width + horizontalInset*2, height: stringSize.height + verticalInset*2)
    }
    
    override var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }
}
