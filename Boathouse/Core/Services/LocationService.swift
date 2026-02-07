import Foundation
import CoreLocation

/// Service for location validation and UK boundary checking
final class LocationService {
    static let shared = LocationService()

    // UK bounding box coordinates (approximate)
    private let ukBounds = (
        minLatitude: 49.8,   // South
        maxLatitude: 60.9,   // North (includes Shetland)
        minLongitude: -8.2,  // West (includes Northern Ireland)
        maxLongitude: 1.8    // East
    )

    /// Check if a coordinate is within the UK
    func isInUK(latitude: Double, longitude: Double) -> Bool {
        return latitude >= ukBounds.minLatitude &&
               latitude <= ukBounds.maxLatitude &&
               longitude >= ukBounds.minLongitude &&
               longitude <= ukBounds.maxLongitude
    }

    /// Check if a coordinate is within the UK
    func isInUK(coordinate: Coordinate) -> Bool {
        isInUK(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Check if a CLLocationCoordinate2D is within the UK
    func isInUK(coordinate: CLLocationCoordinate2D) -> Bool {
        isInUK(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Validate a session's location is within the UK
    func validateSessionLocation(session: Session) -> Bool {
        // Check start location
        if let start = session.startLocation {
            guard isInUK(coordinate: start) else { return false }
        }

        // Check end location
        if let end = session.endLocation {
            guard isInUK(coordinate: end) else { return false }
        }

        // If no locations provided, cannot validate
        guard session.startLocation != nil || session.endLocation != nil else {
            return false
        }

        return true
    }

    /// Decode polyline and check if all points are within the UK
    func validatePolyline(_ polyline: String) -> Bool {
        let coordinates = decodePolyline(polyline)

        // Check a sample of points (every 10th point for efficiency)
        let sampleSize = max(1, coordinates.count / 10)
        for i in stride(from: 0, to: coordinates.count, by: sampleSize) {
            let coord = coordinates[i]
            if !isInUK(latitude: coord.latitude, longitude: coord.longitude) {
                return false
            }
        }

        // Always check first and last
        if let first = coordinates.first {
            if !isInUK(latitude: first.latitude, longitude: first.longitude) {
                return false
            }
        }

        if let last = coordinates.last {
            if !isInUK(latitude: last.latitude, longitude: last.longitude) {
                return false
            }
        }

        return true
    }

    /// Decode Google polyline encoding format
    private func decodePolyline(_ polyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = polyline.startIndex
        var latitude = 0
        var longitude = 0

        while index < polyline.endIndex {
            // Decode latitude
            var result = 0
            var shift = 0
            var byte: Int

            repeat {
                byte = Int(polyline[index].asciiValue ?? 0) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = polyline.index(after: index)
            } while byte >= 0x20 && index < polyline.endIndex

            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            latitude += deltaLat

            // Decode longitude
            result = 0
            shift = 0

            while index < polyline.endIndex {
                byte = Int(polyline[index].asciiValue ?? 0) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = polyline.index(after: index)

                if byte < 0x20 {
                    break
                }
            }

            let deltaLon = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            longitude += deltaLon

            let coord = CLLocationCoordinate2D(
                latitude: Double(latitude) / 1e5,
                longitude: Double(longitude) / 1e5
            )
            coordinates.append(coord)
        }

        return coordinates
    }
}
