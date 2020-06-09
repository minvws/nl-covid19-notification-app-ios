import UIKit

extension NSAttributedString {
  static func make(text: String, font: UIFont, textColor: UIColor, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = textAlignment
    var attributes: [Key: Any] = [
      .foregroundColor: textColor,
      .font: font,
      .paragraphStyle: paragraphStyle
    ]
    if let underlineColor = underlineColor {
      attributes[.underlineColor] = underlineColor
      attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }
    return NSAttributedString(string: text, attributes: attributes)
  }
}
