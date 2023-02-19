//
//  PurchaseBarView.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/01/21.
//

import SwiftUI

struct PurchaseBarView: View {
    @Namespace var heroEffect
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var goodsViewModel: GoodsViewModel
    
    @Binding var showOptionSheet: Bool
    @Binding var orderType: OrderType
    
    @State private var showOrderTypeAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0),
                                    .black.opacity(0.1),
                                    .black.opacity(0.2),
                                    .black.opacity(0.3)
            ], startPoint: .top, endPoint: .bottom)
            .frame(height: 5)
            .opacity(0.3)
            .background(.clear)
            
            purchaseMode()
                .padding(.vertical, 8)
                .padding(.horizontal, 25)
                .frame(height: 70)
                .background(.white)
        }
        .background(.clear)
    }
    
    @State private var isWished: Bool = false
    
    func purchaseMode() -> some View {
        HStack(spacing: 20) {
            ZStack {
                if !showOptionSheet {
                    Button {
                        withAnimation {
                            isWished.toggle()
                        }
                    } label: {
                        VStack(spacing: 0) {
                            if isWished {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("main-highlight-color"))
                            } else {
                                Image(systemName: "heart")
                                    .font(.title2)
                            }
                            
                            Text("찜하기")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(Color("main-text-color"))
                }
                
                Button {
                    withAnimation {
                        goodsViewModel.sendCartGoodsRequest(token: loginViewModel.returnToken())
                        goodsViewModel.seletedGoods.quantity = 0
                        goodsViewModel.seletedGoods.color = nil
                        goodsViewModel.seletedGoods.size = nil
                    }
                } label: {
                    HStack {
                        Spacer()
                        
                        Text("장바구니 담기")
                            .font(.subheadline.bold())
                            .foregroundColor(Color("main-highlight-color"))
                            .padding(.vertical)
                        
                        Spacer()
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("main-highlight-color"))
                }
                .frame(width: showOptionSheet ? nil : 30)
                .opacity(showOptionSheet ? 1 : 0)
                .disabled(!showOptionSheet)
            }
            
            if showOptionSheet {
                NavigationLink {
                    OrderView(orderType: $orderType, orderGoods: [OrderItem(color: goodsViewModel.seletedGoods.color, size: goodsViewModel.seletedGoods.size, quantity: goodsViewModel.seletedGoods.quantity, price: goodsViewModel.goodsDetail.price)])
                        .navigationTitle("주문서 작성")
                        .navigationBarTitleDisplayMode(.inline)
                        .modifier(NavigationColorModifier())
                } label: {
                    HStack {
                        Spacer()
                        
                        Text("주문하기")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical)
                        
                        Spacer()
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color("main-highlight-color"))
                }
                .matchedGeometryEffect(id: "구매하기", in: heroEffect)
            } else {
                Button {
                    showOrderTypeAlert = true
                } label: {
                    HStack {
                        Spacer()
                        
                        Text("주문하기")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical)
                        
                        Spacer()
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color("main-highlight-color"))
                }
                .matchedGeometryEffect(id: "구매하기", in: heroEffect)
                .alert("주문 방법 안내", isPresented: $showOrderTypeAlert) {
                    Button {
                        withAnimation(.spring()) {
                            showOptionSheet = true
                        }
                    } label: {
                        Text("확인")
                    }

                } message: {
                    Text("해당 상품은 현장 수령만 가능합니다.")
                }

            }
        }
    }
}

struct PurchaseBarView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseBarView(showOptionSheet: .constant(false), orderType: .constant(.pickUpOrder))
            .environmentObject(GoodsViewModel())
            .environmentObject(LoginViewModel())
    }
}
