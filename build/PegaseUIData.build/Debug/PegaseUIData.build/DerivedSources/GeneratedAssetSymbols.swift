import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "035-bank" asset catalog image resource.
    static let _035Bank = DeveloperToolsSupport.ImageResource(name: "035-bank", bundle: resourceBundle)

    /// The "035-bank 1" asset catalog image resource.
    static let _035Bank1 = DeveloperToolsSupport.ImageResource(name: "035-bank 1", bundle: resourceBundle)

    /// The "Gradient" asset catalog image resource.
    static let gradient = DeveloperToolsSupport.ImageResource(name: "Gradient", bundle: resourceBundle)

    /// The "add" asset catalog image resource.
    static let add = DeveloperToolsSupport.ImageResource(name: "add", bundle: resourceBundle)

    /// The "discount" asset catalog image resource.
    static let discount = DeveloperToolsSupport.ImageResource(name: "discount", bundle: resourceBundle)

    /// The "icons8-credit-card-100" asset catalog image resource.
    static let icons8CreditCard100 = DeveloperToolsSupport.ImageResource(name: "icons8-credit-card-100", bundle: resourceBundle)

    /// The "icons8-expensive-100" asset catalog image resource.
    static let icons8Expensive100 = DeveloperToolsSupport.ImageResource(name: "icons8-expensive-100", bundle: resourceBundle)

    /// The "icons8-money-100" asset catalog image resource.
    static let icons8Money100 = DeveloperToolsSupport.ImageResource(name: "icons8-money-100", bundle: resourceBundle)

    /// The "icons8-money-box-80" asset catalog image resource.
    static let icons8MoneyBox80 = DeveloperToolsSupport.ImageResource(name: "icons8-money-box-80", bundle: resourceBundle)

    /// The "icons8-museum-80" asset catalog image resource.
    static let icons8Museum80 = DeveloperToolsSupport.ImageResource(name: "icons8-museum-80", bundle: resourceBundle)

    /// The "icons8-paypal-100" asset catalog image resource.
    static let icons8Paypal100 = DeveloperToolsSupport.ImageResource(name: "icons8-paypal-100", bundle: resourceBundle)

    /// The "icons8-purse-100" asset catalog image resource.
    static let icons8Purse100 = DeveloperToolsSupport.ImageResource(name: "icons8-purse-100", bundle: resourceBundle)

    /// The "icons8-safe-100" asset catalog image resource.
    static let icons8Safe100 = DeveloperToolsSupport.ImageResource(name: "icons8-safe-100", bundle: resourceBundle)

    /// The "icons8-wallet-80" asset catalog image resource.
    static let icons8Wallet80 = DeveloperToolsSupport.ImageResource(name: "icons8-wallet-80", bundle: resourceBundle)

    /// The "pegase" asset catalog image resource.
    static let pegase = DeveloperToolsSupport.ImageResource(name: "pegase", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "035-bank" asset catalog image.
    static var _035Bank: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._035Bank)
#else
        .init()
#endif
    }

    /// The "035-bank 1" asset catalog image.
    static var _035Bank1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._035Bank1)
#else
        .init()
#endif
    }

    /// The "Gradient" asset catalog image.
    static var gradient: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gradient)
#else
        .init()
#endif
    }

    /// The "add" asset catalog image.
    static var add: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .add)
#else
        .init()
#endif
    }

    /// The "discount" asset catalog image.
    static var discount: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .discount)
#else
        .init()
#endif
    }

    /// The "icons8-credit-card-100" asset catalog image.
    static var icons8CreditCard100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8CreditCard100)
#else
        .init()
#endif
    }

    /// The "icons8-expensive-100" asset catalog image.
    static var icons8Expensive100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Expensive100)
#else
        .init()
#endif
    }

    /// The "icons8-money-100" asset catalog image.
    static var icons8Money100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Money100)
#else
        .init()
#endif
    }

    /// The "icons8-money-box-80" asset catalog image.
    static var icons8MoneyBox80: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8MoneyBox80)
#else
        .init()
#endif
    }

    /// The "icons8-museum-80" asset catalog image.
    static var icons8Museum80: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Museum80)
#else
        .init()
#endif
    }

    /// The "icons8-paypal-100" asset catalog image.
    static var icons8Paypal100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Paypal100)
#else
        .init()
#endif
    }

    /// The "icons8-purse-100" asset catalog image.
    static var icons8Purse100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Purse100)
#else
        .init()
#endif
    }

    /// The "icons8-safe-100" asset catalog image.
    static var icons8Safe100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Safe100)
#else
        .init()
#endif
    }

    /// The "icons8-wallet-80" asset catalog image.
    static var icons8Wallet80: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icons8Wallet80)
#else
        .init()
#endif
    }

    /// The "pegase" asset catalog image.
    static var pegase: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pegase)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "035-bank" asset catalog image.
    static var _035Bank: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._035Bank)
#else
        .init()
#endif
    }

    /// The "035-bank 1" asset catalog image.
    static var _035Bank1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._035Bank1)
#else
        .init()
#endif
    }

    /// The "Gradient" asset catalog image.
    static var gradient: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .gradient)
#else
        .init()
#endif
    }

    #warning("The \"add\" image asset name resolves to a conflicting UIImage symbol \"add\". Try renaming the asset.")

    /// The "discount" asset catalog image.
    static var discount: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .discount)
#else
        .init()
#endif
    }

    /// The "icons8-credit-card-100" asset catalog image.
    static var icons8CreditCard100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8CreditCard100)
#else
        .init()
#endif
    }

    /// The "icons8-expensive-100" asset catalog image.
    static var icons8Expensive100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Expensive100)
#else
        .init()
#endif
    }

    /// The "icons8-money-100" asset catalog image.
    static var icons8Money100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Money100)
#else
        .init()
#endif
    }

    /// The "icons8-money-box-80" asset catalog image.
    static var icons8MoneyBox80: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8MoneyBox80)
#else
        .init()
#endif
    }

    /// The "icons8-museum-80" asset catalog image.
    static var icons8Museum80: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Museum80)
#else
        .init()
#endif
    }

    /// The "icons8-paypal-100" asset catalog image.
    static var icons8Paypal100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Paypal100)
#else
        .init()
#endif
    }

    /// The "icons8-purse-100" asset catalog image.
    static var icons8Purse100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Purse100)
#else
        .init()
#endif
    }

    /// The "icons8-safe-100" asset catalog image.
    static var icons8Safe100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Safe100)
#else
        .init()
#endif
    }

    /// The "icons8-wallet-80" asset catalog image.
    static var icons8Wallet80: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icons8Wallet80)
#else
        .init()
#endif
    }

    /// The "pegase" asset catalog image.
    static var pegase: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pegase)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

