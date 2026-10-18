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
import TFMarkdown

struct LegalDocumentScene: View {
    
    let document: LegalDocument
    
    var body: some View {
        Group {
            if let url = document.url, let content = try? String(contentsOf: url, encoding: .utf8) {
                ScrollView {
                    MarkdownView(markdown: content)
                        .font(.subheadline)
                        .padding([.horizontal, .bottom], .large)
                }
            } else {
                ContentUnavailableView("legal_document_unavailable", systemImage: "doc.questionmark")
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentScene(document: .termsOfService)
    }
}
