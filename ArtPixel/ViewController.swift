//
//  ViewController.swift
//  ArtPixel
//
//  Created by Chung on 2018/01/04.
//  Copyright © 2018 Chung. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    fileprivate let labelFont = UIFont(name: "Menlo", size: 7)!
    fileprivate let maxImageSize = CGSize(width: 300, height: 300)
    fileprivate lazy var palette: AsciiPalette = AsciiPalette(font: self.labelFont)
    fileprivate var currentView: Canvas?
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pixels = Array<Array<UILabel>>()
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureZoomSupport()
    }
    
    // MARK: - Actions
    
    @IBAction func handleKermitTapped(_ sender: AnyObject) {
        displayImageNamed("kermit")
    }
    
    @IBAction func handleBatmanTapped(_ sender: AnyObject) {
        displayImageNamed("batman")
    }
    
    @IBAction func handleMonkeyTapped(_ sender: AnyObject) {
        displayImageNamed("monkey")
    }
    
    @IBAction func handlePickImageTapped(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.show(imagePicker, sender: self)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            displayImage(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Rendering
    
    fileprivate func displayImageNamed(_ imageName: String) {
        let image = UIImage(named: imageName)!
        displayImage(image)
    }
    
    fileprivate func displayImage(_ image: UIImage) {
        self.busyView.isHidden = false
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            let // Rotate first because the orientation is lost when resizing.
            rotatedImage = image.imageRotatedToPortraitOrientation(),
            resizedImage = rotatedImage.imageConstrainedToMaxSize(self.maxImageSize),
            asciiArtist  = AsciiArtist(resizedImage, self.palette),
            symbolsMatix = asciiArtist.createAsciiArt()
            
            DispatchQueue.main.async {
                self.displayAsciiArt(symbolsMatix)
                self.busyView.isHidden = true
            }
        }
    }
    
    fileprivate func displayAsciiArt(_ matrix: [[String]]) {
        self.currentView?.removeFromSuperview()
        self.currentView = Canvas(itemSize: 10, symbolsMatix: matrix)
        self.scrollView.addSubview(currentView!)
        self.scrollView.contentSize = self.currentView!.frame.size
        self.updateZoomSettings(animated: true)
    }
    // MARK: - Zooming support
    
    fileprivate func configureZoomSupport() {
        scrollView.delegate = self
        scrollView.maximumZoomScale = 5
    }
    
    fileprivate func updateZoomSettings(animated: Bool) {
        let
        scrollSize  = scrollView.frame.size,
        contentSize = scrollView.contentSize,
        scaleWidth  = scrollSize.width / contentSize.width,
        scaleHeight = scrollSize.height / contentSize.height,
        scale       = min(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = scale/2
        scrollView.setZoomScale(scale, animated: animated)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        setCenterScrollView(scrollView, currentView)
        return currentView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        currentLabel!.isUserInteractionEnabled = true
        let subView = scrollView.subviews[0] // get the view
        setCenterScrollView(scrollView, subView)
    }
    
    func setCenterScrollView(_ scrollView: UIScrollView,_ subView: UIView?) {
        let offsetX = max(Double(scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5,0.0)
        let offsetY = max(Double(scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5,0.0)
        // adjust the center of view
        subView!.center = CGPoint(x: scrollView.contentSize.width * 0.5 + CGFloat(offsetX),y: scrollView.contentSize.height * 0.5 + CGFloat(offsetY))
    }
}

