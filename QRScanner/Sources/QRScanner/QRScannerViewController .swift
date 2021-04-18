//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by Stefano on 17/4/21.
//

import UIKit
import AVFoundation

public protocol QRScannerViewControllerDelegate: AnyObject {
    func qrScanner(_ qrScanner: QRScannerViewController, didSucceedScanningWithCode code: String)
    func qrScannerDidFail(_ qrScanner: QRScannerViewController)
    func qrScannerDidFinish(_ qrScanner: QRScannerViewController)
}

open class QRScannerViewController: UIViewController {
    
    public weak var delegate: QRScannerViewControllerDelegate?
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    private var flashIsOn = false
    private let overlayView = QRScannerOverlayView()
    private let scannerView = QRScannerView()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        scannerView.delegate = self
        overlayView.delegate = self
        checkPermissions()
        setupViews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !scannerView.isRunning { scannerView.startScanning() }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if scannerView.isRunning { scannerView.stopScanning() }
    }
}

// MARK: - QRScannerViewDelegate

extension QRScannerViewController: QRScannerViewDelegate {
    
    func qrScanner(_ qrScanner: QRScannerView, didSucceedScanningWithCode code: String) {
        scannerView.stopScanning()
        delegate?.qrScanner(self, didSucceedScanningWithCode: code)
    }
    
    func qrScannerDidFail(_ qrScanner: QRScannerView) {
        delegate?.qrScannerDidFail(self)
    }
    
    func qrScannerDidFinish(_ qrScanner: QRScannerView) {
        delegate?.qrScannerDidFinish(self)
    }
}

// MARK: - QRScannerOverlayViewDelegate

extension QRScannerViewController: QRScannerOverlayViewDelegate {
    
    func qrOverlayDidPressBack() {
        dismiss(animated: true)
        delegate?.qrScannerDidFinish(self)
    }
    
    func qrOverlayDidPressFlash() {
        flashIsOn.toggle()
        toggleTorch(turnOn: flashIsOn)
    }
}

// MARK: - View Setup

private extension QRScannerViewController {
    
    func setupViews() {
        setupQRScannerView()
        setupQROverlayView()
    }
    
    func setupQRScannerView() {
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerView)
        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: view.topAnchor),
            scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupQROverlayView() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        overlayView.title = "Place QR code in the frame"
    }
    
    func toggleTorch(turnOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = turnOn ? .on : .off
        device.unlockForConfiguration()
    }
    
    func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return
        case .denied, .restricted:
            overlayView.darkenView(darken: true)
            showNoticeAlert()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        return
                    } else {
                        self.dismiss(animated: true)
                        self.delegate?.qrScannerDidFinish(self)
                    }
                }
            })
        default:
            return
        }
    }
    
    func showNoticeAlert() {
        let alert = makeNoticeAlert(
            title: "Notice",
            message: "To scan QR code, please allow access to your camera in your device settings.",
            actionTitle: "Settings",
            cancelTitle: "Cancel",
            cancelAction: { _ in
                self.dismiss(animated: true)
                self.delegate?.qrScannerDidFinish(self)
            }
        )
        present(alert, animated: true)
    }
    
    func makeNoticeAlert(
        title: String,
        message: String,
        actionTitle: String,
        cancelTitle: String,
        confirmAction: (() -> Void)? = nil,
        cancelAction: ((UIAlertAction) -> Void)? = nil
    ) -> UIViewController {
        let confirmAction = UIAlertAction(
            title: actionTitle,
            style: .default,
            handler: { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(settingsURL) else { return }
                confirmAction?()
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            })
        let cancelAction = UIAlertAction(title: cancelTitle,
                                         style: .cancel,
                                         handler: cancelAction)
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        return alert
    }
}
