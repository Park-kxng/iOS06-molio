import SwiftUI
import UIKit

extension UIViewController {
    func presentCustomSheet<Content: View>(
        content: Content,
        backgroundView: UIView? = nil,
        sheetHeight: CGFloat? = nil,
        detentIdentifier: String = "fixedHeight",
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let viewController = UIViewController()

        if let backgroundView = backgroundView {
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(backgroundView)
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                backgroundView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                backgroundView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
                backgroundView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
            ])
        } else {
            viewController.view.addGradientBackground()
        }

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: viewController)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            hostingController.view.layoutIfNeeded()
            let calculatedHeight = hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            let finalHeight = sheetHeight ?? calculatedHeight

            let fixedDetent = UISheetPresentationController.Detent.custom(
                identifier: UISheetPresentationController.Detent.Identifier(detentIdentifier)
            ) { _ in
                return finalHeight
            }

            sheet.detents = [fixedDetent]
            sheet.prefersGrabberVisible = true
        }

        self.present(viewController, animated: animated, completion: completion)
    }
}
