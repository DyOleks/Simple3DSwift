//
//  Simple3D.swift - Created by Matt Reagan | (@hmblebee) | 1/19/19
//  Copyright © 2019 Matt Reagan. ** Please see README for license and info. **


// This Swift code sample sets up a basic framework for 3D transformations and
// rendering in a 2D space, using the Cocoa framework for graphical user interface elements on macOS.

//imports the Cocoa framework, which provides functionality for macOS applications, including graphical components, event handling, and user interface management
import Cocoa

//These constants are defined to assist with calculations related to the size of a view:
let ViewSize: CGFloat = 600.0                   // Total size of the view.
let HalfViewSize: CGFloat = (ViewSize / 2.0)    // Half the size of the view
let QuarterViewSize: CGFloat = (ViewSize / 4.0) // Quarter of the view size

// Represents the negative half of the view size, potentially used to position elements at the bottom of the view.
let FloorHeight: CGFloat = -HalfViewSize

//These lines define two colors using the NSColor class.
// The colors are specified in the RGB color model where each color component
// (red, green, and blue) is given a value from 0 to 255, and then normalized by dividing by 255
let blueColor = NSColor(calibratedRed: 15.0 / 255.0, green: 171.0 / 255.0, blue: 1.0, alpha: 1.0)
let brownColor = NSColor(calibratedRed: 110.0 / 255.0, green: 78.0 / 255.0, blue: 33.0 / 255.0, alpha: 1.0)

// Axis: An enumeration that defines the three axes (x, y, z) around which rotations can occur.
// Vec3: A structure representing a three-dimensional vector, with methods to rotate and translate this vector.
// 3D Transformations:
// Methods inside the Vec3 structure:
// rotated(by:around:): Rotates the vector around a specified axis by a given angle (in radians).
// translated(by:): Translates the vector by another vector, effectively adding the two vectors.
// The prefix - operator is overloaded to negate the vector components.
enum Axis { case x,y,z }
struct Vec3 {
    let x,y,z: CGFloat
    func rotated(by a: CGFloat, around axis: Axis) -> Vec3 {
        switch axis {
        case .x: return Vec3(x: x, y: cos(a) * y - sin(a) * z, z: sin(a) * y + cos(a) * z)
        case .y: return Vec3(x: cos(a) * x + sin(a) * z, y: y, z: -(sin(a) * x) + cos(a) * z)
        case .z: return Vec3(x: cos(a) * x - sin(a) * y, y: sin(a) * x + cos(a) * y, z: z)
        }
    }
    func translated(by v: Vec3) -> Vec3 { return Vec3(x: x + v.x, y: y + v.y, z: z + v.z) }
    static prefix func -(lhs: Vec3) -> Vec3 { return Vec3(x: -lhs.x, y: -lhs.y, z: -lhs.z) }
}

//This function computes the dot product of two vectors, which is a measure of their
//parallelism and is used in various graphics calculations.
func dotProd(_ v1: Vec3, _ v2: Vec3) -> CGFloat { return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z }

//This function translates a 3D point represented by a Vec3 to a 2D point in the
//view using perspective division. If the z component of the vector is
//negative, which implies the point is behind the viewer, the function returns nil
func renderedPtFromVec3(_ vector: Vec3) -> CGPoint? {
    if vector.z < 0.0 { return nil }
    let depth = vector.z > 0.0 ? vector.z / 600.0 : 0.000001 // leastNormalMagnitude (DBL_MIN) will produce +Inf
    return CGPoint(x: vector.x / depth + HalfViewSize, y: vector.y / depth + HalfViewSize)
}

