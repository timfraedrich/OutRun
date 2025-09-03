//
//  WorkoutCard.swift
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

struct WorkoutCard: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: WorkoutCardModel
    
    var body: some View {
        AxisGeometryReader { width in
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constants.UI.Padding.normal) {
                    MetricView(viewModel: viewModel.titleMetric)
                    HStack(alignment: .top, spacing: Constants.UI.Padding.normal) {
                        ForEach(viewModel.metrics, id: \.title) { metric in
                            VStack(alignment: .leading) {
                                MetricView(viewModel: metric)
                            }
                        }
                    }
                }.padding(Constants.UI.Padding.small)
                Spacer(minLength: 0)
                ZStack {
                    Color.gray.opacity(0.1)
                    if let mapImage = viewModel.mapImage {
                        Image(uiImage: mapImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                    .frame(width: width / 2.25, height: 125)
                    .cornerRadius(Constants.UI.CornerRadius.small)
                    .onAppear { viewModel.loadImage(colorScheme: colorScheme) }
                    .onChange(of: colorScheme, perform: viewModel.loadImage)
            }
            .padding(Constants.UI.Padding.small)
            .background(Color.secondaryBackground)
            .cornerRadius(Constants.UI.CornerRadius.normal)
        }
    }
    
    init(viewModel: WorkoutCardModel) {
        self.viewModel = viewModel
    }
}

struct WorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutCard(viewModel: .init())
            .padding()
    }
}
