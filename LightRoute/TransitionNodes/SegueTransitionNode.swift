//
//  SegueTransitionNode.swift
//  LightRoute
//
//  Created by Vladislav Prusakov on 25/10/2017.
//  Copyright © 2017 Vladislav Prusakov. All rights reserved.
//


public final class SegueTransitionNode<T>: GenericTransitionNode<T> {
	
    /// Contain transition delegate for transition.
	var transitioningDelegate: UIViewControllerTransitioningDelegate?
	
    /// Containt segue identifer, for `prepare(for:sender:)` method.
	var segueIdentifier: String = ""
	
    ///
    /// Apply UIViewControllerTransitioningDelegate for current transition.
    ///
    /// - Parameter transitioningDelegate: UIViewControllerTransitioningDelegate instance.
    /// - Returns: Return current transition node.
    ///
	public func add(transitioningDelegate: UIViewControllerTransitioningDelegate) -> SegueTransitionNode<T> {
		self.transitioningDelegate = transitioningDelegate
		return self
	}
	
    ///
    /// This method is responsible for the delivery of the controller for the subsequent initialization, then there is a transition.
    ///
    /// - Parameter block: Initialize controller for transition and fire.
    /// - Throws: Throw error, if destination was nil or could not be cast to type.
    ///
	public override func then(_ block: @escaping TransitionSetupBlock<T>) throws {
		DispatchQueue.main.async {
			self.root.performSegue(withIdentifier: self.segueIdentifier, sender: nil, completion: { segue in
				var destination = segue.destination
				destination.transitioningDelegate = self.transitioningDelegate
				
				if destination is UINavigationController {
					destination = (segue.destination as! UINavigationController).topViewController ?? segue.destination
				} else if destination is UITabBarController {
					let tabBarController = (segue.destination as! UITabBarController)
					guard let viewControllers = tabBarController.viewControllers else {
						throw LightRouteError.customError("ViewControllers in UITabBarController can't be nil")
					}
					
					for controller in viewControllers {
						let moduleInput = (self.customModuleInput != nil) ? self.customModuleInput : destination.moduleInput
						if moduleInput is T || controller is T {
							destination = controller
							break
						}
					}
				}
				
				var output: Any?
				
				let destinationModuleInput = (self.customModuleInput != nil) ? self.customModuleInput : destination.moduleInput
				if let moduleInput = destinationModuleInput, moduleInput is T {
					output = block(destination.moduleInput as! T)
				} else if destination is T {
					output = block(destination as! T)
				} else {
					throw LightRouteError.castError(controller: String(describing: destination.self), type: "\(self.type)")
				}
				
				segue.source.moduleOutput = output
			})
		}
	}
	
}
