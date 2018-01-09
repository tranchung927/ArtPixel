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
    var itemWidth: CGFloat = 0
    var itemHeight: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    fileprivate var currentLabel: UILabel?
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pixels = Array<Array<UIView>>()
    
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
        let image = UIImage(named: imageName)!.cropIfNeed(aspectFillToSize: maxImageSize)
        displayImage(image!)
    }
    
    fileprivate func displayImage(_ image: UIImage) {
        self.busyView.isHidden = false
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            let // Rotate first because the orientation is lost when resizing.
            rotatedImage = image.imageRotatedToPortraitOrientation(),
            resizedImage = rotatedImage.imageConstrainedToMaxSize(self.maxImageSize),
            asciiArtist  = AsciiArtist(resizedImage, self.palette),
            asciiArt     = asciiArtist.createAsciiArt()
            
            DispatchQueue.main.async {
                self.displayAsciiArt(asciiArt, matrix: asciiArtist.matrix)
                self.busyView.isHidden = true
            }
        }
    }
    
    fileprivate func displayAsciiArt(_ asciiArt: String, matrix: [[Double]]) {
        let label = UILabel()
        label.font = self.labelFont
        label.lineBreakMode = NSLineBreakMode.byClipping
        label.numberOfLines = 0
        label.text = asciiArt
        label.sizeToFit()
//        print(asciiArt)
        currentLabel?.removeFromSuperview()
        currentLabel = label
        label.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        tapGestureRecognizer.delegate = self
        label.addGestureRecognizer(tapGestureRecognizer)
        let dragGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleDrag(sender:)))
        dragGestureRecognizer.minimumPressDuration = 0.25
        label.addGestureRecognizer(dragGestureRecognizer)
        scrollView.addSubview(label)
        scrollView.contentSize = label.frame.size
        
        self.updateZoomSettings(animated: false)
        scrollView.contentOffset = CGPoint.zero
        self.createView(label.bounds.size.width, label.bounds.size.height, matrix[0].count, matrix.count)
    }
    
    func createView(_ width: CGFloat,_ height: CGFloat,_ numberOfItemInRow: Int,_ numberOfItemInColumn: Int) {
        print("image size \(numberOfItemInRow)x\(numberOfItemInColumn)")
        self.width = width
        self.height = height
        let itemWidth = width / CGFloat(numberOfItemInRow)
        let itemHeight = height / CGFloat(numberOfItemInColumn)
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.pixels = []
        for x in 0..<numberOfItemInRow {
            pixels.append([])
            for y in 0..<numberOfItemInColumn {
                let view = UIView()
                view.frame = CGRect(x: CGFloat(x) * itemWidth, y: CGFloat(y) * itemHeight, width: itemWidth, height: itemHeight)
                view.backgroundColor = UIColor.clear
                view.layer.borderWidth = 0.1
                view.layer.borderColor = UIColor.black.cgColor
                view.alpha = 0.5
                self.currentLabel!.addSubview(view)
                self.pixels[x].append(view)
            }
        }
        print("\(self.pixels.count): \(self.pixels[0].count)")
    }
    @objc private func handleTap(sender: UIGestureRecognizer) {
        print("tapped: \(sender.location(in: currentLabel))")
        self.draw(atPoint: sender.location(in: currentLabel), Int(self.width), and: Int(self.height))
    }
    
    @objc private func handleDrag(sender: UIGestureRecognizer) {
        switch sender.state {
        case .changed, .began:
            print("changed & began: \(sender.location(in: currentLabel))")
            self.draw(atPoint: sender.location(in: currentLabel), Int(self.width), and: Int(self.height))
        case .ended:
            print("End")
        default: break
        }
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
        setCenterScrollView(scrollView, currentLabel)
        return currentLabel
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
  
    private func draw(atPoint point: CGPoint,_ width: Int, and height: Int) {
        let y = Int(point.y / self.itemHeight)
        let x = Int(point.x / self.itemWidth)
        guard y < height && x < width && y >= 0 && x >= 0 else { return }
        pixels[x][y].backgroundColor = UIColor.red
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
