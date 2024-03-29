//
//  PickUpOrderView.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/02/19.
//

import SwiftUI

struct OrderView: View {
    @StateObject var kakaoPostCodeViewModel: KakaoPostCodeViewModel = KakaoPostCodeViewModel()
    
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var goodsViewModel: GoodsViewModel
    
    @FocusState private var currentField: FocusedTextField?
    
    @State private var buyerName: String = ""
    @State private var isValidBuyerName: Bool = false
    @State private var phoneNumber: String = ""
    @State private var isValidPhoneNumber: Bool = false
    @State private var orderPrice: Int = 0
    @State private var postalNumber: String = ""
    @State private var isValidPostalNumber: Bool = false
    @State private var mainAddress: String = ""
    @State private var isValidMainAddress: Bool = false
    @State private var detailAddress: String = ""
    @State private var deliveryRequirements: String = ""
    @State private var showFindAddressView: Bool = false
    @State private var showDeliveryInfo: Bool = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 350, maximum: .infinity), spacing: nil, alignment: .top)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if goodsViewModel.isOrderComplete {
                OrderCompleteView()
            } else {
                Rectangle()
                    .fill(Color("shape-bkg-color"))
                    .frame(height: 10)
                
                ScrollView {
                    switch goodsViewModel.orderType {
                        case .pickUpOrder:
                            pickUpInformation()
                        case .deliveryOrder:
                            deliveryInformation()
                    }
                    
                    orderGoodsList()
                    
                    deliveryInfoAlert()
                    
                    orderButton()
                        .padding(.top, 30)
                        .onAppear() {
                            orderPrice = 0
                            if goodsViewModel.cartIDList.isEmpty {
                                goodsViewModel.orderGoods.forEach { goods in
                                    orderPrice += (goods.price * goods.quantity)
                                }
                                
                                if goodsViewModel.orderType == .deliveryOrder {
                                    orderPrice += goodsViewModel.goodsDetail?.deliveryFee ?? 0
                                }
                            }
                        }
                        .onChange(of: goodsViewModel.orderGoodsDeliveryFeeFromCart) { newValue in
                            if !goodsViewModel.cartIDList.isEmpty {
                                orderPrice = 0
                                
                                goodsViewModel.orderGoods.forEach { goods in
                                    orderPrice += (goods.price)
                                }
                                
                                goodsViewModel.orderGoodsDeliveryFeeFromCart.forEach { key, value in
                                    orderPrice += value
                                }
                            }
                        }
                }
            }
        }
        .navigationTitle(goodsViewModel.isOrderComplete ? "주문 완료" : "주문서 작성")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(NavigationColorModifier())
        .background(.white)
        .onChange(of: kakaoPostCodeViewModel.address) { newValue in
            if let address = newValue, let zipcode = kakaoPostCodeViewModel.zipcode {
                mainAddress = address
                postalNumber = zipcode
                
                showFindAddressView = false
            }
        }
        .onTapGesture {
            currentField = nil
        }
        .fullScreenCover(isPresented: $showFindAddressView) {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    FindAdressView(request: URLRequest(url: URL(string: "https://shapekim98.github.io/Sejong-University-GoodsMall-KaKao-PostCode-Service/")!))
                    .environmentObject(kakaoPostCodeViewModel)
                    .navigationTitle("우편번호 찾기")
                    .navigationBarTitleDisplayMode(.inline)
                    .modifier(NavigationColorModifier())
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showFindAddressView = false
                            } label: {
                                Label("닫기", systemImage: "xmark")
                                    .labelStyle(.iconOnly)
                                    .font(.footnote)
                                    .foregroundColor(Color("main-text-color"))
                            }
                        }
                    }
                }
                .overlay {
                    if let errorView = goodsViewModel.errorView {
                        errorView
                            .transition(.opacity.animation(.easeInOut))
                    }
                }
            } else {
                NavigationView {
                    FindAdressView(request: URLRequest(url: URL(string: "https://shapekim98.github.io/Sejong-University-GoodsMall-KaKao-PostCode-Service/")!))
                        .environmentObject(kakaoPostCodeViewModel)
                        .navigationTitle("우편번호 찾기")
                        .navigationBarTitleDisplayMode(.inline)
                        .modifier(NavigationColorModifier())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showFindAddressView = false
                                } label: {
                                    Label("닫기", systemImage: "xmark")
                                        .labelStyle(.iconOnly)
                                        .font(.footnote)
                                        .foregroundColor(Color("main-text-color"))
                                }
                            }
                        }
                }
                .overlay {
                    if let errorView = goodsViewModel.errorView {
                        errorView
                            .transition(.opacity.animation(.easeInOut))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func pickUpInformation() -> some View {
        VStack {
            HStack {
                Text("수령 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            TextField("수령인", text: $buyerName, prompt: Text("수령인"))
                .modifier(TextFieldModifier(text: $buyerName, isValidInput: $isValidBuyerName, currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .name, focusedTextField: .nameField, submitLabel: .next))
                .onChange(of: buyerName) { newValue in
                    withAnimation(.easeInOut) {
                        isValidBuyerName = newValue != "" ? true : false
                    }
                }
                .overlay {
                    if isValidBuyerName {
                        HStack {
                            Spacer()
                            
                            DrawingCheckmarkView()
                        }
                        .padding()
                    }
                }
            
            HStack {
                Text(!isValidBuyerName && buyerName != "" ? "필수 항목입니다." : " ")
                    .font(.caption2)
                    .foregroundColor(Color("main-highlight-color"))
                
                Spacer()
            }
            .padding(.horizontal)
            
            TextField("휴대전화", text: $phoneNumber, prompt: Text("휴대전화('-'포함해서 입력)"))
                .modifier(TextFieldModifier(text: $phoneNumber, isValidInput: $isValidPhoneNumber, currentField: _currentField, font: .subheadline.bold(), keyboardType: .numbersAndPunctuation, contentType: .telephoneNumber, focusedTextField: .phoneNumberField, submitLabel: .done))
                .onChange(of: phoneNumber) { newValue in
                    if(newValue.range(of:"^01([0|1|6|7|8|9]?)-([0-9]{3,4})-([0-9]{4})$", options: .regularExpression) != nil) {
                        withAnimation(.easeInOut){
                            isValidPhoneNumber = true
                        }
                    } else {
                        withAnimation(.easeInOut) {
                            isValidPhoneNumber = false
                        }
                    }
                }
                .overlay {
                    if isValidPhoneNumber {
                        HStack {
                            Spacer()
                            
                            DrawingCheckmarkView()
                        }
                        .padding()
                    }
                }
            
            HStack {
                Text(!isValidPhoneNumber && phoneNumber != "" ? "올바르지 않은 휴대전화번호 입니다" : " ")
                    .font(.caption2)
                    .foregroundColor(Color("main-highlight-color"))
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    func deliveryInformation() -> some View {
        VStack {
            HStack {
                Text("배송 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Group {
                TextField("수령인", text: $buyerName, prompt: Text("수령인"))
                    .modifier(TextFieldModifier(text: $buyerName, isValidInput: $isValidBuyerName, currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .name, focusedTextField: .nameField, submitLabel: .next))
                    .onChange(of: buyerName) { newValue in
                        withAnimation(.easeInOut) {
                            isValidBuyerName = newValue != "" ? true : false
                        }
                    }
                    .overlay {
                        if isValidBuyerName {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    Text(!isValidBuyerName && buyerName != "" ? "필수 항목입니다." : " ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Group {
                TextField("휴대전화", text: $phoneNumber, prompt: Text("휴대전화('-'포함해서 입력)"))
                    .modifier(TextFieldModifier(text: $phoneNumber, isValidInput: $isValidPhoneNumber, currentField: _currentField, font: .subheadline.bold(), keyboardType: .numbersAndPunctuation, contentType: .telephoneNumber, focusedTextField: .phoneNumberField, submitLabel: .done))
                    .onChange(of: phoneNumber) { newValue in
                        if(newValue.range(of:"^01([0|1|6|7|8|9]?)-([0-9]{3,4})-([0-9]{4})$", options: .regularExpression) != nil) {
                            withAnimation(.easeInOut) {
                                isValidPhoneNumber = true
                            }
                        } else {
                            withAnimation(.easeInOut) {
                                isValidPhoneNumber = false
                            }
                        }
                    }
                    .overlay {
                        if isValidPhoneNumber {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    Text(!isValidPhoneNumber && phoneNumber != "" ? "올바르지 않은 휴대전화번호 입니다" : " ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Group {
                TextField("우편번호", text: $postalNumber, prompt: Text("우편번호"))
                    .modifier(TextFieldModifier(text: $postalNumber, isValidInput: $isValidPostalNumber, currentField: _currentField, font: .subheadline.bold(), keyboardType: .numberPad, contentType: .postalCode, focusedTextField: .postalNumberField, submitLabel: .next))
                    .onChange(of: postalNumber) { newValue in
                        if newValue.count == 5 {
                            withAnimation(.easeInOut) {
                                isValidPostalNumber = true
                            }
                        } else {
                            withAnimation(.easeInOut) {
                                isValidPostalNumber = false
                            }
                        }
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            
                            if isValidPostalNumber {
                                DrawingCheckmarkView()
                            }
                            
                            Button {
                                withAnimation(.easeInOut) {
                                    showFindAddressView.toggle()
                                }
                            } label: {
                                Text("주소찾기")
                                    .font(.caption2)
                                    .foregroundColor(Color("main-text-color"))
                                    .background(alignment: .bottom) {
                                        Rectangle()
                                            .fill(Color("main-text-color"))
                                            .frame(height: 0.5)
                                    }
                            }
                        }
                        .padding()
                    }
                
                HStack {
                    Text(!isValidPostalNumber && postalNumber != "" ? "필수 항목입니다." : " ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Group {
                TextField("주소", text: $mainAddress, prompt: Text("주소"))
                    .modifier(TextFieldModifier(text: $mainAddress, isValidInput: $isValidMainAddress, currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .streetAddressLine1, focusedTextField: .address1, submitLabel: .next))
                    .onChange(of: mainAddress) { newValue in
                        if newValue != "" {
                            withAnimation(.easeInOut) {
                                isValidMainAddress = true
                            }
                        } else {
                            withAnimation(.easeInOut) {
                                isValidMainAddress = false
                            }
                        }
                    }
                    .overlay {
                        if isValidMainAddress {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    Text(!isValidMainAddress && mainAddress != "" ? "필수 항목입니다." : " ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Group {
                TextField("상세주소", text: $detailAddress, prompt: Text("상세주소"))
                    .modifier(TextFieldModifier(text: $detailAddress, isValidInput: .constant(true), currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .streetAddressLine2, focusedTextField: .address2, submitLabel: .next))
                
                HStack {
                    Text(" ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Group {
                TextField("배송 요청사항", text: $deliveryRequirements, prompt: Text("배송 요청사항(선택)"))
                    .modifier(TextFieldModifier(text: $deliveryRequirements, isValidInput: .constant(true), currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .name, focusedTextField: .deliveryRequirements, submitLabel: .done))
                
                HStack {
                    Text(" ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func orderGoodsList() -> some View {
        VStack {
            HStack {
                Text("상품 정보")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns) {
                if !goodsViewModel.cartIDList.isEmpty {
                    ForEach(goodsViewModel.orderGoodsListFromCart) { goods in
                        subOrderGoodsFromCart(goods: goods)
                        
                    }
                } else {
                    ForEach(goodsViewModel.orderGoods, id: \.hashValue) { goods in
                        subOrderGoods(goods: goods)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func subOrderGoods(goods: OrderItem) -> some View {
        VStack {
            HStack() {
                if let image = goodsViewModel.goodsDetail?.goodsImages.first {
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
                        Text(goodsViewModel.goodsDetail?.title ?? "")
                            .foregroundColor(Color("main-text-color"))
                            .padding(.trailing)
                        
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    HStack {
                        if goods.color != nil || goods.size != nil {
                            Group {
                                if let color = goods.color, let size = goods.size {
                                    Text("\(color), \(size)")
                                } else {
                                    Text("\(goods.color ?? "")\(goods.size ?? "")")
                                }
                            }
                            .font(.caption.bold())
                            .foregroundColor(Color("main-text-color"))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    HStack {
                        Text(goodsViewModel.goodsDetail?.seller.name ?? "")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("point-color"))
                        
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    HStack {
                        if goodsViewModel.cartIDList.isEmpty {
                            Text("\(goods.price)원")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("main-text-color"))
                        } else {
                            Text("\(goods.price * goods.quantity)원")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("main-text-color"))
                        }
                        
                        Spacer()
                        
                        Text("수량 \(goods.quantity)개")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("secondary-text-color"))
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
    func subOrderGoodsFromCart(goods: CartGoodsResponse) -> some View {
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
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    HStack {
                        if goods.color != nil || goods.size != nil {
                            Group {
                                if let color = goods.color, let size = goods.size {
                                    Text("\(color), \(size)")
                                } else {
                                    Text("\(goods.color ?? "")\(goods.size ?? "")")
                                }
                            }
                            .font(.caption.bold())
                            .foregroundColor(Color("main-text-color"))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    HStack {
                        Text(goods.seller)
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
    func orderButton() -> some View {
        if goodsViewModel.orderType == .pickUpOrder {
            Button {
                goodsViewModel.hapticFeedback.notificationOccurred(.warning)
                
                appViewModel.createMessageBox(title: "주문 전 확인하세요!", secondaryTitle: "＊입력된 개인정보는 주문 이외의 목적으로 이용되지 않습니다.\n＊주문완료 이후 금액을 입금하지 않으면 주문 내용은 일정시간 이후 자동 삭제됩니다, 입금 이후 주문 취소는 판매자 정보의 연락처를 통해 연락바랍니다.\n＊1~2일 이내 입금 내역을 전달받아 배송 상태가 변경됩니다. ", mainButtonTitle: "주문하기", secondaryButtonTitle: "뒤로가기") {
                    withAnimation(.spring()) {
                        appViewModel.showMessageBoxBackground = false
                        appViewModel.showMessageBox = false
                    }
                    
                    goodsViewModel.isSendOrderGoodsLoading = true
                    
                    if goodsViewModel.cartIDList.isEmpty {
                        goodsViewModel.sendOrderGoodsFromDetailGoods(buyerName: buyerName, phoneNumber: phoneNumber, address: nil, deliveryRequest: nil, token: loginViewModel.returnToken())
                    } else {
                        goodsViewModel.sendOrderGoodsFromCart(buyerName: buyerName, phoneNumber: phoneNumber, address: nil, deliveryRequest: nil, token: loginViewModel.returnToken())
                    }
                } secondaryButtonAction: {
                    withAnimation(.spring()) {
                        appViewModel.showMessageBoxBackground = false
                        appViewModel.showMessageBox = false
                    }
                    
                    appViewModel.deleteMessageBox()
                } closeButtonAction: {
                    appViewModel.deleteMessageBox()
                }
                
                withAnimation(.spring()) {
                    appViewModel.showMessageBoxBackground = true
                    appViewModel.showMessageBox = true
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if goodsViewModel.isSendOrderGoodsLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .tint(Color("main-highlight-color"))
                    } else {
                        Text("\(orderPrice)원 주문하기")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor((isValidBuyerName && isValidPhoneNumber) || !goodsViewModel.isSendOrderGoodsLoading ? Color("main-highlight-color") : Color("main-shape-bkg-color"))
                }
            }
            .disabled(!isValidBuyerName || !isValidPhoneNumber || goodsViewModel.isSendOrderGoodsLoading)
            .padding([.horizontal, .bottom])
            .padding(.bottom, 20)
        } else {
            Button {
                goodsViewModel.hapticFeedback.notificationOccurred(.warning)
                
                appViewModel.createMessageBox(title: "주문 전 확인하세요!", secondaryTitle: "＊입력된 개인정보는 주문 이외의 목적으로 이용되지 않습니다.\n＊주문완료 이후 금액을 입금하지 않으면 주문 내용은 일정시간 이후 자동 삭제됩니다, 입금 이후 주문 취소는 판매자 정보의 연락처를 통해 연락바랍니다.\n＊1~2일 이내 입금 내역을 전달받아 배송 상태가 변경됩니다. ", mainButtonTitle: "주문하기", secondaryButtonTitle: "뒤로가기") {
                    withAnimation(.spring()) {
                        appViewModel.showMessageBoxBackground = false
                        appViewModel.showMessageBox = false
                    }
                    
                    goodsViewModel.isSendOrderGoodsLoading = true
                    
                    if goodsViewModel.cartIDList.isEmpty {
                        goodsViewModel.sendOrderGoodsFromDetailGoods(buyerName: buyerName, phoneNumber: phoneNumber, address: Address(mainAddress: mainAddress, zipcode: postalNumber, detailAddress: detailAddress), deliveryRequest: deliveryRequirements == "" ? nil : deliveryRequirements, token: loginViewModel.returnToken())
                    } else {
                        goodsViewModel.sendOrderGoodsFromCart(buyerName: buyerName, phoneNumber: phoneNumber, address: Address(mainAddress: mainAddress, zipcode: postalNumber, detailAddress: detailAddress), deliveryRequest: deliveryRequirements == "" ? nil : deliveryRequirements, token: loginViewModel.returnToken())
                    }
                } secondaryButtonAction: {
                    withAnimation(.spring()) {
                        appViewModel.showMessageBoxBackground = false
                        appViewModel.showMessageBox = false
                    }
                    
                    appViewModel.deleteMessageBox()
                } closeButtonAction: {
                    appViewModel.deleteMessageBox()
                }
                
                withAnimation(.spring()) {
                    appViewModel.showMessageBoxBackground = true
                    appViewModel.showMessageBox = true
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if goodsViewModel.isSendOrderGoodsLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .tint(Color("main-highlight-color"))
                    } else {
                        Text("\(orderPrice)원 주문하기")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(isValidBuyerName && isValidPhoneNumber && isValidPostalNumber && isValidMainAddress && !goodsViewModel.isSendOrderGoodsLoading ? Color("main-highlight-color") : Color("main-shape-bkg-color"))
                }
            }
            .disabled(!isValidBuyerName || !isValidPhoneNumber || !isValidPostalNumber || !isValidMainAddress)
            .padding([.horizontal, .bottom])
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    func deliveryInfoAlert() -> some View {
        VStack {
            HStack {
                if goodsViewModel.cartIDList.isEmpty {
                    if let fee = goodsViewModel.goodsDetail?.deliveryFee, fee != 0 {
                        Text("• 기본 배송료는 \(fee)원 입니다.")
                            .font(.caption)
                            .foregroundColor(Color("secondary-text-color"))
                        
                        Spacer()
                        
                        Button {
                            showDeliveryInfo = true
                        } label: {
                            Label("도움말", systemImage: "info.circle")
                                .font(.title3)
                                .labelStyle(.iconOnly)
                                .foregroundColor(Color("point-color"))
                        }
                        .alert("지역별 추가 배송비 안내", isPresented: $showDeliveryInfo) {
                            Button {
                                showDeliveryInfo = false
                            } label: {
                                Text("확인")
                            }
                            .foregroundColor(Color("main-highlight-color"))
                        } message: {
                            VStack {
                                Text("판매자에 따라 제주도 외 도서산간에선 추가 배송비가 붙을 수 있으며,\n판매자에게 별도의 연락이 올 수 있습니다.").font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    } else {
                        Text("• 본 상품은 무료배송인 상품입니다.")
                            .font(.caption)
                            .foregroundColor(Color("secondary-text-color"))
                        
                        Spacer()
                    }
                } else {
                    Text("• 상품에 따라 별도의 배송비가 추가됩니다.")
                        .font(.caption)
                        .foregroundColor(Color("secondary-text-color"))
                    
                    Spacer()
                    
                    Button {
                        showDeliveryInfo = true
                    } label: {
                        Label("도움말", systemImage: "info.circle")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .foregroundColor(Color("point-color"))
                    }
                    .alert("지역별 추가 배송비 안내", isPresented: $showDeliveryInfo) {
                        Button {
                            showDeliveryInfo = false
                        } label: {
                            Text("확인")
                        }
                        .foregroundColor(Color("main-highlight-color"))
                    } message: {
                        VStack {
                            Text("판매자에 따라 제주도 외 도서산간에선 추가 배송비가 붙을 수 있으며,\n판매자에게 별도의 연락이 올 수 있습니다.").font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            HStack {
                Text("• 총 주문금액은 배송비 포함 금액입니다.")
                    .font(.caption)
                    .foregroundColor(Color("secondary-text-color"))
                
                Spacer()
            }
        }
        .padding()
    }
}

struct OrderView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView()
        .environmentObject(LoginViewModel())
        .environmentObject(GoodsViewModel())
        .environmentObject(AppViewModel())
    }
}
