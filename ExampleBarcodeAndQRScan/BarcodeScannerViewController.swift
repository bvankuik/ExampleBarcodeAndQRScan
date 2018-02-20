//
//  BarcodeScannerViewController.swift
//  TestBarcodeScan
//
//  Created by Bart van Kuik on 06/02/2018.
//  Copyright © 2018 DutchVirtual. All rights reserved.
//

import UIKit
import AVFoundation


private class VideoPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
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


class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let viewFinderView = UIView()
    private let barcodeLabel = UILabel()
    private var barcodeLabelAnimator = UIViewPropertyAnimator()
    private var device: AVCaptureDevice!
    private var deviceInput: AVCaptureDeviceInput!
    private var metadataOutput: AVCaptureMetadataOutput!
    private var captureSession: AVCaptureSession!
    private var previewView = VideoPreviewView()
    private let interruptedOverlayView = UIVisualEffectView()
    private let objectTypesToScan: [AVMetadataObject.ObjectType] = [
        .code39, .ean13, .qr
    ]
    public var completionBlock: (()->Void)?
    public var lastResult: String?

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for object in metadataObjects {
            let visualCodeObject = previewView.previewLayer.transformedMetadataObject(for: object)
            if let object = visualCodeObject, self.viewFinderView.frame.contains(object.bounds) {
                if let barcode = object as? AVMetadataMachineReadableCodeObject, let barcodeString = barcode.stringValue {
                    self.lastResult = barcodeString
                    self.showBarcode(text: barcodeString)
                    
                    if let block = self.completionBlock {
                        block()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func showInterruptedMessage(_ notification: Notification) {
        self.interruptedOverlayView.isHidden = false
    }
    
    @objc func hideInterruptedMessage(_ notification: Notification) {
        self.interruptedOverlayView.isHidden = true
    }
    
    @objc func stopRunning() {
        self.captureSession.stopRunning()
    }
    
    @objc func startRunning() {
        self.captureSession.startRunning()
    }
    
    @objc func rotateCameraButtonAction() {
        let types: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera]
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified)
        var discoveredDevice: AVCaptureDevice?
        
        // Go through all devices and find one where the device position is not the same as the current one.
        // I.e. if we're using the front facing camera, search for the other one
        for device in deviceDiscoverySession.devices where device.position != self.device.position {
            discoveredDevice = device
            break
        }

        self.teardown()
        self.setup(device: discoveredDevice)
        self.captureSession.startRunning()
    }
    
    // MARK: - Private methods
    
    private func setup(device deviceOrNil: AVCaptureDevice?) {
        if let device = deviceOrNil {
            self.device = device
        } else {
             self.device = AVCaptureDevice.default(for: .video)
        }
        
        if let deviceInput = try? AVCaptureDeviceInput(device: self.device) {
            self.deviceInput = deviceInput
        } else {
            fatalError("Couldn't create AVCaptureDeviceInput")
        }
        
        // Add input to capture session
        
        self.captureSession = AVCaptureSession()
        if !self.captureSession.canAddInput(self.deviceInput) {
            fatalError("Can't add AVCaptureDeviceInput to AVCaptureSession")
        } else {
            self.captureSession.addInput(self.deviceInput)
        }
        
        // Add output to capture session
        
        self.metadataOutput = AVCaptureMetadataOutput()
        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        self.metadataOutput.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)  // This means: the whole screen
        
        if self.captureSession.canAddOutput(self.metadataOutput) {
            self.captureSession.addOutput(self.metadataOutput)
        } else {
            fatalError("Can't add metadata output to capture session")
        }
        
        self.objectTypesToScan.forEach {
            if !self.metadataOutput.availableMetadataObjectTypes.contains($0) {
                fatalError("Metadata object type \($0) not available")
            }
        }
        self.metadataOutput.metadataObjectTypes = self.objectTypesToScan
        
        // Hook up capture session to view
        
        self.previewView.previewLayer.session = self.captureSession
    }
    
    private func teardown() {
        self.captureSession.stopRunning()
        self.captureSession.removeInput(self.deviceInput)
        self.captureSession.removeOutput(self.metadataOutput)
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        self.previewView.previewLayer.connection?.videoOrientation = orientation
    }
    
    private func showBarcode(text: String) {
        self.barcodeLabelAnimator.stopAnimation(true)
        self.barcodeLabel.text = text
        self.barcodeLabel.alpha = 1.0
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
            self.barcodeLabel.alpha = 0.0
        }
        animator.startAnimation()
        self.barcodeLabelAnimator = animator
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let connection = self.previewView.previewLayer.connection else {
            return
        }
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        let previewLayerConnection : AVCaptureConnection = connection
        
        guard previewLayerConnection.isVideoOrientationSupported else {
            return
        }
        
        switch (orientation) {
        case .portrait:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
            break
        case .landscapeRight:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
            break
        case .landscapeLeft:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
            break
        case .portraitUpsideDown:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
            break
        default:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
            break
        }
    }
    
    // MARK: - View cycle

    override func viewDidLoad() {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toolbar)
        
        let rotateCameraButton = UIBarButtonItem(image: #imageLiteral(resourceName: "rotate"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(rotateCameraButtonAction))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spacer,rotateCameraButton, spacer], animated: false)
        
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previewView)
        
        self.barcodeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.barcodeLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        self.barcodeLabel.textColor = UIColor.red
        self.barcodeLabel.textAlignment = .center
        self.barcodeLabel.backgroundColor = .white
        self.barcodeLabel.alpha = 0.0
        self.view.addSubview(self.barcodeLabel)

        self.viewFinderView.translatesAutoresizingMaskIntoConstraints = false
        self.viewFinderView.layer.borderColor = UIColor.red.cgColor
        self.viewFinderView.layer.borderWidth = 2.0
        self.previewView.addSubview(self.viewFinderView)
        
        self.interruptedOverlayView.translatesAutoresizingMaskIntoConstraints = false
        self.interruptedOverlayView.effect = UIBlurEffect(style: .light)
        self.view.addSubview(self.interruptedOverlayView)
        
        let interruptedLabel = UILabel()
        interruptedLabel.translatesAutoresizingMaskIntoConstraints = false
        interruptedLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        interruptedLabel.numberOfLines = 0
        interruptedLabel.textAlignment = .center
        interruptedLabel.lineBreakMode = .byWordWrapping
        interruptedLabel.text = "Camera paused when app is not full screen"
        self.interruptedOverlayView.contentView.addSubview(interruptedLabel)

        let guide = self.view.safeAreaLayoutGuide

        let viewFinderDefaultWidth = self.viewFinderView.widthAnchor.constraint(equalTo: self.previewView.widthAnchor, multiplier: 0.25)
        viewFinderDefaultWidth.priority = .defaultLow
        let viewFinderMinWidthConstraint = self.viewFinderView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        viewFinderMinWidthConstraint.priority = .defaultHigh
        
        let constraints = [
            self.previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.previewView.topAnchor.constraint(equalTo: guide.topAnchor),
            self.previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.previewView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            self.viewFinderView.centerXAnchor.constraint(equalTo: self.previewView.centerXAnchor),
            self.viewFinderView.centerYAnchor.constraint(equalTo: self.previewView.centerYAnchor),
            self.viewFinderView.heightAnchor.constraint(equalTo: self.viewFinderView.widthAnchor, multiplier: 0.75),
            viewFinderDefaultWidth,
            viewFinderMinWidthConstraint,
            self.barcodeLabel.centerXAnchor.constraint(equalTo: self.viewFinderView.centerXAnchor),
            self.barcodeLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            toolbar.leftAnchor.constraint(equalTo: guide.leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: guide.rightAnchor),
            toolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            self.interruptedOverlayView.leftAnchor.constraint(equalTo: self.previewView.leftAnchor),
            self.interruptedOverlayView.topAnchor.constraint(equalTo: self.previewView.topAnchor),
            self.interruptedOverlayView.rightAnchor.constraint(equalTo: self.previewView.rightAnchor),
            self.interruptedOverlayView.bottomAnchor.constraint(equalTo: self.previewView.bottomAnchor),
            interruptedLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            interruptedLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            interruptedLabel.centerYAnchor.constraint(equalTo: self.interruptedOverlayView.centerYAnchor),
        ]
        self.view.addConstraints(constraints)
        
        self.interruptedOverlayView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(showInterruptedMessage(_:)),
                                               name: Notification.Name.AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideInterruptedMessage(_:)),
                                               name: Notification.Name.AVCaptureSessionInterruptionEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRunning),
                                               name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRunning),
                                               name: .UIApplicationWillEnterForeground, object: nil)
        self.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopRunning()        
    }
    
    // MARK: - Life cycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup(device: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
