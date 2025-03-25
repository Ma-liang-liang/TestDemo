//
//  UIView++.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

@resultBuilder
public struct SubviewBuilder {
    
    public static func buildBlock(_ subviews: UIView...) -> [UIView] {
        subviews
    }
    
    public static func buildEither(first component: [UIView]) -> [UIView] {
        component
    }
    
    public static func buildEither(second component: [UIView]) -> [UIView] {
        component
    }
    
    public static func buildArray(_ components: [[UIView]]) -> [UIView] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [UIView]?) -> [UIView] {
        component ?? []
    }
   
}

public extension UIView {
    
    func addSubviews(@SubviewBuilder _ builder: () -> [UIView]) {
        builder().forEach { addSubview($0) }
    }
}

extension UIView {
    
    func setShadow(size: CGSize, color: UIColor, radius: CGFloat, opacity: Float = 0.6) {
        layer.shadowOffset = size
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
    }
    
    func addRectCorner(corner: UIRectCorner, radius: CGFloat) {
        
        var corners: CACornerMask = []
        if corner.contains(.topLeft) {
            corners.insert(.layerMinXMinYCorner)
        }
        if corner.contains(.topRight) {
            corners.insert(.layerMaxXMinYCorner)
        }
        if corner.contains(.bottomLeft) {
            corners.insert(.layerMinXMaxYCorner)
        }
        if corner.contains(.bottomRight) {
            corners.insert(.layerMaxXMaxYCorner)
        }
        if corner.contains(.bottomRight) {
            corners.insert(.layerMaxXMaxYCorner)
        }
        if corner.contains(.allCorners) {
            corners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                       .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
        }
        layer.maskedCorners = corners
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}
