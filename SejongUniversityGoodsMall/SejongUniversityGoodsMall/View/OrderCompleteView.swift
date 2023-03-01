//
//  OrderCompleteView.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/03/01.
//

import SwiftUI

struct OrderCompleteView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var goodsViewModel: GoodsViewModel
    
    @State private var limitDate: String = ""
    
    private var orderCompleteCloseAction: () -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 350, maximum: .infinity), spacing: nil, alignment: .top)
    ]
    
    init(orderCompleteCloseAction: @escaping () -> Void) {
        self.orderCompleteCloseAction = orderCompleteCloseAction
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("shape-bkg-color"))
                    .frame(height: 10)
                
                Text("상품 주문이 완료되었습니다.")
                    .font(.title3)
                    .padding(.top)
                
                Text("입금 기한: \(limitDate) 까지")
                    .foregroundColor(Color("main-highlight-color"))
                    .padding(.vertical)
                    .onAppear() {
                        if let date = goodsViewModel.orderCompleteGoods?.createdAt {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy.MM.dd HH시 mm분"
                            limitDate = formatter.string(from: date.addingTimeInterval(3600 * 24 * 2 + 3600 * 9))
                        }
                    }
                
                LazyVGrid(columns: columns) {
                    if let orderCompletGoods = goodsViewModel.orderCompleteGoods?.orderItems {
                        ForEach(orderCompletGoods, id: \.hashValue) { goods in
                            orderCompleteGoods(goods: goods)
                        }
                    }
                }
                
                Button {
                    
                } label: {
                    HStack {
                        Spacer()
                        
                        Text("주문 내역 확인하기")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                        
                        Spacer()
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color("main-highlight-color"))
                    }
                }
                .padding([.horizontal, .bottom])
                .padding(.vertical, 20)
                .padding(.top, 20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: orderCompleteCloseAction){
                    Label("닫기", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .font(.footnote)
                        .foregroundColor(Color("main-text-color"))
                }
            }
        }
        .navigationTitle("주문완료")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(NavigationColorModifier())
        .background(.white)
    }
    
    @ViewBuilder
    func orderCompleteGoods(goods: OrderItem) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color("shape-bkg-color"))
                .frame(height: 10)
                       
            subOrderGoods(goods: goods)
            
            if let seller = goods.seller {
                Group {
                    orderCompleteInfo(title: "예금주", content: seller.accountHolder)
                    
                    orderCompleteInfo(title: "입금은행", content: seller.bank)
                    
                    orderCompleteInfo(title: "계좌번호", content: seller.account)
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    func subOrderGoods(goods: OrderItem) -> some View {
        VStack {
            HStack() {
                if let image = goodsViewModel.goodsDetail.goodsImages.first {
                    AsyncImage(url: URL(string: image.oriImgName)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ZStack {
                            Color("main-shape-bkg-color")
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            ProgressView()
                                .tint(Color("main-highlight-color"))
                        }
                    }
                    .frame(width: 100, height: 100)
                    .shadow(radius: 1)
                }
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        
                        Text(goodsViewModel.goodsDetail.title)
                            .foregroundColor(Color("main-text-color"))
                            .padding(.trailing)
                        
                        Group {
                            if let color = goods.color, let size = goods.size {
                                Text("\(color), \(size)")
                            } else {
                                Text("\(goods.color ?? "")\(goods.size ?? "")")
                            }
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color("main-text-color"))
                        .padding(.leading)
                        .background(alignment: .leading) {
                            Rectangle()
                                .fill(Color("main-text-color"))
                                .frame(width: 1)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    HStack {
                        Text(goodsViewModel.goodsDetail.seller.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("point-color"))
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                            Text("\(goods.price)원")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("main-text-color"))
                        
                        Spacer()
                        
                        Text("수량 \(goods.quantity)개")
                            .font(.caption.bold())
                            .foregroundColor(Color("main-text-color"))
                    }
                }
                .padding(10)
            }
            .padding(.vertical)
            
            Rectangle()
                .foregroundColor(Color("shape-bkg-color"))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func subOrderCartGoods(goods: CartGoodsResponse) -> some View {
        VStack {
            HStack() {
                AsyncImage(url: URL(string: goods.repImage.oriImgName)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ZStack {
                            Color("main-shape-bkg-color")
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            ProgressView()
                                .tint(Color("main-highlight-color"))
                        }
                    }
                    .frame(width: 100, height: 100)
                    .shadow(radius: 1)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(goods.title)
                            .foregroundColor(Color("main-text-color"))
                            .padding(.trailing)
                        
                        Group {
                            if let color = goods.color, let size = goods.size {
                                Text("\(color), \(size)")
                            } else {
                                Text("\(goods.color ?? "")\(goods.size ?? "")")
                            }
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color("main-text-color"))
                        .padding(.leading)
                        .background(alignment: .leading) {
                            Rectangle()
                                .fill(Color("main-text-color"))
                                .frame(width: 1)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    HStack {
                        Text(goods.seller)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("point-color"))
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                            Text("\(goods.price * goods.quantity)원")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("main-text-color"))
                        
                        Spacer()
                        
                        Text("수량 \(goods.quantity)개")
                            .font(.caption.bold())
                            .foregroundColor(Color("main-text-color"))
                    }
                }
                .padding(10)
            }
            .padding(.vertical)
            
            Rectangle()
                .foregroundColor(Color("shape-bkg-color"))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func orderCompleteInfo(title: String, content: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Color("secondary-text-color-strong"))
                .frame(minWidth: 100)
            
            Text(content)
                .foregroundColor(Color("main-text-color"))
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical)
        .background(alignment: .bottom) {
            Rectangle()
                .foregroundColor(Color("shape-bkg-color"))
                .frame(height: 1)
        }
    }
}

struct OrderCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        OrderCompleteView() {
            
        }
        .environmentObject(GoodsViewModel())
        .environmentObject(LoginViewModel())
    }
}
