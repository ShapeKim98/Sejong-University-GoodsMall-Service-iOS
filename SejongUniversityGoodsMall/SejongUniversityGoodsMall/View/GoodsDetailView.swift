//
//  GoodsDetailView.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/01/19.
//

import SwiftUI

struct GoodsDetailView: View {
    enum Servie {
        case goodsInformation
        case sellerInformation
    }
    
    enum DeviceType {
        case oldiPhone
        case noneNotchiPhone
        case noneNotchiPhonePlus
        case notchiPhoneMini
        case notchiPhone
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Namespace var heroEffect
    
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var goodsViewModel: GoodsViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    @State private var service: Servie = .goodsInformation
    @State private var showOptionSheet: Bool = false
    @State private var imagePage: Int = 1
    @State private var optionSheetDrag: CGFloat = .zero
    @State private var isOptionSelected: Bool = false
    @State private var showHelpAlert: Bool = false
    @State private var vibrateOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = .zero
    @State private var showScrapMessage: Bool = false
    @State private var deviceType: DeviceType = .notchiPhone
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .top) {
                if let goods = goodsViewModel.goodsDetail {
                    Group {
                        imageView(goods: goods, height: reader.size.width)
                    }
                    .zIndex(scrollOffset <= 0 ? 2 : 0)
                    
                    ScrollView {
                        VStack {
                            Spacer()
                                .frame(height: reader.size.width)
                            
                            VStack {
                                VStack(spacing: 10) {
                                    HStack(spacing: 0) {
                                        Text("\(imagePage) ")
                                            .foregroundColor(Color("main-text-color"))
                                        Text("/ \(goods.goodsImages.count)")
                                            .foregroundColor(Color("secondary-text-color"))
                                        
                                        Spacer()
                                    }
                                    .font(.footnote)
                                    .padding(.horizontal)
                                    
                                    nameAndPriceView(goods: goods)
                                }
                                .padding(.vertical)
                                
                                Rectangle()
                                    .foregroundColor(Color("shape-bkg-color"))
                                    .frame(height: 10)
                                
                                switch service {
                                    case .goodsInformation:
                                        goodsInformationPage(goods: goods)
                                    case .sellerInformation:
                                        sellerInformationPage(goods: goods)
                                }
                                
                                Spacer()
                                    .frame(height: 80)
                            }
                            .background(.white)
                        }
                        .background {
                            GeometryReader { reader in
                                let offset = -reader.frame(in: .named("SCROLL")).minY
                                Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                            }
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .controlSize(.large)
                                .padding()
                                .tint(Color("main-highlight-color"))
                                .unredacted()
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
            .coordinateSpace(name: "SCROLL")
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    if showOptionSheet {
                        OptionSheetView(isOptionSelected: $isOptionSelected, vibrateOffset: $vibrateOffset)
                            .frame(height: reader.size.height - (deviceType == .oldiPhone ? 180 : (deviceType == .noneNotchiPhone ? 270 : (deviceType == .noneNotchiPhonePlus ? 350 : (deviceType == .notchiPhoneMini ? reader.size.width - 15 : (horizontalSizeClass == .regular ? 700 : reader.size.width))))) + 5)
                            .transition(.move(edge: .bottom))
                            .offset(y: optionSheetDrag)
                            .gesture(
                                DragGesture()
                                    .onChanged({ drag in
                                        if !isOptionSelected {
                                            optionSheetDrag = drag.translation.height > 0 ? drag.translation.height : drag.translation.height / 10
                                        } else {
                                            optionSheetDrag = drag.translation.height / 10
                                        }
                                    })
                                    .onEnded({ drag in
                                        withAnimation(.spring()) {
                                            if optionSheetDrag > 100 {
                                                optionSheetDrag = .zero
                                                showOptionSheet = false
                                                isOptionSelected = false
                                            } else {
                                                optionSheetDrag = .zero
                                            }
                                        }
                                    })
                            )
                    }
                    
                    if !isOptionSelected {
                        purchaseBar()
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .fullScreenCover(isPresented: $goodsViewModel.showOrderView) {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        OrderView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        if goodsViewModel.isOrderComplete {
                                            goodsViewModel.orderGoodsInfoList.removeAll()
                                            dismiss()
                                        }
                                        
                                        goodsViewModel.orderGoods.removeAll()
                                        goodsViewModel.orderGoodsListFromCart.removeAll()
                                        goodsViewModel.cartIDList.removeAll()
                                        goodsViewModel.isOrderComplete = false
                                        
                                        goodsViewModel.showOrderView = false
                                    } label: {
                                        Label("닫기", systemImage: "xmark")
                                            .labelStyle(.iconOnly)
                                            .font(.footnote)
                                            .foregroundColor(Color("main-text-color"))
                                    }
                                }
                            }
                            .onAppear() {
                                goodsViewModel.orderGoods.append(OrderItem(color: goodsViewModel.seletedGoods.color, size: goodsViewModel.seletedGoods.size, quantity: goodsViewModel.seletedGoods.quantity, price: (goodsViewModel.goodsDetail?.price ?? 0) * goodsViewModel.seletedGoods.quantity, orderStatus: nil))
                            }
                    }
                    .overlay {
                        ZStack {
                            if appViewModel.showMessageBoxBackground {
                                Color(.black).opacity(0.4)
                            }
                            
                            if appViewModel.showMessageBox {
                                MessageBoxView()
                                    .transition(.move(edge: .bottom))
                            }
                        }
                        .ignoresSafeArea()
                    }
                    .overlay {
                        if let errorView = goodsViewModel.errorView {
                            errorView
                                .transition(.opacity.animation(.easeInOut))
                        }
                    }
                } else {
                    NavigationView {
                        OrderView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        if goodsViewModel.isOrderComplete {
                                            goodsViewModel.orderGoodsInfoList.removeAll()
                                            dismiss()
                                        }
                                        
                                        goodsViewModel.orderGoods.removeAll()
                                        goodsViewModel.orderGoodsListFromCart.removeAll()
                                        goodsViewModel.cartIDList.removeAll()
                                        goodsViewModel.isOrderComplete = false
                                        
                                        goodsViewModel.showOrderView = false
                                    } label: {
                                        Label("닫기", systemImage: "xmark")
                                            .labelStyle(.iconOnly)
                                            .font(.footnote)
                                            .foregroundColor(Color("main-text-color"))
                                    }
                                }
                            }
                            .onAppear() {
                                goodsViewModel.orderGoods.append(OrderItem(color: goodsViewModel.seletedGoods.color, size: goodsViewModel.seletedGoods.size, quantity: goodsViewModel.seletedGoods.quantity, price: (goodsViewModel.goodsDetail?.price ?? 0) * goodsViewModel.seletedGoods.quantity, orderStatus: nil))
                            }
                    }
                    .overlay {
                        ZStack {
                            if appViewModel.showMessageBoxBackground {
                                Color(.black).opacity(0.4)
                            }
                            
                            if appViewModel.showMessageBox {
                                MessageBoxView()
                                    .transition(.move(edge: .bottom))
                            }
                        }
                        .ignoresSafeArea()
                    }
                    .overlay {
                        if let errorView = goodsViewModel.errorView {
                            errorView
                                .transition(.opacity.animation(.easeInOut))
                        }
                    }
                }
            }
            .onAppear() {
                let width = reader.size.width
                let height = reader.size.height

                switch width {
                    case 320 where height == 568:
                        deviceType = .oldiPhone
                    case 375 where height == 667:
                        deviceType = .noneNotchiPhone
                        break
                    case 414 where height == 736:
                        deviceType = .noneNotchiPhonePlus
                        break
                    case 375 where height == 812:
                        deviceType = .notchiPhoneMini
                    default:
                        deviceType = .notchiPhone
                        break
                }
            }
            .onDisappear() {
                goodsViewModel.seletedGoods.color = nil
                goodsViewModel.seletedGoods.size = nil
                goodsViewModel.seletedGoods.quantity = 0
                goodsViewModel.goodsDetail = nil
            }
            .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
    }
    
    @ViewBuilder
    func imageView(goods: Goods, height: CGFloat) -> some View {
        TabView(selection: $imagePage) {
            ForEach(goods.goodsImages, id: \.id) { image in
                AsyncImage(url: URL(string: image.oriImgName)) { img in
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: height, height: height - (scrollOffset < 0 ? scrollOffset : 0))
                } placeholder: {
                    ZStack {
                        Color("shape-bkg-color")
                        
                        ProgressView()
                            .tint(Color("main-highlight-color"))
                            .controlSize(.large)
                    }
                }
                .frame(width: height, height: height - (scrollOffset < 0 ? scrollOffset : 0))
                .tag(image.id - goods.id)
                .overlay {
                    Color(.black)
                        .opacity(scrollOffset / (height * 2))
                }
            }
        }
        .frame(height: height - (scrollOffset < 0 ? scrollOffset : 0))
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    @ViewBuilder
    func nameAndPriceView(goods: Goods) -> some View {
        HStack {
            Text(goods.title)
                .font(.title2.bold())
                .foregroundColor(Color("main-text-color"))
                .padding(.horizontal, 5)
            
            Spacer()
            
            switch goods.seller.method {
                case .both:
                    Text("현장수령, 택배수령")
                        .font(.caption)
                        .foregroundColor(Color("point-color"))
                case .pickUp:
                    Text("현장수령")
                        .font(.caption)
                        .foregroundColor(Color("point-color"))
                case .delivery:
                    Text("택배수령")
                        .font(.caption)
                        .foregroundColor(Color("point-color"))
            }
        }
        .padding(.horizontal)
        
        HStack {
            Text("\(goods.price)원")
                .font(.title.bold())
                .foregroundColor(Color("main-text-color"))
                .padding(.horizontal, 5)
            
            Spacer()
            
            if !(goods.seller.method == .pickUp) {
                if goods.deliveryFee == 0 {
                    Label("무료배송", systemImage: "box.truck")
                        .font(.caption)
                        .foregroundColor(Color("point-color"))
                } else {
                    Label("\(goods.deliveryFee)원", systemImage: "box.truck")
                        .font(.caption)
                        .foregroundColor(Color("point-color"))
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func goodsInformationView() -> some View {
        HStack {
            Spacer()
            
            serviceButton("상품정보", .goodsInformation) {
                withAnimation(.spring()) {
                    service = .goodsInformation
                }
            }
            
            Spacer(minLength: 150)
            
            serviceButton("판매자 정보", .sellerInformation) {
                withAnimation(.spring()) {
                    service = .sellerInformation
                }
            }
            
            Spacer()
        }
        .padding(.top, 10)
        .background(alignment: .bottom) {
            Rectangle()
                .foregroundColor(Color("shape-bkg-color"))
                .frame(height: 1)
        }
        .background(.white)
    }
    
    @ViewBuilder
    func serviceButton(_ title: String, _ seleted: Servie, _ action: @escaping () -> Void) -> some View {
        let isSelected = service == seleted
        
        Button(action: action) {
            VStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .light)
                    .foregroundColor(isSelected ? Color("main-text-color") : Color("secondary-text-color"))
                    .padding(.bottom, 10)
            }
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .foregroundColor(Color("main-highlight-color"))
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "선택", in: heroEffect)
                }
            }
        }
    }
    
    @ViewBuilder
    func goodsInformationPage(goods: Goods) -> some View {
        LazyVStack(pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(goods.goodsInfos, id: \.infoURL) { info in
                    AsyncImage(url: URL(string: info.infoURL.replacingOccurrences(of: "/images/info/", with: ""))) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ZStack {
                            Color("main-shape-bkg-color")
                            
                            ProgressView()
                                .tint(Color("main-highlight-color"))
                        }
                    }
                }
            } header: {
                goodsInformationView()
            }
        }
        .background(.white)
    }
    
    @ViewBuilder
    func sellerInformationPage(goods: Goods) -> some View {
        LazyVStack(pinnedViews: [.sectionHeaders]) {
            Section {
                orderCompleteInfo(title: "업체명", content: goods.seller.name)
                
                if let phoneNumber = goods.seller.phoneNumber, phoneNumber != "미공개" {
                    orderCompleteInfo(title: "전화번호", content: phoneNumber)
                }
                
                if let sns = goods.seller.sns {
                    orderCompleteInfo(title: "소셜계정", content: sns)
                }
            } header: {
                goodsInformationView()
            }
        }
        .background(.white)
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
    
    @ViewBuilder
    func purchaseBar() -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0),
                                    .black.opacity(0.1),
                                    .black.opacity(0.2),
                                    .black.opacity(0.3)
            ], startPoint: .top, endPoint: .bottom)
            .frame(height: 5)
            .opacity(0.3)
            .background(.clear)
            
            HStack(spacing: 20) {
                ZStack {
                    if !showOptionSheet {
                        Button {
                            if loginViewModel.isAuthenticate {
                                withAnimation(.easeInOut) {
                                    if let goods = goodsViewModel.goodsDetail {
                                        goods.scraped ? goodsViewModel.deleteIsScrap(id: goods.id, token: loginViewModel.returnToken()) : goodsViewModel.sendIsScrap(id: goods.id, token: loginViewModel.returnToken())
                                    }
                                }
                            } else {
                                appViewModel.createMessageBox(title: "로그인이 필요한 서비스 입니다", secondaryTitle: "로그인 하시겠습니까?", mainButtonTitle: "로그인 하러 가기", secondaryButtonTitle: "계속 둘러보기") {
                                    withAnimation(.spring()) {
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    loginViewModel.showLoginView = true
                                } secondaryButtonAction: {
                                    withAnimation(.spring()) {
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                } closeButtonAction: {
                                    appViewModel.deleteMessageBox()
                                }
                                
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = true
                                    appViewModel.showMessageBox = true
                                }
                            }
                        } label: {
                            VStack(spacing: 0) {
                                if goodsViewModel.goodsDetail?.scraped ?? false {
                                    Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .foregroundColor(Color("main-highlight-color"))
                                } else {
                                    Image(systemName: "heart")
                                        .font(.title2)
                                }
                                
                                Text("\(goodsViewModel.goodsDetail?.scrapCount ?? 0)")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(Color("main-text-color"))
                    }
                    
                    Button {
                        if !loginViewModel.isAuthenticate {
                            appViewModel.createMessageBox(title: "로그인이 필요한 서비스 입니다", secondaryTitle: "로그인 하시겠습니까?", mainButtonTitle: "로그인 하러 가기", secondaryButtonTitle: "계속 둘러보기") {
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = false
                                    appViewModel.showMessageBox = false
                                }
                                
                                loginViewModel.showLoginView = true
                            } secondaryButtonAction: {
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = false
                                    appViewModel.showMessageBox = false
                                }
                            } closeButtonAction: {
                                appViewModel.deleteMessageBox()
                            }
                            
                            withAnimation(.spring()) {
                                appViewModel.showMessageBoxBackground = true
                                appViewModel.showMessageBox = true
                                
                            }
                        } else if goodsViewModel.isSendGoodsPossible {
                            if goodsViewModel.goodsDetail?.seller.method == .both {
                                appViewModel.createMessageBox(title: "담을 방법을 선택해 주세요", secondaryTitle: "주문 후 24시간 이내에 입금하지 않을시 주문이 취소될 수 있습니다.", mainButtonTitle: "현장 수령하기", secondaryButtonTitle: "택배 수령하기") {
                                    withAnimation(.spring()) {
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    withAnimation(.easeInOut) {
                                        goodsViewModel.seletedGoods.cartMethod = .pickUpOrder
                                        goodsViewModel.sendCartGoodsRequest(token: loginViewModel.returnToken())
                                        goodsViewModel.seletedGoods.quantity = 0
                                        goodsViewModel.seletedGoods.color = nil
                                        goodsViewModel.seletedGoods.size = nil
                                    }
                                    
                                    appViewModel.deleteMessageBox()
                                } secondaryButtonAction: {
                                    withAnimation(.spring()) {
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    withAnimation(.easeInOut) {
                                        goodsViewModel.seletedGoods.cartMethod = .deliveryOrder
                                        goodsViewModel.sendCartGoodsRequest(token: loginViewModel.returnToken())
                                        goodsViewModel.seletedGoods.quantity = 0
                                        goodsViewModel.seletedGoods.color = nil
                                        goodsViewModel.seletedGoods.size = nil
                                    }
                                    
                                    appViewModel.deleteMessageBox()
                                } closeButtonAction: {
                                    appViewModel.deleteMessageBox()
                                }
                                
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = true
                                    appViewModel.showMessageBox = true
                                }
                            } else {
                                appViewModel.createMessageBox(title: "본 상품은 \(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배") 수령만 가능합니다.", secondaryTitle: "\(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배")만 가능하니 다시 한번 확인하고 주문해주세요.", mainButtonTitle: "\(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배") 수령하기", secondaryButtonTitle: "둘러보기") {
                                    withAnimation(.spring()) {
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    withAnimation(.easeInOut) {
                                        goodsViewModel.seletedGoods.cartMethod = goodsViewModel.goodsDetail?.seller.method == .pickUp ? .pickUpOrder : .deliveryOrder
                                        goodsViewModel.sendCartGoodsRequest(token: loginViewModel.returnToken())
                                        goodsViewModel.seletedGoods.quantity = 0
                                        goodsViewModel.seletedGoods.color = nil
                                        goodsViewModel.seletedGoods.size = nil
                                    }
                                    
                                    appViewModel.deleteMessageBox()
                                } secondaryButtonAction: {
                                    appViewModel.deleteMessageBox()
                                } closeButtonAction: {
                                    appViewModel.deleteMessageBox()
                                }
                                
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = true
                                    appViewModel.showMessageBox = true
                                }
                            }
                        } else {
                            goodsViewModel.hapticFeedback.notificationOccurred(.error)
                            withAnimation(.spring()) {
                                vibrateOffset += 1
                            }
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
                    Button {
                        if !loginViewModel.isAuthenticate {
                            appViewModel.createMessageBox(title: "로그인이 필요한 서비스 입니다", secondaryTitle: "로그인 하시겠습니까?", mainButtonTitle: "로그인 하러 가기", secondaryButtonTitle: "계속 둘러보기") {
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = false
                                    appViewModel.showMessageBox = false
                                }
                                
                                loginViewModel.showLoginView = true
                            } secondaryButtonAction: {
                                withAnimation(.spring()) {
                                    appViewModel.showMessageBoxBackground = false
                                    appViewModel.showMessageBox = false
                                }
                            } closeButtonAction: {
                                appViewModel.deleteMessageBox()
                            }
                            
                            withAnimation(.spring()) {
                                appViewModel.showMessageBoxBackground = true
                                appViewModel.showMessageBox = true
                                
                            }
                        } else if goodsViewModel.isSendGoodsPossible {
                            if goodsViewModel.goodsDetail?.seller.method == .both {
                                appViewModel.createMessageBox(title: "주문 방법을 선택해 주세요", secondaryTitle: "주문 후 24시간 이내에 입금하지 않을시 주문이 취소될 수 있습니다. ", mainButtonTitle: "현장 수령하기", secondaryButtonTitle: "택배 수령하기") {
                                    withAnimation(.spring()) {
                                        showOptionSheet = false
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    goodsViewModel.orderType = .pickUpOrder
                                    goodsViewModel.showOrderView = true
                                } secondaryButtonAction: {
                                    withAnimation(.spring()) {
                                        showOptionSheet = false
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                    }
                                    
                                    goodsViewModel.orderType = .deliveryOrder
                                    goodsViewModel.showOrderView = true
                                } closeButtonAction: {
                                    appViewModel.deleteMessageBox()
                                }
                            } else {
                                appViewModel.createMessageBox(title: "본 상품은 \(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배") 수령만 가능합니다.", secondaryTitle: "\(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배")만 가능하니 다시 한번 확인하고 주문해주세요.", mainButtonTitle: "\(goodsViewModel.goodsDetail?.seller.method == .pickUp ? "현장" : "택배") 수령하기", secondaryButtonTitle: "둘러보기") {
                                    withAnimation(.spring()) {
                                        showOptionSheet = false
                                        appViewModel.showMessageBoxBackground = false
                                        appViewModel.showMessageBox = false
                                        
                                        goodsViewModel.orderType = goodsViewModel.goodsDetail?.seller.method == .pickUp ? .pickUpOrder : .deliveryOrder
                                        goodsViewModel.showOrderView = true
                                    }
                                } secondaryButtonAction: {
                                    appViewModel.deleteMessageBox()
                                } closeButtonAction: {
                                    appViewModel.deleteMessageBox()
                                }
                            }
                            
                            withAnimation(.spring()) {
                                appViewModel.showMessageBoxBackground = true
                                appViewModel.showMessageBox = true
                            }
                        } else {
                            goodsViewModel.hapticFeedback.notificationOccurred(.error)
                            withAnimation(.spring()) {
                                vibrateOffset += 1
                            }
                        }
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
                        withAnimation(.spring()) {
                            showOptionSheet = true
                        }
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
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 25)
            .frame(height: 70)
            .background(.white)
        }
        .background(.clear)
    }
}

struct GoodsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GoodsDetailView()
            .environmentObject(GoodsViewModel())
            .environmentObject(LoginViewModel())
            .environmentObject(AppViewModel())
    }
}
