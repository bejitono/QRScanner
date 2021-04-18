//
//  QRScannerViewController.swift
//  PHWallet
//
//  Created by Stefano De Micheli on 17/3/21.
//  Copyright © 2021 OPN Tech Co., Ltd. All rights reserved.
//

import PHUIKit
import UIKit
import AVFoundation

final class QRScannerViewController: BaseViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    private var flashIsOn = false
    private let overlayView = QRScannerOverlayView()
    private let scannerView = QRScannerView()
    private let loadingViewController = PHProgressIndicatorOverlayViewController()
    private let viewModel: QRScannerViewModelType
    
    init(viewModel: QRScannerViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scannerView.delegate = self
        overlayView.delegate = self
        viewModel.input.set(startHandleScan: showLoadingIndicator)
        viewModel.input.set(finishedHandleScan: dismissLoadingIndicator)
        checkPermissions()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !scannerView.isRunning { scannerView.startScanning() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if scannerView.isRunning { scannerView.stopScanning() }
    }
    
    func showLoadingIndicator(completion: VoidHandler = nil) {
        loadingViewController.configure(with: .init(title: Localizable.generalLoadingTitle()))
        loadingViewController.modalPresentationStyle = .overFullScreen
        present(loadingViewController, animated: true, completion: completion)
    }
    
    func dismissLoadingIndicator(completion: VoidHandler = nil) {
        loadingViewController.dismiss(animated: true, completion: completion)
    }
}

// MARK: - QRScannerViewDelegate

extension QRScannerViewController: QRScannerViewDelegate {
    
    func qrScanner(_ qrScanner: QRScannerView, didSucceedScanningWithCode code: String) {
        scannerView.stopScanning()
        viewModel.input.handleScan(code: code)
    }
    
    func qrScannerDidFail(_ qrScanner: QRScannerView) { }
    
    func qrScannerDidFinish(_ qrScanner: QRScannerView) { }
}

// MARK: - QRScannerOverlayViewDelegate

extension QRScannerViewController: QRScannerOverlayViewDelegate {
    
    func qrOverlayDidPressBack() {
        viewModel.input.cancel()
    }
    
    func qrOverlayDidPressFlash() {
        flashIsOn.toggle()
        toggleTorch(turnOn: flashIsOn)
    }
}

// MARK: - View Setup

private extension QRScannerViewController {
    
    func setupViews() {
        hideNavigationBar()
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
        overlayView.title = viewModel.output.title
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
                        self.viewModel.input.cancel()
                    }
                }
            })
        default:
            return
        }
    }
    
    func showNoticeAlert() {
        let alert = makeNoticeAlert(
            title: viewModel.output.noticeTitle,
            message: viewModel.output.noticeMessage,
            actionTitle: viewModel.output.noticeConfirm,
            cancelTitle: viewModel.output.noticeCancel,
            cancelAction: { _ in self.viewModel.input.cancel() }
        )
        present(alert, animated: true)
    }
}
