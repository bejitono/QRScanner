//
//  QRScannerOverlayView.swift
//  QRScanner
//
//  Created by Stefano on 17/4/21.
//

import UIKit

protocol QRScannerOverlayViewDelegate: AnyObject {
    func qrOverlayDidPressBack()
    func qrOverlayDidPressFlash()
}

final class QRScannerOverlayView: UIView {

    weak var delegate: QRScannerOverlayViewDelegate?
    
    var title: String? {
        didSet {
            alignLabel.text = title
        }
    }
    
    private let alignLabel = UILabel()
    private let boxFrameView = UIView()
    private let overlayView = UIView()
    private let backButton = ExpandedTouchAreaButton()
    private let flashButton = ExpandedTouchAreaButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let cornersLayer = createCorners(rect: boxFrameView.bounds)
        boxFrameView.layer.addSublayer(cornersLayer)
        layer.addSublayer(boxFrameView.layer)

        addMaskLayer()
        addLabel()
        addBackButton()
        addFlashButton()

        super.draw(rect)
    }

    func darkenView(darken: Bool) {
        if darken {
            boxFrameView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: .backgroundAlpha)
        } else {
            boxFrameView.backgroundColor = .clear
        }
        setNeedsDisplay()
    }

    @objc func backPressed() {
        delegate?.qrOverlayDidPressBack()
    }

    @objc func flashPressed() {
        delegate?.qrOverlayDidPressFlash()
    }
}

// MARK: - View Setup

// swiftlint:disable function_body_length
private extension QRScannerOverlayView {

    func setupViews() {
        self.backgroundColor = .clear
        setupOverlayViews()
    }
    
    func setupOverlayViews() {
        boxFrameView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(boxFrameView)
        NSLayoutConstraint.activate([
            boxFrameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            boxFrameView.topAnchor.constraint(equalTo: topAnchor, constant: .scanBoxTopMargin),
            boxFrameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding),
            boxFrameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding),
            boxFrameView.heightAnchor.constraint(equalTo: boxFrameView.widthAnchor)
        ])
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        overlayView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: .backgroundAlpha)
    }

    func addMaskLayer() {
        // Create the initial layer from the view bounds.
        let maskLayer = CAShapeLayer()
        maskLayer.frame = overlayView.bounds

        // Create the path
        let path = UIBezierPath(rect: overlayView.bounds)
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd

        // Append the boxFrame to the path so that it is subtracted.
        path.append(UIBezierPath(rect: boxFrameView.frame))
        maskLayer.path = path.cgPath

        // Set the mask of the view
        overlayView.layer.mask = maskLayer

        layer.insertSublayer(overlayView.layer, below: boxFrameView.layer)
    }

    func addLabel() {
        alignLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(alignLabel)
        NSLayoutConstraint.activate([
            alignLabel.bottomAnchor.constraint(equalTo: boxFrameView.topAnchor, constant: -.titleSpacing),
            alignLabel.widthAnchor.constraint(equalTo: boxFrameView.widthAnchor),
            alignLabel.centerXAnchor.constraint(equalTo: boxFrameView.centerXAnchor)
        ])
        
        alignLabel.font = UIFont.systemFont(ofSize: 24)
        alignLabel.textColor = .white
        alignLabel.numberOfLines = 2
        alignLabel.textAlignment = .center
    }

    func addBackButton() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding),
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .topMargin)
        ])

        backButton.setImage(UIImage(named: "chevron.backward")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
    }

    func addFlashButton() {
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(flashButton)

        NSLayoutConstraint.activate([
            flashButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding),
            flashButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .topMargin)
        ])
        
        flashButton.setImage(UIImage(named: "flashlight.off.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(flashPressed), for: .touchUpInside)
    }
    
    func createCorners(rect: CGRect) -> CAShapeLayer {
        // Calculate the length of corner to be shown
        let cornerLengthToShow = rect.size.height * 0.10

        // Create Paths Using BeizerPath for all four corners
        let topLeftCorner1 = UIBezierPath()
        topLeftCorner1.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLengthToShow))
        topLeftCorner1.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        let topLeftCorner2 = UIBezierPath()
        topLeftCorner2.move(to: CGPoint(x: rect.minX, y: rect.minY))
        topLeftCorner2.addLine(to: CGPoint(x: rect.minX + cornerLengthToShow, y: rect.minY))

        let topRightCorner1 = UIBezierPath()
        topRightCorner1.move(to: CGPoint(x: rect.maxX - cornerLengthToShow, y: rect.minY))
        topRightCorner1.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        let topRightCorner2 = UIBezierPath()
        topRightCorner2.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        topRightCorner2.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLengthToShow))

        let bottomRightCorner1 = UIBezierPath()
        bottomRightCorner1.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLengthToShow))
        bottomRightCorner1.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        let bottomRightCorner2 = UIBezierPath()
        bottomRightCorner2.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        bottomRightCorner2.addLine(to: CGPoint(x: rect.maxX - cornerLengthToShow, y: rect.maxY ))

        let bottomLeftCorner1 = UIBezierPath()
        bottomLeftCorner1.move(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLengthToShow))
        bottomLeftCorner1.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        let bottomLeftCorner2 = UIBezierPath()
        bottomLeftCorner2.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        bottomLeftCorner2.addLine(to: CGPoint(x: rect.minX + cornerLengthToShow, y: rect.maxY))

        let combinedPath = CGMutablePath()
        combinedPath.addPath(topLeftCorner1.cgPath)
        combinedPath.addPath(topLeftCorner2.cgPath)
        combinedPath.addPath(topRightCorner1.cgPath)
        combinedPath.addPath(topRightCorner2.cgPath)
        combinedPath.addPath(bottomRightCorner1.cgPath)
        combinedPath.addPath(bottomRightCorner2.cgPath)
        combinedPath.addPath(bottomLeftCorner1.cgPath)
        combinedPath.addPath(bottomLeftCorner2.cgPath)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = combinedPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 5
        shapeLayer.lineCap = .round

        return shapeLayer
    }
}

final class ExpandedTouchAreaButton: UIButton {

    var margin: CGFloat = 10.0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = self.bounds.insetBy(dx: -margin, dy: -margin)
        return newArea.contains(point)
    }
}

private extension CGFloat {
    static let padding: CGFloat = 36
    static let topMargin: CGFloat = 20
    static let scanBoxTopMargin: CGFloat = 200
    static let titleSpacing: CGFloat = 32
    static let backgroundAlpha: CGFloat = 0.6
}
