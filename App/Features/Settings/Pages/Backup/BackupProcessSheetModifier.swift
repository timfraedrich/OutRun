//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import SwiftUI

struct BackupProcessSheetModifier: ViewModifier {
    
    @Binding private var process: BackupProcess?
    
    init(process: Binding<BackupProcess?>) {
        _process = process
    }
    
    func body(content: Content) -> some View {
        content.dynamicSheet(item: $process, content: processSheetContent)
    }
    
    @ViewBuilder
    private func processSheetContent(_ process: BackupProcess) -> some View {
        VStack(spacing: .extraLarge) {
            VStack(spacing: .small) {
                Text(process.title).font(.title).fontWeight(.bold)
                Text(verbatim: process.message).font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, .extraLarge)
            }
            if let symbolSystemName = process.symbolSystemName {
                Image(systemName: symbolSystemName)
                    .symbolRenderingMode(.multicolor)
                    .font(.largeTitle)
            }
            if let progress = process.progress {
                ProgressView(value: progress).progressViewStyle(.linear)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .padding([.top, .horizontal], .extraLarge)
        .padding(.bottom, .regular)
        .interactiveDismissDisabled(!process.isDismissable)
    }
}

extension View {
    
    @ViewBuilder
    func backupProcessSheet(for process: Binding<BackupProcess?>) -> some View {
        modifier(BackupProcessSheetModifier(process: process))
    }
}
