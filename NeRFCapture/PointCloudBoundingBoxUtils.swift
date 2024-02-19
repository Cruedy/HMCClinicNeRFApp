import RealityKit
import ARKit

func createBoundingBoxForPointCloud(frame: ARFrame) -> (size: SIMD3<Float>, center: SIMD3<Float>)? {
    // Extract the ARPointCloud from the current frame.
    let pointCloud = frame.rawFeaturePoints

    // Create an empty array to store filtered points.
    var filteredPoints: [SIMD3<Float>] = []

    for point in pointCloud!.points {
        // Customize your filtering criteria here.
        // For example, you can skip points that are too far or filter outliers.

        // Skip points that are too far from the device (adjust the threshold as needed).
        let maxDistanceToCamera: Float = 5.0
        if length(point) > maxDistanceToCamera {
            continue
        }

        // Add the point to the filtered points array.
        filteredPoints.append(point)
    }

    // Check if there are filtered points.
    guard !filteredPoints.isEmpty else {
        print("No filtered points found.")
        return nil
    }

    // Calculate the minimum (`localMin`) and maximum (`localMax`) corners of the bounding box.
    var localMin = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
    var localMax = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)

    for point in filteredPoints {
        localMin = min(localMin, point)
        localMax = max(localMax, point)
    }

    // Calculate the size and center of the bounding box.
    let size = localMax - localMin
    let center = (localMax + localMin) / 2

    print("Filtered points count: \(filteredPoints.count)")
    print("Bounding box size: \(size)")
    print("Bounding box center: \(center)")

    return (size, center)
}

