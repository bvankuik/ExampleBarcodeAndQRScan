//
//  VIVideoPreviewView.swift
//  TestBarcodeScan
//
//  Created by Bart van Kuik on 06/02/2018.
//  Copyright © 2018 DutchVirtual. All rights reserved.
//

import UIKit
import AVFoundation

class VIVideoPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass {
        get {
            return AVCaptureVideoPreviewLayer.self
        }
    }
    
    init() {
        super.init(frame: CGRect())
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundColor = UIColor.darkGray
        self.previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
