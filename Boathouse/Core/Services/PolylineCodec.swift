import Foundation
import CoreLocation

/// Google Encoded Polyline Algorithm codec
/// Reference: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
enum PolylineCodec {

    // MARK: - Decode

    /// Decode a Google encoded polyline string into an array of coordinates
    static func decode(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let characters = Array(encoded.utf8)
        let length = characters.count
        var index = 0
        var latitude: Int32 = 0
        var longitude: Int32 = 0

        while index < length {
            // Decode latitude
            var result: Int32 = 0
            var shift: Int32 = 0
            var byte: Int32

            repeat {
                guard index < length else { break }
                byte = Int32(characters[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            latitude += dlat

            // Decode longitude
            result = 0
            shift = 0

            repeat {
                guard index < length else { break }
                byte = Int32(characters[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            longitude += dlng

            let coord = CLLocationCoordinate2D(
                latitude: Double(latitude) / 1e5,
                longitude: Double(longitude) / 1e5
            )
            coordinates.append(coord)
        }

        return coordinates
    }

    // MARK: - Encode

    /// Encode an array of coordinates into a Google encoded polyline string
    static func encode(_ coordinates: [CLLocationCoordinate2D]) -> String {
        var encoded = ""
        var previousLatitude: Int32 = 0
        var previousLongitude: Int32 = 0

        for coordinate in coordinates {
            let lat = Int32(round(coordinate.latitude * 1e5))
            let lng = Int32(round(coordinate.longitude * 1e5))

            encoded += encodeValue(lat - previousLatitude)
            encoded += encodeValue(lng - previousLongitude)

            previousLatitude = lat
            previousLongitude = lng
        }

        return encoded
    }

    private static func encodeValue(_ value: Int32) -> String {
        var v = value < 0 ? ~(value << 1) : (value << 1)
        var encoded = ""

        while v >= 0x20 {
            let char = UnicodeScalar(Int((v & 0x1F) | 0x20) + 63)!
            encoded += String(char)
            v >>= 5
        }

        let char = UnicodeScalar(Int(v) + 63)!
        encoded += String(char)

        return encoded
    }

    // MARK: - Route Generation (for mock data)

    /// Generate a deterministic route between two coordinates with natural-looking curves
    static func generateRoute(
        from start: Coordinate,
        to end: Coordinate,
        pointCount: Int = 30
    ) -> String {
        var coordinates: [CLLocationCoordinate2D] = []

        for i in 0..<pointCount {
            let t = Double(i) / Double(pointCount - 1)
            // Use sine waves for natural-looking waterway meander
            let wave1 = sin(t * .pi * 3) * 0.002
            let wave2 = sin(t * .pi * 5) * 0.001

            let lat = start.latitude + (end.latitude - start.latitude) * t + wave1
            let lng = start.longitude + (end.longitude - start.longitude) * t + wave2

            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }

        return encode(coordinates)
    }

    /// Generate a loop route around a center coordinate (for sessions without end location)
    static func generateLoopRoute(
        center: CLLocationCoordinate2D,
        radiusDegrees: Double = 0.008,
        pointCount: Int = 40
    ) -> String {
        var coordinates: [CLLocationCoordinate2D] = []

        for i in 0..<pointCount {
            let angle = (Double(i) / Double(pointCount)) * 2 * .pi
            let wobble = sin(angle * 3) * radiusDegrees * 0.3

            let lat = center.latitude + (radiusDegrees + wobble) * sin(angle)
            let lng = center.longitude + (radiusDegrees + wobble) * cos(angle) * 1.4

            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }

        // Close the loop
        coordinates.append(coordinates[0])

        return encode(coordinates)
    }
}
