//
//  UIConstants.swift
//  TestDemo
//
//  Created by Kiro on 2025/8/6.
//

import UIKit

struct UIConstants {
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Button Heights
    struct ButtonHeight {
        static let small: CGFloat = 32
        static let medium: CGFloat = 44
        static let large: CGFloat = 56
    }
    
    // MARK: - Animation Duration
    struct Animation {
        static let fast: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
    }
}

// MARK: - Color Extensions
extension UIColor {
    struct App {
        static let primary = UIColor.systemBlue
        static let secondary = UIColor.systemGray
        static let accent = UIColor.systemOrange
        static let background = UIColor.systemBackground
        static let surface = UIColor.secondarySystemBackground
        static let error = UIColor.systemRed
        static let success = UIColor.systemGreen
        static let warning = UIColor.systemYellow
    }
}