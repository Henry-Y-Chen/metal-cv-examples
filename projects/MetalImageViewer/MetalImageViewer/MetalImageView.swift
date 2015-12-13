//
//  MetalImageView.swift
//  MetalImageViewer
//
//  Created by Yankang Chen on 12/13/15.
//  Copyright © 2015 Henry Chen. All rights reserved.
//

import MetalKit

// MARK: - Class Extensions

extension MTKTextureLoader {
    
    func newTextureWithUIImage(image: UIImage) -> MTLTexture? {
        if let cgImage = image.CGImage {
            do {
                return try newTextureWithCGImage(cgImage, options: nil)
            } catch let error as NSError {
                print("[ERROR] - Failed to create a new MTLTexture from the CGImage. \(error)")
            }
        } else {
            print("[ERROR] - Failed to get a CGImage from the UIImage.")
        }
        
        return nil
    }
    
}

// MARK - Metal Image View Class

class MetalImageView: MTKView {
    
    // MARK: Properties
    
    var commandQueue: MTLCommandQueue?
    var imageTexture: MTLTexture? {
        didSet {
            if let texture = imageTexture {
                self.drawableSize = CGSize(width: texture.width, height: texture.height)
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: Texture Loaders
    
    func loadUIImage(image: UIImage) {
        if let device = self.device {
            imageTexture = MTKTextureLoader(device: device).newTextureWithUIImage(image)
        }
    }
    
    // MARK: Initializer
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        initCommon()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        initCommon()
    }
    
    private func initCommon() {
        // Enable drawable texture read/write.
        framebufferOnly = false
        
        // Flip the view vertically.
        transform = CGAffineTransformMakeScale(1.0, -1.0)
        
        // Diable drawable auto-resize.
        autoResizeDrawable = false
        
        // Set auto scale aspect fit.
        contentMode = .ScaleAspectFit
        
        // Change drawing mode to only draw on notification.
        enableSetNeedsDisplay = true
        paused = true
    }
    
    // MARK: Draw
    
    override func drawRect(rect: CGRect) {
        if let commandQueue = self.commandQueue,
            imageTexture = self.imageTexture,
            currentDrawable = self.currentDrawable
        {
            let commandBuffer = commandQueue.commandBuffer()
            
            // Copy the image texture to the texture of the current drawable
            let blitEncoder = commandBuffer.blitCommandEncoder()
            blitEncoder.copyFromTexture(imageTexture, sourceSlice: 0, sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSizeMake(imageTexture.width, imageTexture.height, imageTexture.depth),
                toTexture: currentDrawable.texture, destinationSlice: 0, destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
            
            // Present current drawable
            commandBuffer.presentDrawable(currentDrawable)
            commandBuffer.commit()
        }
    }

}
