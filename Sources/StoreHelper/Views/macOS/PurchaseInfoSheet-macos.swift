//
//  PurchaseInfoSheet.swift
//  StoreHelper
//
//  Created by Russell Archer on 05/01/2022.
//
// View hierachy:
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Consumables:     [Products].[ProductListView].[ProductListViewRow]......[ConsumableView]...[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI

#if os(macOS)
@available(macOS 12.0, *)
public struct PurchaseInfoSheet: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var extendedPurchaseInfo: ExtendedPurchaseInfo?
    @State private var showManagePurchase = false
    @Binding var showPurchaseInfoSheet: Bool
    var productId: ProductId
    var viewModel: PurchaseInfoViewModel
    
    public init(showPurchaseInfoSheet: Binding<Bool>, productId: ProductId, viewModel: PurchaseInfoViewModel) {
        self._showPurchaseInfoSheet = showPurchaseInfoSheet
        self.productId = productId
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            SheetBarView(showSheet: $showPurchaseInfoSheet, title: "Purchase Information", sysImage: "creditcard.circle")
            
            Image(productId)
                .resizable()
                .frame(maxWidth: 85, maxHeight: 85)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(25) 
            
            ScrollView {
                if let epi = extendedPurchaseInfo, epi.isPurchased {
                    
                    VStack {
                        PurchaseInfoFieldView(fieldName: "Product name:", fieldValue: epi.name)
                        PurchaseInfoFieldView(fieldName: "Product ID:", fieldValue: epi.productId)
                        PurchaseInfoFieldView(fieldName: "Price:", fieldValue: epi.purchasePrice ?? "Unknown")
                        
                        if epi.productType == .nonConsumable {
                            PurchaseInfoFieldView(fieldName: "Date:", fieldValue: epi.purchaseDateFormatted ?? "Unknown")
                            PurchaseInfoFieldView(fieldName: "Transaction:", fieldValue: String(epi.transactionId ?? UInt64.min))
                            PurchaseInfoFieldView(fieldName: "Purchase type:", fieldValue: epi.ownershipType == nil ? "Unknown" : (epi.ownershipType! == .purchased ? "Personal purchase" : "Family sharing"))
                            PurchaseInfoFieldView(fieldName: "Notes:", fieldValue: "\(epi.revocationDate == nil ? "-" : "Purchased revoked \(epi.revocationDateFormatted ?? "") \(epi.revocationReason == .developerIssue ? "(developer issue)" : "(other issue)")")")
                            
                        } else {
                            Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("No additional purchase information available")}
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(EdgeInsets(top: 1, leading: 5, bottom: 0, trailing: 5))
                        }
                    }
                    
                    Divider().padding(.bottom)
                    
                    DisclosureGroup(isExpanded: $showManagePurchase, content: {
                        Button(action: {
                            if  let sRefundUrl = storeHelper.configurationProvider?.value(configuration: .requestRefund) ?? Configuration.requestRefund.value(),
                                let refundUrl = URL(string: sRefundUrl) {
                                NSWorkspace.shared.open(refundUrl)
                            }
                        }) { Label("Request Refund", systemImage: "creditcard.circle")}.macOSStyle()

                    }) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("Manage Purchase")}.padding()},
                              icon:  { Image(systemName: "creditcard.circle").bodyImageNotRounded().frame(height: 24)})
                    }
                    .onTapGesture { withAnimation { showManagePurchase.toggle()}}
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20))
                    
                    Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("You may request a refund from the App Store if a purchase does not perform as expected. This requires you to authenticate with the App Store. Note that this app does not have access to credentials used to sign-in to the App Store.")}
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                } else {
                    TitleFont(scaleFactor: storeHelper.fontScaleFactor) { Text("No purchase information available")}
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 1, leading: 5, bottom: 0, trailing: 5))
                }
            }
        }
        .task { extendedPurchaseInfo = await viewModel.extendedPurchaseInfo(for: productId)}
        .frame(minWidth: 650, idealWidth: 650, maxWidth: 650, minHeight: 680, idealHeight: 680, maxHeight: 680)
        .fixedSize(horizontal: true, vertical: true)
    }
}

@available(macOS 12.0, *)
struct PurchaseInfoFieldView: View {
    let fieldName: String
    let fieldValue: String
    let edgeInsetsFieldValue = EdgeInsets(top: 7, leading: 5, bottom: 0, trailing: 5)
    let edgeInsetsFieldName = EdgeInsets(top: 7, leading: 25, bottom: 0, trailing: 5)
    let width: CGFloat = 140
    
    var body: some View {
        HStack {
            PurchaseInfoFieldText(text: fieldName).foregroundColor(.secondary).frame(width: width, alignment: .leading).padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 5))
            PurchaseInfoFieldText(text:fieldValue).foregroundColor(.blue).padding(EdgeInsets(top: 10, leading: 5, bottom: 0, trailing: 5))
            Spacer()
        }
    }
}

@available(macOS 12.0, *)
struct PurchaseInfoFieldText: View {
    @EnvironmentObject var storeHelper: StoreHelper
    let text: String
    
    var body: some View {
        // Note. We intentionaly don't support scalable fonts here
        Text(text).font(.title2)
    }
}
#endif
