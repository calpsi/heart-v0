import SwiftUI
import UIKit

/// A native adjustable control with a quiet six-point track and an explicit
/// thumb. UIKit owns tracking, cancellation and assistive adjustments; the
/// SwiftUI binding remains the sole source of lesson/model state.
struct HeartSlider: UIViewRepresentable {
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void
    @Environment(\.isEnabled) private var enabled

    init(value: Binding<Double>, in bounds: ClosedRange<Double>, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        _value = value
        self.bounds = bounds
        self.onEditingChanged = onEditingChanged
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> HeartTrackSlider {
        let slider = HeartTrackSlider()
        slider.sliderStyle = .default
        slider.isContinuous = true
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.began), for: .touchDown)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.ended), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        slider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return slider
    }
    func updateUIView(_ slider: HeartTrackSlider, context: Context) {
        context.coordinator.parent = self
        slider.minimumValue = Float(bounds.lowerBound)
        slider.maximumValue = Float(bounds.upperBound)
        slider.isEnabled = enabled
        slider.setValue(Float(value), animated: false)
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: HeartTrackSlider, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 200, height: 60)
    }
    static func dismantleUIView(_ uiView: HeartTrackSlider, coordinator: Coordinator) {
        coordinator.ended()
    }

    @MainActor final class Coordinator: NSObject {
        var parent: HeartSlider
        private var editing = false
        init(_ parent: HeartSlider) { self.parent = parent }
        @objc func began() {
            guard !editing else { return }
            editing = true
            parent.onEditingChanged(true)
        }
        @objc func changed(_ sender: UISlider) {
            // Accessibility increments send valueChanged without touchDown.
            let discrete = !editing
            if discrete { parent.onEditingChanged(true) }
            parent.value = min(parent.bounds.upperBound, max(parent.bounds.lowerBound, Double(sender.value)))
            if discrete { parent.onEditingChanged(false) }
        }
        @objc func ended() {
            guard editing else { return }
            editing = false
            parent.onEditingChanged(false)
        }
    }
}

final class HeartTrackSlider: UISlider {
    // visionOS may suppress its idle thumb even with a custom thumb image.
    // This non-interactive indicator follows the normalized track value; it
    // neither replaces the slider's hit target nor creates a second AX element.
    private let positionIndicator = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumTrackTintColor = UIColor(HeartDesign.accent)
        maximumTrackTintColor = UIColor(red: 217/255, green: 217/255, blue: 223/255, alpha: 1)
        let thumb = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { renderer in
            let context = renderer.cgContext
            context.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.15).cgColor)
            let circle = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 28, height: 28))
            UIColor.white.setFill(); circle.fill()
            context.setShadow(offset: .zero, blur: 0, color: nil)
            UIColor(red: 200/255, green: 200/255, blue: 207/255, alpha: 1).setStroke()
            circle.lineWidth = 1; circle.stroke()
        }
        setThumbImage(thumb, for: .normal)
        setThumbImage(thumb, for: .highlighted)
        positionIndicator.isUserInteractionEnabled = false
        positionIndicator.isAccessibilityElement = false
        positionIndicator.backgroundColor = .white
        positionIndicator.layer.cornerRadius = 14
        positionIndicator.layer.borderWidth = 1
        positionIndicator.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 207/255, alpha: 1).cgColor
        positionIndicator.layer.shadowColor = UIColor.black.cgColor
        positionIndicator.layer.shadowOpacity = 0.15
        positionIndicator.layer.shadowOffset = CGSize(width: 0, height: 1)
        positionIndicator.layer.shadowRadius = 2
        addSubview(positionIndicator)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let track = trackRect(forBounds: bounds)
        let fraction = CGFloat(min(1, max(0, (value - minimumValue) / max(Float.ulpOfOne, maximumValue - minimumValue))))
        let position = effectiveUserInterfaceLayoutDirection == .rightToLeft ? 1 - fraction : fraction
        positionIndicator.frame = CGRect(x: track.minX + track.width * position - 14, y: bounds.midY - 14, width: 28, height: 28)
        positionIndicator.isHidden = !isEnabled
        bringSubviewToFront(positionIndicator)
    }
    override func setValue(_ value: Float, animated: Bool) {
        super.setValue(value, animated: animated)
        setNeedsLayout()
    }
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: 60) }
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let track = super.trackRect(forBounds: bounds)
        return CGRect(x: track.minX, y: bounds.midY - 3, width: track.width, height: 6)
    }
}
