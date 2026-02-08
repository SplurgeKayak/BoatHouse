import SwiftUI
import CoreLocation

/// Lightweight Canvas-drawn route preview replacing heavy MapKit Map in feed cards.
/// Draws a polyline scaled to fit, with no tile loading or map framework overhead.
struct RoutePreviewShape: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Canvas { context, size in
            guard coordinates.count >= 2 else { return }

            let lats = coordinates.map(\.latitude)
            let lngs = coordinates.map(\.longitude)

            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLng = lngs.min(), let maxLng = lngs.max() else { return }

            let latRange = maxLat - minLat
            let lngRange = maxLng - minLng

            // Avoid division by zero for single-point routes
            let safeLat = latRange > 0 ? latRange : 0.001
            let safeLng = lngRange > 0 ? lngRange : 0.001

            let padding: CGFloat = 12
            let drawW = size.width - padding * 2
            let drawH = size.height - padding * 2

            // Scale to fit maintaining aspect ratio
            let scaleX = drawW / safeLng
            let scaleY = drawH / safeLat
            let scale = min(scaleX, scaleY)

            let scaledW = safeLng * scale
            let scaledH = safeLat * scale
            let offsetX = padding + (drawW - scaledW) / 2
            let offsetY = padding + (drawH - scaledH) / 2

            func point(for coord: CLLocationCoordinate2D) -> CGPoint {
                let x = offsetX + (coord.longitude - minLng) * scale
                let y = offsetY + scaledH - (coord.latitude - minLat) * scale
                return CGPoint(x: x, y: y)
            }

            var path = Path()
            path.move(to: point(for: coordinates[0]))
            for coord in coordinates.dropFirst() {
                path.addLine(to: point(for: coord))
            }

            context.stroke(
                path,
                with: .color(Color.accentColor),
                lineWidth: 2.5
            )

            // Start dot
            let startPt = point(for: coordinates[0])
            context.fill(
                Path(ellipseIn: CGRect(x: startPt.x - 3, y: startPt.y - 3, width: 6, height: 6)),
                with: .color(.green)
            )

            // End dot
            let endPt = point(for: coordinates[coordinates.count - 1])
            context.fill(
                Path(ellipseIn: CGRect(x: endPt.x - 3, y: endPt.y - 3, width: 6, height: 6)),
                with: .color(.red)
            )
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
