//
//  UIViewController+Extension.swift
//  LightRoute
//
//  Created by Vladislav Prusakov on 25/10/2017.
//  Copyright © 2017 Vladislav Prusakov. All rights reserved.
//

///
/// This extension adds public methods for work with LightRoute.
/// Performs swizzle default `prepare(for:sender:)` method and return transition segue.
///
extension UIViewController: TransitionHandler {
	
	/// This property return tradition VIPER presenter object from "output" property.
	var moduleInput: Any? {
		let reflection = Mirror(reflecting: self).children
		var output: Any?
		
		// Find `output` property
		for property in reflection {
			if property.label! == "output" {
				output = property.value
				break
			}
		}
		
		return output
	}
	
	/// This property have responsobility about store property for moduleOutput protocols.
	public var moduleOutput: Any? {
		get {
			let box = objc_getAssociatedObject(self, &UIViewController.TransitionHandlerModuleOutput) as? Box
			return box?.value
		}
		set {
			objc_setAssociatedObject(self, &UIViewController.TransitionHandlerModuleOutput, Box(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}
	

	///
    /// This methods get moduleInput by selector.
    ///
    /// - Parameter selectorName: Selector name for find object in view controller.
    /// - Returns: Return something object, how can be promisee about moduleInput.
    ///
	func getModuleInput(for selectorName: String) -> Any? {
		
		let reflection = Mirror(reflecting: self).children
		var output: Any?
		
		// Find `output` property
		for property in reflection {
			if property.label! == selectorName {
				output = property.value
				break
			}
		}
		
		return output
	}
	
	///
	/// You can read more about this implemetation in this article - ["Swift improve performSegue(withIdentifier:sender:) or a router with storyboards"](https://habrahabr.ru/post/275783/)
	///
	// Wrapper for save objects with nil.
	class Box {
		let value: Any?
		init(_ value: Any?) {
			self.value = value
		}
	}
	
	// Key for objc associated objects.
	@nonobjc static var ClosurePrepareForSegueKey = "ru.hipsterknight.lightroute.prepareForSegue"
	@nonobjc static var TransitionHandlerModuleOutput = "ru.hipsterknight.lightroute.moduleOutput"
	
	// Contain information about current transition segue.
	var configuratePerformSegue: ConfiguratePerformSegue? {
		get {
			let box = objc_getAssociatedObject(self, &UIViewController.ClosurePrepareForSegueKey) as? Box
			return box?.value as? ConfiguratePerformSegue
		}
		set {
			objc_setAssociatedObject(self, &UIViewController.ClosurePrepareForSegueKey, Box(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	// Return transition segue.
	typealias ConfiguratePerformSegue = (UIStoryboardSegue) throws -> ()
	
	// MARK: Swizzled methods
	func performSegue(withIdentifier identifier: String, sender: Any?, completion: @escaping ConfiguratePerformSegue) {
		swizzlePrepareForSegue()
		configuratePerformSegue = completion
		performSegue(withIdentifier: identifier, sender: sender)
	}
	
	func swizzlePrepareForSegue() {
		
		// Must be fire once time.
		DispatchQueue.once(token: "ru.hipsterknight.lightroute.dispatch.swizzle.prepareForSegue") {
			let originalSelector = #selector(UIViewController.prepare(for:sender:))
			let swizzledSelector = #selector(UIViewController.swizzledPrepare(for:sender:))
			
			let instanceClass = UIViewController.self
			let originalMethod = class_getInstanceMethod(instanceClass, originalSelector)
			let swizzledMethod = class_getInstanceMethod(instanceClass, swizzledSelector)
			
			let didAddMethod = class_addMethod(instanceClass, originalSelector,
			                                   method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
			
			if didAddMethod {
				class_replaceMethod(instanceClass, swizzledSelector,
				                    method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
			} else {
				method_exchangeImplementations(originalMethod!, swizzledMethod!)
			}
		}
	}
	
	@objc func swizzledPrepare(for segue: UIStoryboardSegue, sender: Any?) {
		do {
			try configuratePerformSegue?(segue)
			swizzledPrepare(for: segue, sender: sender)
			configuratePerformSegue = nil
		} catch {
			print("Swizzle error", error.localizedDescription)
		}
	}
	
}

// MARK: -
// MARK: Dispatch once implemetation.

// Read more: [Dispatch once in Swift 3](http://stackoverflow.com/a/38311178)
fileprivate extension DispatchQueue {
	
	private static var _onceTracker: [String] = []
	
	/// Return default dispatch_once in Swift.
	static func once(token: String, block: () -> Void) {
		objc_sync_enter(self)
		defer { objc_sync_exit(self) }
		
		if _onceTracker.contains(token) {
			return
		}
		
		_onceTracker.append(token)
		block()
	}
	
}
