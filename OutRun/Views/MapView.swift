//
//  MapView.swift
//
//  OutRun
//  Copyright (C) 2022 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import Combine
import MapKit
import CoreLocation

public struct MapView: UIViewRepresentable {
    
    @Binding var mapType: MKMapType
    @Binding var region: MKCoordinateRegion?
    @Binding var camera: MKMapCamera?
    @Binding var isZoomEnabled: Bool
    @Binding var isScrollEnabled: Bool
    @Binding var showsUserLocation: Bool
    @Binding var showsCompass: Bool
    @Binding var userTrackingMode: MKUserTrackingMode
    @Binding var annotations: [MKAnnotation]
    @Binding var overlays: [MKOverlay]

    // MARK: - Initializer
    
    init(
        mapType: Binding<MKMapType> = .constant(.standard),
        region: Binding<MKCoordinateRegion?> = .constant(nil),
        camera: Binding<MKMapCamera?> = .constant(nil),
        isZoomEnabled: Binding<Bool> = .constant(true),
        isScrollEnabled: Binding<Bool> = .constant(true),
        showsUserLocation: Binding<Bool> = .constant(true),
        showsCompass: Binding<Bool> = .constant(false),
        userTrackingMode: Binding<MKUserTrackingMode> = .constant(.follow),
        annotations: Binding<[MKAnnotation]> = .constant([]),
        overlays: Binding<[MKOverlay]> = .constant([])
    ) {
        self._mapType = mapType
        self._region = region
        self._camera = camera
        self._isZoomEnabled = isZoomEnabled
        self._isScrollEnabled = isScrollEnabled
        self._showsUserLocation = showsUserLocation
        self._showsCompass = showsCompass
        self._userTrackingMode = userTrackingMode
        self._annotations = annotations
        self._overlays = overlays
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(for: self)
    }
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        configureView(mapView)
        return mapView
    }
    
    public func updateUIView(_ uiView: MKMapView, context: Context) {
        configureView(uiView)
    }
    
    // MARK: - Updates
    
    private func configureView(_ mapView: MKMapView) {
        mapView.mapType = self.mapType
        if let mapRegion = self.region {
            let region = mapView.regionThatFits(mapRegion)
            if region.center != mapView.region.center || region.span != mapView.region.span {
                mapView.setRegion(region, animated: true)
            }
        }
        if let camera = self.camera {
            mapView.setCamera(camera, animated: true)
        }
        mapView.isZoomEnabled = self.isZoomEnabled
        mapView.isScrollEnabled = self.isScrollEnabled
        mapView.showsCompass = self.showsCompass
        mapView.showsUserLocation = self.showsUserLocation
        mapView.userTrackingMode = self.userTrackingMode
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 50, maxCenterCoordinateDistance: 2000)
        
        self.updateAnnotations(in: mapView)
        self.updateOverlays(in: mapView)
    }
    
    private func updateAnnotations(in mapView: MKMapView) {
        let currentAnnotations = mapView.annotations
        let obsoleteAnnotations = currentAnnotations.filter { mapAnnotation in
            !self.annotations.contains { $0.isEqual(mapAnnotation) }
        }
        let newAnnotations = self.annotations.filter { mapAnnotation in
            !currentAnnotations.contains { $0.isEqual(mapAnnotation) }
        }
        mapView.removeAnnotations(obsoleteAnnotations)
        mapView.addAnnotations(newAnnotations)
    }
    
    private func updateOverlays(in mapView: MKMapView) {
        let currentOverlays = mapView.overlays
        let obsoleteOverlays = currentOverlays.filter { mapOverlay in
            !self.overlays.contains { $0.isEqual(mapOverlay) }
        }
        let newAnnotations = self.overlays.filter { mapOverlay in
            !currentOverlays.contains { $0.isEqual(mapOverlay) }
        }
        mapView.removeOverlays(obsoleteOverlays)
        mapView.addAnnotations(newAnnotations)
    }
    
    // MARK: - Corrdinator
    
    public class Coordinator: NSObject, MKMapViewDelegate {
        
        private let context: MapView
        
        init(for context: MapView) {
            self.context = context
            super.init()
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .tintColor
            renderer.lineWidth = 4
            return renderer
        }
        
        public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.context.region = mapView.region
            }
        }
    }
}
