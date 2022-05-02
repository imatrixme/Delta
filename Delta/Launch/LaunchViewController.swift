//
//  LaunchViewController.swift
//  Delta
//
//  Created by Riley Testut on 8/8/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import UIKit
import Roxas
import GPUImage

import Harmony

class LaunchViewController: RSTLaunchViewController
{
    @IBOutlet private var gameViewContainerView: UIView!
    private var gameViewController: GameViewController!
    
    private var presentedGameViewController: Bool = false
    
    private var applicationLaunchDeepLinkGame: Game?
    
    private var didAttemptStartingSyncManager = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.gameViewController?.preferredStatusBarStyle ?? .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.gameViewController?.prefersStatusBarHidden ?? false
    }
    
    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return self.gameViewController
    }
    
    override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        return self.gameViewController
    }
    
    override var shouldAutorotate: Bool {
        return self.gameViewController?.shouldAutorotate ?? true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LaunchViewController.deepLinkControllerLaunchGame(with:)), name: .deepLinkControllerLaunchGame, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard segue.identifier == "embedGameViewController" else { return }
        
        self.gameViewController = segue.destination as? GameViewController
//        let filter = FSHFilter.create(vsh: "zfast_lcd", fsh: "zfast_lcd_hd+psp_color_mobile")
        
//        let sharpen = CIFilter(name: "CIUnsharpMask")!
//        sharpen.setValue(0.2, forKey: "inputIntensity")
//        sharpen.setValue(1, forKey: "inputRadius")
        
//        let filter = CIFilter.init(name: "CILineScreen")!
//        filter.setValue(0.2, forKey: kCIInputAngleKey)
//        filter.setValue(CIVector(x: 0, y: 0), forKey: kCIInputCenterKey)
//        filter.setValue(0.5, forKey: kCIInputSharpnessKey)
//        filter.setValue(0.5, forKey: kCIInputWidthKey)
        
//        let shader = FSHFilter.create("matrixme+zfast_lcd_hd+psp_color")

        let filter = CIFilter.init(name: "CICMYKHalftone")!
        filter.setValue(CIVector(x: 0, y: 0), forKey: kCIInputCenterKey)
        filter.setValue(0.2, forKey: kCIInputAngleKey)
        filter.setValue(1, forKey: kCIInputWidthKey)
        filter.setValue(0.3, forKey: kCIInputSharpnessKey)
        filter.setValue(0.2, forKey: "inputGCR")
        filter.setValue(0.5, forKey: "inputUCR")

        self.gameViewController.externalFilters = [filter]
    }
}

extension LaunchViewController
{
    override var launchConditions: [RSTLaunchCondition] {
        let isDatabaseManagerStarted = RSTLaunchCondition(condition: { DatabaseManager.shared.isStarted }) { (completionHandler) in
            DatabaseManager.shared.start(completionHandler: completionHandler)
        }
        
        let isSyncingManagerStarted = RSTLaunchCondition(condition: { self.didAttemptStartingSyncManager }) { (completionHandler) in
            self.didAttemptStartingSyncManager = true
            
            SyncManager.shared.start(service: Settings.syncingService) { (result) in
                switch result
                {
                case .success: completionHandler(nil)
                case .failure(let error): completionHandler(error)
                }
            }
        }
        
        return [isDatabaseManagerStarted, isSyncingManagerStarted]
    }
    
    override func handleLaunchError(_ error: Error)
    {
        do
        {
            throw error
        }
        catch is HarmonyError
        {
            // Ignore
            self.handleLaunchConditions()
        }
        catch
        {
            let alertController = UIAlertController(title: NSLocalizedString("Unable to Launch Delta", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default, handler: { (action) in
                self.handleLaunchConditions()
            }))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func finishLaunching()
    {
        super.finishLaunching()
        
        guard !self.presentedGameViewController else { return }
        
        self.presentedGameViewController = true
        
        func showGameViewController()
        {
            self.view.bringSubviewToFront(self.gameViewContainerView)
            
            self.setNeedsStatusBarAppearanceUpdate()
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
        
        if let game = self.applicationLaunchDeepLinkGame
        {
            self.gameViewController.game = game
            
            UIView.transition(with: self.view, duration: 0.3, options: [.transitionCrossDissolve], animations: {
                showGameViewController()
            }) { (finished) in
                self.gameViewController.startEmulation()
            }
        }
        else
        {
            self.gameViewController.performSegue(withIdentifier: "showInitialGamesViewController", sender: nil)
            self.transitionCoordinator?.animate(alongsideTransition: nil, completion: { (context) in
                showGameViewController()
            })
        }
    }
}

private extension LaunchViewController
{
    @objc func deepLinkControllerLaunchGame(with notification: Notification)
    {
        guard !self.presentedGameViewController else { return }
        
        guard let game = notification.userInfo?[DeepLink.Key.game] as? Game else { return }
        
        self.applicationLaunchDeepLinkGame = game
    }
}