//The renderedLine(from:to:) function in Swift is designed to convert a line segment defined in a 3D space by two points (Vec3 objects) into a 2D representation (CGPoint objects). This function takes into account whether parts of the line are behind the observer (the z-component is negative) and clips the line at the plane z=0 if necessary. Here's how it works step-by-step:
func renderedLine(from argV1: Vec3, to argV2: Vec3) -> (CGPoint, CGPoint)? {
    if argV1.z < 0.0 && argV2.z < 0.0 { return nil }//This checks if both points of the line segment are behind the viewer (i.e., both have a negative z-component). If true, the function returns nil as the line cannot be seen.
    
    if argV1.z >= 0.0 && argV2.z >= 0.0 { return (renderedPtFromVec3(argV1)!, renderedPtFromVec3(argV2)!) } //If both points are in front of the viewer (z-component is non-negative), the function directly computes and returns the 2D projections of these points using the renderedPtFromVec3() function.
    
    //Sorting Points
    let v1,v2: Vec3
    if argV1.z > argV2.z { v1 = argV1; v2 = argV2; } else { v1 = argV2; v2 = argV1; } //The function ensures that v1 is the point closer to or further into the viewer's space compared to v2. This is done to facilitate the clipping operation which comes next.
    
    //dVec is the direction vector from v1 to v2.
    //n is a normal vector pointing along the z-axis, used to determine the intersection of the line segment with the z=0 plane.
    //t calculates the interpolation parameter where the line crosses the z=0 plane using the plane equation and the direction vector.
    //p1 computes the actual 3D coordinates of the intersection point using t.
    let dVec = v2.translated(by: -v1)
    let n = Vec3(x: 0, y: 0, z: 1)
    let t = -(dotProd(v1, n)) / dotProd(dVec, n)
    let p1 = Vec3(x: v1.x + dVec.x * t, y: v1.y + dVec.y * t, z: v1.z + dVec.z * t)
    
    // This attempts to render both points v1 and p1. If either point fails to render
    // (which might occur if p1.z does not properly evaluate to 0 due to floating-point
    // precision issues), the function returns nil.
    guard let renderP0 = renderedPtFromVec3(v1), 
          let renderP1 = renderedPtFromVec3(p1) else { return nil }
    
    //Finally, the function returns a tuple containing the 2D projections of the
    //visible segments of the original line.
    return (renderP0, renderP1)
}

    //This Swift code defines a Shape structure used to represent various 3D shapes and objects in a graphical application. The Shape structure includes properties for vertices, edges, faces, and additional attributes such as color and animation settings. It also provides static methods to create specific shapes like a cube, a pyramid, and a grid floor. Here’s a detailed explanation of the code:

struct Shape {
    //The Shape structure encapsulates the data and methods for 3D shapes.
    let vectors: [Vec3] //An array of Vec3 representing the vertices of the shape.
    let lines: [(Int, Int)] //An array of tuples, each representing an edge by indexing into the vectors array.
    let faces:  [(Int, Int, Int, Int)] //An array of tuples, each representing a face by indexing into the vectors array.
    let color: NSColor
    let objectCenter: Vec3
    let animates: Bool
    let bulletAngle: Vec3?
    var shootTime: CGFloat = 0
    
