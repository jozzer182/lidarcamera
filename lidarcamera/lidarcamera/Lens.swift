//
//  Lens.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import SwiftUI
import AVFoundation

/// Represents the available camera lens modes
enum Lens: String, CaseIterable, Identifiable {
    case ultraWide
    case wide
    case tele
    case lidar
    
    var id: String { rawValue }
    
    /// Display label for the lens
    var label: String {
        switch self {
        case .ultraWide: return "0.5"
        case .wide: return "1×"
        case .tele: return "5"
        case .lidar: return "LiDAR"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .ultraWide: return "camera.aperture"
        case .wide: return "camera"
        case .tele: return "camera.fill"
        case .lidar: return "dot.radiowaves.left.and.right"
        }
    }
    
    /// The corresponding AVCaptureDevice.DeviceType for camera lenses
    var deviceType: AVCaptureDevice.DeviceType? {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide: return .builtInWideAngleCamera
        case .tele: return .builtInTelephotoCamera
        case .lidar: return nil // LiDAR doesn't use camera device directly
        }
    }
    
    /// Whether this lens requires switching the camera device
    var requiresCameraSwitch: Bool {
        return deviceType != nil
    }
}
