import StoreKit
import SwiftUI

struct TipJarSettingsScene: View {
    
    @State private var showThankYou: Bool = false
    @State private var purchaseError: Error?

    @ScaledMetric private var tipImageSize: CGFloat = 70

    var body: some View {
        List {
            Section {
                VStack(spacing: .regular) {
                    Image(systemName: "star.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .frame(height: 100)
                    Text("tip_jar_message")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(TipProduct.allCases) { tip in
                    ProductView(id: tip.id) {
                        Image(systemName: tip.systemImage)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.tint)
                            .padding(.small)
                            .frame(width: tipImageSize)
                    }
                }
            }
            .productViewStyle(.compact)
            Section {
                SettingsOpenURLButton(ExternalURL.appStoreReview) {
                    Text("tip_jar_leave_review")
                }
                SettingsOpenURLButton(ExternalURL.support) {
                    LabeledContent("tip_jar_say_thanks", value: ExternalURL.supportAddress)
                }
            } header: {
                Text("tip_jar_other_ways_header")
            } footer: {
                Text("tip_jar_other_ways_footer")
            }
        }
        .safeAreaPadding(.vertical, .regular)
        .navigationTitle("tip_jar")
        .onInAppPurchaseCompletion(perform: handlePurchaseCompletion)
        .alert("tip_jar_thank_you_title", isPresented: $showThankYou) {
            Button("ok") {}
        } message: {
            Text("tip_jar_thank_you_message")
        }
        .errorAlert($purchaseError)
    }
    
    private func handlePurchaseCompletion(product: Product, result: Result<Product.PurchaseResult, any Error>) async {
        switch result {
        case .success(let purchaseResult):
            showThankYou = await TipJarService.handle(purchaseResult)
        case .failure(let error):
            purchaseError = error
        }
    }
}