    static func cube(width: CGFloat, height: CGFloat, at center: Vec3, animated: Bool = false, color: NSColor = brownColor, bulletAngle: Vec3? = nil) -> Shape {
        let halfW = width / 2.0; let halfH = height / 2.0
        let vec = [Vec3(x: -halfW, y: halfH, z: -halfW), Vec3(x: -halfW, y: -halfH, z: -halfW),
                   Vec3(x: halfW, y: -halfH, z: -halfW), Vec3(x: halfW, y: halfH, z: -halfW),
                   Vec3(x: -halfW, y: halfH, z: halfW), Vec3(x: -halfW, y: -halfH, z: halfW),
                   Vec3(x: halfW, y: -halfH, z: halfW), Vec3(x: halfW, y: halfH, z: halfW)]
        let translatedVec = vec.map({ return $0.translated(by: center) })
        return Shape(vectors: translatedVec,
                     lines: [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)],
                     faces: [(0, 1, 2, 3), (7, 6, 5, 4), (4, 5, 1, 0), (3, 2, 6, 7), (4, 0, 3, 7), (1, 5, 6, 2)],
                     color: color, objectCenter: center, animates: animated, bulletAngle: bulletAngle, shootTime: 0)
    }
    
    static func pyramid(size: CGFloat, at center: Vec3, animated: Bool = false, color: NSColor = NSColor.green) -> Shape {
        let halfSize = size / 2.0
        let vec = [Vec3(x: -halfSize, y: -halfSize, z: halfSize), Vec3(x: -halfSize, y: -halfSize, z: -halfSize),
                   Vec3(x: halfSize, y: -halfSize, z: -halfSize), Vec3(x: halfSize, y: -halfSize, z: halfSize),
                   Vec3(x: 0.0, y: halfSize, z: 0.0)]
        let translatedVec = vec.map({ return $0.translated(by: center) })
        return Shape(vectors: translatedVec,
                     lines: [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (1, 4), (2, 4), (3, 4)],
                     faces: [(0, 1, 4, 0), (1, 2, 4, 1), (2, 3, 4, 2), (3, 0, 4, 3),],
                     color: color, objectCenter: center, animates: animated, bulletAngle: nil, shootTime: 0)
    }
    
    static func gridFloor(of size: Int, squareSize: CGFloat) -> Shape {
        var vectors = [Vec3]()
        var lines = [(Int, Int)]()
        let halfGridSize = CGFloat(size) * squareSize / 2.0
        for xi in 0..<size {
            for zi in 0..<size {
                let x = CGFloat(xi) * squareSize - halfGridSize
                let z = CGFloat(zi) * squareSize - halfGridSize
                vectors.append(Vec3(x: x, y: FloorHeight, z: z))
            }
        }
        
        for x in 0..<size {
            lines.append((x, size * size - size + x))
            lines.append((x * size, x * size + (size - 1)))
        }
        
        return Shape(vectors: vectors, lines: lines, faces: [],
                     color: NSColor(calibratedRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
                     objectCenter: Vec3(x: 0.0, y: 0.0, z: 0.0), animates: false, bulletAngle: nil, shootTime: 0)
    }
}

var worldShapes = [Shape.gridFloor(of: 40, squareSize: QuarterViewSize),
                   Shape.cube(width: HalfViewSize, height: HalfViewSize, at: Vec3(x: 0.0, y: 0.0, z: ViewSize), animated: true, color: blueColor),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: -1200.0, y: ViewSize, z: 800.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: -1200.0, y: 0.0, z: 800.0)),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: -1300.0, y: ViewSize, z: -500.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: -1300.0, y: 0.0, z: -500.0)),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: 600.0, y: ViewSize, z: 1300.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: 600.0, y: 0.0, z: 1300.0)),
                   Shape.pyramid(size: ViewSize * 0.6, at: Vec3(x: 1200.0, y: 260, z: 600.0)),
                   Shape.cube(width: QuarterViewSize * 0.6, height: 380.0, at: Vec3(x: 1200.0, y: -100.0, z: 600.0))]

// Define a custom NSView subclass called MyView
class MyView: NSView {
    // Properties for handling animation, camera angle, and position
    var shapeSpinAnimationAngle: CGFloat = 0.0
    var cameraAngle = Vec3(x: 0.0, y: 0.0, z: 0.0)
    var cameraPosition = Vec3(x: 0.0, y: 0.0, z: 1500.0)
    var turnAmount: CGFloat = 0.0
    var moveAmount: CGFloat = 0.0
    
