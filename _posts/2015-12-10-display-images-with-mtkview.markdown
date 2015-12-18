---
layout: post
title:  "Display Images with MTKView"
date:   2015-12-13 13:21:21 -0800
categories: metal-cv-basics
---

As the first post in this blog, some "pre-party" chats should do no harm. I am interested to know what brings you to this blog. Metal? Computer vision? Both? Neither? Justin Bieber? Leave me comments if you like.

This blog is more like a collection of my development notes, but I will do my best to make it as readable and friendly as tutorials. With my horrible English writing, will this go well? If you like to read codes rather than blog posts, all source codes are available in the [GitHub](https://github.com/Henry-Y-Chen/metal-cv-examples/tree/master/projects). 

I would focus on implementing algorithms and solving problems. That is to say, I may not cover many details on computer vision concepts nor the Swift and Metal languages. If you need any of those, here are some helpful references.

* If you are keen to know more about computer vision, read [Computer Vision:  Models, Learning, and Inference by Simon J.D. Prince](http://www.computervisionmodels.com).

* If Swift is new to you, Apple has a concise tutorial - [Learn the Essentials of Swift](https://developer.apple.com/library/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Lesson1.html).

* If you want to learn Metal, [Metal By Example by Warren Moore](http://metalbyexample.com), [Tutorials by Ray Wenderlich](http://www.raywenderlich.com/77488/ios-8-metal-tutorial-swift-getting-started) and [Metal Programming Guide](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide) helped me a lot. Really appreciate their awesome works!

* For more Metal applications and examples, check out [official sample codes from Apple](https://developer.apple.com/search/?q=metal&platform=iOS&type=Sample%20Code) and [FlexMonkey's blog](http://flexmonkey.blogspot.com)

**[NOTICE] - Metal is not available in iOS simulators yet. To include MetalKit and MetalPerformanceshaders frameworks, a supported iOS9 device and XCode7 are required. Check the iOS device compatibility [here](https://developer.apple.com/library/ios/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/OpenGLESPlatforms/OpenGLESPlatforms.html). OS X El Capitan also supports metal on all Macs introduced since 2012.**

<br/>

---

<br/> 

In the next several posts, I will work with Lena (a.k.a. Lenna). The [original 512x512 TIFF image](http://sipi.usc.edu/database/download.php?vol=misc&img=4.2.04) is still available in the [USC SIPI Image Database](http://sipi.usc.edu/database/)'s [miscellaneous](http://sipi.usc.edu/database/?volume=misc) collection. But I will use this converted [512x512 PNG version]({{ site.baseurl }}/imagebase/Lena.png). (Deep inside some classic computer science pros live playboys. Check out [A Complete Story of Lenna](http://www.ee.cityu.edu.hk/~lmpo/lenna/Lenna97.html).)
<p style="text-align: center"><img src="{{ site.baseurl }}/imagebase/Lena.png" alt="Lena" width="320px"></p>

Create a new `Single View Application` using `Swift` in `Language` option. Make sure the new project's `Deployment Target` is at least `9.0`. Add `Lena.png` into the project. 

I will build a basic view to render Lena onto my iPhone screen using Metal and MetalKit. All the projects later will be based on this viewer.

<br/>

---

<br/>

# Now let's get swift on the metal works.#
<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/meme001.jpg" alt="No pun intended." width="320px"></p>

In `ViewController.swift`, import the Metal framework.

{% highlight swift %}
import Metal
{% endhighlight %}

Get the system default Metal device and create a new Metal command queue . If the creation failed, print an error message in console.

{% highlight swift %}
override func viewDidLoad() {
    super.viewDidLoad()
    
    // Get the default Metal device and create a new command queue
    if let metalDevice = MTLCreateSystemDefaultDevice() {
        let metalCommandQueue = metalDevice.newCommandQueue()
    } else {
        print("[ERROR] - No available Metal device.")
    }
}
{% endhighlight %}

**If the Xcode shows compiler errors, make sure you are not building the project on iOS simulators. Use your iPhone/iPad or the (build only) generic iOS device.**

Run the project on an iPhone/iPad. If everything goes well, the console will show confirmation messages:
{% highlight pypylog %}
2015-12-12 11:00:02.197 MetalImageViewer[673:309014] Metal GPU Frame Capture Enabled
2015-12-12 11:00:02.197 MetalImageViewer[673:309014] Metal API Validation Enabled
{% endhighlight %}

<br/>

---

<br/>

Now let's prototype the MetalImageView class. It should be able to read an UIImage into a MTLTexture then render the texture through Metal. The MTKView class from MetalKit framework offers the lowest overheads.

Create a `New File` as a `Cocoa Touch Class`. Name it `MetalImageView` and make it a subclass of `MTKView`.

In `MetalImageView.swift`, Xcode should report a compiler error about the undefined MTKView. Fix it by replacing `import UIKit` with
{% highlight swift %}
import MetalKit
{% endhighlight %}

For all methods in the MetalImageView class, the metal device, command queue and the texture from image should be accessible. So they should be defined as instance properties. MTKView class has already declared `device`. Similar to it, we also use optionals, so we don't have to initialize them.

{% highlight swift %}
var commandQueue: MTLCommandQueue?
var imageTexture: MTLTexture?
{% endhighlight %}

The `MTKTextureLoader` from MetalKit has a method `newTextureWithCGImage:options:error:`, which loads a CGImage into a MTLTexture.

Outside the `class MetalImageView: MTKView {}`, define an extension to the MTKTextureLoader class. Define a new method `newTextureWithUIImage:`

{% highlight swift %}
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
{% endhighlight %}

Back inside the MetalImageView class, create a method to use the extended MTKTextureLoader.

{% highlight swift %}
func loadUIImage(image: UIImage) {
    if let device = self.device {
        imageTexture = MTKTextureLoader(device: device).newTextureWithUIImage(image)
    }
}
{% endhighlight %}

Texture done! Time for a show!

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/meme002.jpg" alt="This texture offends me." width="320px"></p>

If you removed the `drawRect:` because you enjoy holding your coffee/beer and watching your clean code, now it's time to bring it back uncommented.

{% highlight swift %}
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
{% endhighlight %}

What does the `MTLBlitCommandEncoder` do?

> The MTLBlitCommandEncoder provides methods for copying data between resources (buffers and textures). - [Metal Programming Guide](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Blit-Ctx/Blit-Ctx.html).

Make an instance of out new class in storyboard. Open the `Main.storyboard` and drag an `UIView` into the `View Controller`'s `view`. In the UIView's `Identity Inspector`, change its `class` to `MetalImageView`. Add some constrains. I constrained it as zero spacing to nearest neighbor on all 4 directions, and **unchecked** `Constrain to margins`.
<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot001.png" alt="Metal image view constrains." width="320px"></p>

Use `control + drag` to create an IBOutlet in the `ViewController.swift` .

{% highlight swift %}
@IBOutlet weak var metalImageView: MetalImageView!
{% endhighlight %}

<br/>

---

<br/>

I hate keeping ladies waiting. Let's invite Lena. 

In `ViewController.swift`, add a constant property:

{% highlight swift %}
let imageName = "Lena"
{% endhighlight %}

Add following code into the `viewDidLoad` right after we created a new metal command queue.

{% highlight swift %}
// Assign device and command queue to view
metalImageView.device = metalDevice
metalImageView.commandQueue = metalCommandQueue

// Load image
if let image = UIImage(named: imageName) {
    metalImageView.loadUIImage(image)
} else {
    print("[ERROR] - Failed to read the image named \(imageName).")
}
{% endhighlight %}

Now the `viewDidLoad` looks like this:

{% highlight swift %}
override func viewDidLoad() {
    super.viewDidLoad()
    
    // Get the default Metal device and create a new command queue
    if let metalDevice = MTLCreateSystemDefaultDevice() {
        let metalCommandQueue = metalDevice.newCommandQueue()
        
        // Assign device and command queue to view
        metalImageView.device = metalDevice
        metalImageView.commandQueue = metalCommandQueue
        
        // Load image
        if let image = UIImage(named: imageName) {
            metalImageView.loadUIImage(image)
        } else {
            print("[ERROR] - Failed to read the image named \(imageName).")
        }
    } else {
        print("[ERROR] - No available Metal device.")
    }
}
{% endhighlight %}

Build and run! run! run! Why you runtime error?!

{% highlight pypylog %}
2015-12-12 11:14:51.824 MetalImageViewer[685:311330] Metal GPU Frame Capture Enabled
2015-12-12 11:14:51.825 MetalImageViewer[685:311330] Metal API Validation Enabled
/BuildRoot/Library/Caches/com.apple.xbs/Sources/Metal/Metal-55.2.6.1/ToolsLayers/Debug/MTLDebugBlitCommandEncoder.mm:164: failed assertion `destinationTexture must not be a framebufferOnly texture.'
(lldb) 
{% endhighlight %}

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/meme003.jpg" alt="Y U RUNTIME ERROR?" width="320px"></p>

This can be simply fixed by setting the `framebufferOnly` property of `MTKView` as `false`. `framebufferOnly = false` enables us to read/write the texture in MTLDrawables rather than display only. I will do this in intializers. Add those initializers in the `MetalImageView` class.

{% highlight swift %}
override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    
    initCommon()
}

required init(coder: NSCoder) {
    super.init(coder: coder)
    
    initCommon()
}

private func initCommon() {
    framebufferOnly = false
}
{% endhighlight %}

Again, build and run!

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot002.png" alt="Screenshot002" width="640px"></p>

Nailed it! Wait... Lena is upside down. To fix this, we have two options: flip the image or flip the view. I prefer fliping the view, so if I need to load another image later, I don't need to flip the new image again. In `initCommon`, add this line after setting the framebufferOnly.

{% highlight swift %}
transform = CGAffineTransformMakeScale(1.0, -1.0)
{% endhighlight %}

Build and run.
<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot003.png" alt="Screenshot003" width="640px"></p>

That worked. I wanted to stop it here, but my OCD did not agree. The drawable's texture and our image texture from Lena have different dimensions. So the image only fill its size (512 x 512 px) and leave the rest of drawable in the deep darkness. I can't leave it this way. I'd like to have the drawable resized, whenever the texture changed. I could do this in the `loadUIImage:` method, but most likely later I will have more methods updating the texture, then I will need to resize the drawable in every methods. So I use the `didSet` of `imageTexture`	property instead. In `MetalImageView` class, change the declaration of `imageTexture` property like this:

{% highlight swift %}
var imageTexture: MTLTexture? {
    didSet {
        if let texture = imageTexture {
            self.drawableSize = CGSize(width: texture.width, height: texture.height)
        }
    }
}
{% endhighlight %}

And add this line to the `initCommon` to turn off drawable auto-resizing.

{% highlight swift %}
autoResizeDrawable = false
{% endhighlight %}

Cool! Lena is taking my full screen.
<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot004.png" alt="Screenshot004" width="640px"></p>

But she is stretched. Quick fix: use `UIView`'s `contentMode`. In the `initCommon` method, add another line.
{% highlight swift %}
contentMode = .ScaleAspectFit
{% endhighlight %}

Neat!

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot005.png" alt="Screenshot005" width="640px"></p>

Now I can submit the "Lena Viewer" app to the App Store, then drink some beer collecting more junks in Fallout 4. Later, I may get a comment like this:

> Lena is so hot that my battery burnt out.

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/meme004.jpg" alt="Now I need marshmallow." width="320px"></p>

Run the project again, and check the `Debug Navigator`.

<p style="text-align: center"><img src="{{ site.baseurl }}/post-images/screenshot006.png" alt="Screenshot006" width="640px"></p>

Though the energy impact is still low, the same image was rendered at the rate of 60 FPS. It is totally a waste of system resources, and will drain battery. The `MTKView` class offers a drawing mode that only draws by a view notification. Similar to `UIView`, it draws when `setNeedsDisplay` is called. To turn on this mode, just set both `paused` and `enableSetNeedsDisplay` to `ture`. For other drawing modes, check [here](https://developer.apple.com/library/ios/documentation/MetalKit/Reference/MTKView_ClassReference).

Add following two lines in `initCommon`:

{% highlight swift %}
paused = true
enableSetNeedsDisplay = true
{% endhighlight %}

Now the `initCommon` should look like this:

{% highlight swift %}
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
{% endhighlight %}

Call `setNeedsDisplay` in `imageTexture`'s `didSet`. The `imageTexture` declaration should look like:

{% highlight swift %}
var imageTexture: MTLTexture? {
    didSet {
        if let texture = imageTexture {
            self.drawableSize = CGSize(width: texture.width, height: texture.height)
            setNeedsDisplay()
        }
    }
}
{% endhighlight %}

Build, run and check the framerate. Done! The Xcode project can be found in [GitHub](https://github.com/Henry-Y-Chen/metal-cv-examples/tree/master/projects/MetalImageViewer).

This was the first post in this serie. If you had any trouble following my note, or have some suggestions, or just wanna drop by and say hi, leave me comments. Thanks for visiting Metal CV Example blog!