//
//  BaseMapMenuView.swift
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
import CoreLocation
import CoreLocationUI
import MapKit

public struct BaseMapMenuView<MapOverlayContent: View, MenuContent: View>: View {
    
    // TODO: Make map customisable (region/camera, accessories, etc.)
    @State
    private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 51.7222,
            longitude: -0.1275),
        span: MKCoordinateSpan(
            latitudeDelta: 0.005,
            longitudeDelta: 0.005
        )
    )
    
    private let closeButtonAction: () -> Void
    private let mapOverlayContent: () -> MapOverlayContent
    private let menuContent: () -> MenuContent
    
    public var body: some View {
        VStack(spacing: -Constants.UI.Padding.big) {
            ZStack {
                MapView(/*region: $region.optional*/)
                ZStack {
                    CornerView(corner: .topRight) {
                        CloseButton(action: closeButtonAction)
                    }
                    mapOverlayContent()
                }.padding(.bottom, Constants.UI.Padding.big)
                .padding(Constants.UI.Padding.small)
            }.ignoresSafeArea()
            MenuView(content: menuContent)
        }.onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }
    
    public init(
        closeButtonAction: @escaping () -> Void,
        @ViewBuilder mapOverlayContent: @escaping () -> MapOverlayContent,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.closeButtonAction = closeButtonAction
        self.mapOverlayContent = mapOverlayContent
        self.menuContent = menuContent
    }
    
    public init(
        closeButtonAction: @escaping () -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) where MapOverlayContent == EmptyView {
        self.init(
            closeButtonAction: closeButtonAction,
            mapOverlayContent: { EmptyView() },
            menuContent: menuContent
        )
    }
}



public struct MenuView<Content: View>: View {
    
    private let content: () -> Content
    
    public var body: some View {
        VStack {
            content()
        }
            .padding(Constants.UI.Padding.normal)
            .frame(maxWidth: .infinity)
            .background(Color.background)
            .cornerRadius(Constants.UI.CornerRadius.normal)
    }
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}

struct BaseMapMenuView_Previews: PreviewProvider {
    static var previews: some View {
        BaseMapMenuView(closeButtonAction: {}) {
            Text("Hello World")
                .font(.title2)
        }
    }
}