    // Called when the view is added to a window
    override func viewDidMoveToWindow() {
        // Schedule a timer to call the timer() function at 60 FPS
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in self?.timer() }
        // Make this view the first responder for receiving key events
        DispatchQueue.main.async { self.window?.makeFirstResponder(self) }
    }
    
    // Handle key down events for controlling movement and shooting
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: turnAmount = 0.05 // Left arrow key
        case 124: turnAmount = -0.05 // Right arrow key
        case 126: moveAmount = -40.0 // Up arrow key
        case 125: moveAmount = 40.0 // Down arrow key
        case 49: shootBox() // Spacebar key
        default: return
        }
    }
    
    // Handle key up events to stop movement
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 123, 124: turnAmount = 0.0 // Stop turning
        case 125, 126: moveAmount = 0.0 // Stop moving
        default: return
        }
    }
    
    // Timer function called at 60 FPS
    func timer() {
        // Update the angle for shape spinning
        shapeSpinAnimationAngle += 0.014
        // Update the camera position and angle
        updateCamera()
        // Mark the view as needing display to trigger a redraw
        setNeedsDisplay(bounds)
    }
    
    // Update the camera's angle and position based on user input
    func updateCamera() {
        // Update the camera's angle based on turn amount
        cameraAngle = Vec3(x: cameraAngle.x, y: cameraAngle.y + turnAmount, z: cameraAngle.z)
        // Calculate the movement vector and apply it to the camera's position
        let move = Vec3(x: 0.0, y: 0.0, z: moveAmount).rotated(by: cameraAngle.y, around: .y)
        cameraPosition = Vec3(x: cameraPosition.x - move.x, y: cameraPosition.y - move.y, z: cameraPosition.z + move.z)
    }
    
    // Box size constant
    let boxSize: CGFloat = 100.0
    
    // Function to shoot a box from the camera's position
    func shootBox() {
        // Calculate the shooting angle with some randomness
        let angle = Vec3(x: cameraAngle.x, y: cameraAngle.y + CGFloat.random(in: -0.25...0.25), z: cameraAngle.z)
        // Create a new cube shape
        let cube = Shape.cube(width: boxSize, height: boxSize, at: -cameraPosition, animated: true,
                              color: NSColor.magenta.blended(withFraction: CGFloat.random(in: 0...1.0), of: NSColor.yellow)!, bulletAngle: angle)
        // Add the new cube to the worldShapes array
        worldShapes.append(cube)
    }
    
    // Draw the view's contents
    override func draw(_ dirtyRect: NSRect) {
        // Set the background color to black and fill the bounds
        NSColor.black.set()
        bounds.fill()
        
        // Iterate over each shape in the worldShapes array
        for (shapeIndex, shape) in worldShapes.enumerated() {
            // Map each vector of the shape to its transformed position
            let shapeVec = shape.vectors.map { v -> Vec3 in
                var vec = v
                // Apply animations and transformations to the shape's vectors
                vec = shape.animates ? vec.translated(by: -shape.objectCenter).rotated(by: shapeSpinAnimationAngle, around: .y).translated(by: shape.objectCenter) : vec
                
                // Apply bullet movement if the shape is a bullet
                if let bang = shape.bulletAngle {
                    vec = vec.translated(by: Vec3(x: 0.0, y:-pow(shape.shootTime / 2.0, 3.0), z: 10.0 * pow(shape.shootTime, 2.0)).rotated(by: -bang.y, around: .y))
                    // Update shootTime if the bullet is still above the floor
                    if vec.y > FloorHeight + boxSize / 2.0 {
                        var updatedShape = shape
                        updatedShape.shootTime += 0.84
                        worldShapes.remove(at: shapeIndex)
                        worldShapes.insert(updatedShape, at: shapeIndex)
                    }
                }
                
                // Apply camera transformations to the shape's vectors
                return vec.translated(by: cameraPosition).rotated(by: cameraAngle.y, around: .y)
            }
            
            // Set the shape's color for drawing
            shape.color.set()
            // Draw each line of the shape
            for line in shape.lines {
                guard let points = renderedLine(from: shapeVec[line.0], to: shapeVec[line.1]) else { continue }
                NSBezierPath.strokeLine(from: points.0, to: points.1)
            }
            
            // Set the shape's color with transparency for drawing faces
            shape.color.withAlphaComponent(0.20).set()
            // Draw each face of the shape
            for face in shape.faces {
                let points = [shapeVec[face.0], shapeVec[face.1], shapeVec[face.2], shapeVec[face.3]].compactMap { renderedPtFromVec3($0) }
                guard points.count == 4 else { continue }
                let path = NSBezierPath()
                path.move(to: points[0])
                path.line(to: points[1])
                path.line(to: points[2])
                path.line(to: points[3])
                path.fill()
            }
            
            // Set the color for drawing the vertices
            NSColor.green.set()
            // Draw each vertex of the shape
            for vector in shapeVec {
                guard let pt = renderedPtFromVec3(vector) else { continue }
                CGRect(x: pt.x, y: pt.y, width: 0.0, height: 0.0).insetBy(dx: -1.0, dy: -1.0).fill()
            }
        }
    }
}

// Main application delegate class
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate { }
