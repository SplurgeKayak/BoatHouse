import SwiftUI
import MapKit

/// Map preview showing a session's route as a polyline overlay
/// Uses iOS 17+ SwiftUI MapKit APIs
@available(iOS 17.0, *)
struct SessionMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        if coordinates.count >= 2 {
            Map(initialPosition: mapCameraPosition) {
                MapPolyline(coordinates: coordinates)
                    .stroke(AppColors.accent, lineWidth: 3)
            }
            .mapStyle(.standard(elevation: .flat))
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var mapCameraPosition: MapCameraPosition {
        let region = regionForCoordinates(coordinates)
        return .region(region)
    }

    private func regionForCoordinates(_ coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        var minLat = coords[0].latitude
        var maxLat = coords[0].latitude
        var minLng = coords[0].longitude
        var maxLng = coords[0].longitude

        for coord in coords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLng = max(maxLng, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let latDelta = (maxLat - minLat) * 1.4 + 0.002
        let lngDelta = (maxLng - minLng) * 1.4 + 0.002

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.005),
                longitudeDelta: max(lngDelta, 0.005)
            )
        )
    }
}

#Preview {
    SessionMapView(coordinates: [
        CLLocationCoordinate2D(latitude: 51.4615, longitude: -0.3015),
        CLLocationCoordinate2D(latitude: 51.465, longitude: -0.295),
        CLLocationCoordinate2D(latitude: 51.470, longitude: -0.290),
        CLLocationCoordinate2D(latitude: 51.475, longitude: -0.282),
        CLLocationCoordinate2D(latitude: 51.4812, longitude: -0.2734)
    ])
    .frame(height: 160)
    .padding()
}
