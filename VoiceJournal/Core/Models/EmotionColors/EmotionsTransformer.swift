//
//  EmotionsTransformer.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/15/24.
//

import Foundation
import SwiftUI

@objc(EmotionsTransformer)
class EmotionsTransformer: NSSecureUnarchiveFromDataTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let emotions = value as? [String] else { return nil }
        print("Transforming emotions: \(emotions)")
        return try? NSKeyedArchiver.archivedData(withRootObject: emotions, requiringSecureCoding: true)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        let emotions = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSString.self], from: data) as? [String]
        print("Reversing transformed emotions: \(emotions ?? [])")
        return emotions
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSString.self]
    }
}

@objc(EmotionColorsTransformer)
class EmotionColorsTransformer: NSSecureUnarchiveFromDataTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let colors = value as? [Color] else { return nil }
        let uiColors = colors.map { UIColor($0) }
        print("Transforming colors: \(colors)")
        return try? NSKeyedArchiver.archivedData(withRootObject: uiColors, requiringSecureCoding: true)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        if let uiColors = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, UIColor.self], from: data) as? [UIColor] {
            let colors = uiColors.map { Color($0) }
            print("Reversing transformed colors: \(colors)")
            return colors
        }
        return nil
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, UIColor.self]
    }
}
