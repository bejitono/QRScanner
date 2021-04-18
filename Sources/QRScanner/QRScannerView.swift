//
//  QRScannerView.swift
//  QRScanner
//
//  Created by Stefano on 17/4/21.
//

import UIKit
import AVFoundation

protocol QRScannerViewDelegate: AnyObject {
    func qrScanner(_ qrScanner: QRScannerView, didSucceedScanningWithCode code: String)
    func qrScannerDidFail(_ qrScanner: QRScannerView)
    func qrScannerDidFinish(_ qrScanner: QRScannerView)
}

final class QRScannerView: UIView {
    
    enum Status {
        case scanning
        case processing
    }
    
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    
    weak var delegate: QRScannerViewDelegate?
    var isRunning: Bool { captureSession.isRunning }
    
    // swiftlint:disable:next force_cast
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    private let captureSession = AVCaptureSession()
    private var finished = false
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startScanning() {
        captureSession.startRunning()
    }
    
    func stopScanning() {
        captureSession.stopRunning()
        delegate?.qrScannerDidFinish(self)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first, !finished {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            finished = true
            delegate?.qrScanner(self, didSucceedScanningWithCode: stringValue)
        }
    }
}

// MARK: - View Setup

private extension QRScannerView {
    
    func setupViews() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.qrScannerDidFail(self)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.qrScannerDidFail(self)
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrScannerDidFail(self)
            return
        }
        
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.videoGravity = .resizeAspectFill
        
        startScanning()
    }
}
