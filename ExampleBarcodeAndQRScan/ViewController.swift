//
//  ViewController.swift
//  TestBarcodeScan
//
//  Created by Bart van Kuik on 19/02/2018.
//  Copyright © 2018 DutchVirtual. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
    private let resultLabel = UILabel()
    private let scanButton = UIBarButtonItem(barButtonSystemItem: .camera, target: nil, action: nil)

    @objc func scanButtonAction() {
        let viewController = BarcodeScannerViewController()
        viewController.completionBlock = {
            self.resultLabel.text = viewController.lastResult
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.navigationController?.present(viewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.white
        self.resultLabel.translatesAutoresizingMaskIntoConstraints = false
        self.resultLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        self.view.addSubview(self.resultLabel)
        
        self.scanButton.target = self
        self.scanButton.action = #selector(scanButtonAction)
        self.navigationItem.rightBarButtonItem = scanButton

        let constraints = [
            self.resultLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.resultLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ]
        self.view.addConstraints(constraints)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { _ in
        })
    }
}
