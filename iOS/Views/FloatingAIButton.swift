import UIKit

/// Floating button with AI assistant functionality
final class FloatingAIButton: UIView {
    private let button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 28
        btn.setImage(UIImage(systemName: "brain"), for: .normal)
        btn.tintColor = .white
        btn.accessibilityLabel = "AI Assistant"
        return btn
    }()
    
    private var initialPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began:
            initialPoint = center
        case .changed:
            center = CGPoint(x: initialPoint.x + translation.x,
                           y: initialPoint.y + translation.y)
            keepWithinBounds(superview: superview)
        case .ended:
            snapToEdge(superview: superview)
        default:
            break
        }
    }
    
    private func keepWithinBounds(superview: UIView) {
        let margin: CGFloat = 20
        center.x = max(margin + frame.width/2, min(center.x, superview.bounds.width - margin - frame.width/2))
        center.y = max(margin + frame.height/2, min(center.y, superview.bounds.height - margin - frame.height/2))
    }
    
    private func snapToEdge(superview: UIView) {
        let margin: CGFloat = 20
        let newX = center.x < superview.bounds.width/2 ? margin + frame.width/2 : superview.bounds.width - margin - frame.width/2
        UIView.animate(withDuration: 0.3) {
            self.center = CGPoint(x: newX, y: self.center.y)
            self.keepWithinBounds(superview: superview)
        }
    }
    
    @objc private func buttonTapped() {
        NotificationCenter.default.post(name: .showAIAssistant, object: nil)
    }
}