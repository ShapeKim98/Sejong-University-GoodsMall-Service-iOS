//
//  GoodsViewModel.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/01/29.
//

import Foundation
import SwiftUI
import Combine

class GoodsViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    
    let hapticFeedback = UINotificationFeedbackGenerator()
    
    @Published var error: APIError?
    @Published var errorView: ErrorView?
    @Published var goodsList: GoodsList = GoodsList()
    @Published var goodsDetail: Goods?
    @Published var isGoodsListLoading: Bool = true
    @Published var isGoodsDetailLoading: Bool = true
    @Published var isCategoryLoading: Bool = true
    @Published var isCartGoodsListLoading: Bool = true
    @Published var isSendOrderGoodsLoading: Bool = false
    @Published var message: String?
    @Published var pickUpCart: CartGoodsList = CartGoodsList()
    @Published var deliveryCart: CartGoodsList = CartGoodsList()
    @Published var seletedGoods: CartGoodsRequest = CartGoodsRequest(quantity: 0, cartMethod: .pickUpOrder)
    @Published var categoryList: CategoryList = [Category]()
    @Published var cartGoodsSelections: [Int: Bool] = [Int: Bool]()
    @Published var selectedCartGoodsCount: Int = 0
    @Published var selectedCartGoodsPrice: Int = 0
    @Published var isSendGoodsPossible: Bool = false
    @Published var completeSendCartGoods: Bool = false
    @Published var cartGoodsCount: Int = 0
    @Published var orderType: OrderType = .pickUpOrder
    @Published var orderGoodsListFromCart: CartGoodsList = CartGoodsList()
    @Published var orderGoodsDeliveryFeeFromCart: [Int: Int] = [Int: Int]()
    @Published var orderGoods: [OrderItem] = [OrderItem]()
    @Published var cartIDList: [Int] = [Int]()
    @Published var orderCompleteGoodsList = OrderGoodsRespnoseList()
    @Published var pickUpOrderCount: Int = 0
    @Published var deliveryOrderCount: Int = 0
    @Published var orderCompleteGoods: OrderGoodsRespnose?
    @Published var isOrderGoodsListLoading: Bool = true
    @Published var isOrderComplete: Bool = false
    @Published var showOrderView: Bool = false
    @Published var orderGoodsInfoList: [Int: Goods] = [Int: Goods]()
    @Published var scrapGoodsList: ScrapGoodsList = ScrapGoodsList()
    @Published var isScrapListLoading: Bool = true
    @Published var searchList: GoodsList = GoodsList()
    @Published var isSearchLoading: Bool = false
    
    func fetchGoodsList(token: String? = nil) {
        APIService.fetchGoodsList(token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchGoodsList(token: token)
            }
        } receiveValue: { goodsList in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.goodsList = goodsList
                    self.cartGoodsCount = goodsList.first?.cartItemCount ?? 0
                    self.isGoodsListLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchCategory() {
        APIService.fetchCategory().subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchCategory()
            }
        } receiveValue: { categoryList in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.categoryList = categoryList
                    self.categoryList.insert(Category(id: 0, name: "ALLPRODUCT"), at: 0)
                    self.isCategoryLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchGoodsListFromCatefory(id: Int) {
        APIService.fetchGoodsListFromCategory(id: id).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchGoodsListFromCatefory(id: id)
            }
        } receiveValue: { goodsList in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.goodsList = goodsList
                    self.isGoodsListLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchGoodsDetail(id: Int, token: String? = nil) {
        APIService.fetchGoodsDetail(id: id, token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchGoodsDetail(id: id)
            }
        } receiveValue: { goodsDetail in
            DispatchQueue.main.async {
                self.goodsDetail = goodsDetail
                
                withAnimation(.easeInOut) {
                    self.isGoodsDetailLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchorderGoodsDeliveryFeeFromCart(id: Int) {
        APIService.fetchGoodsDetail(id: id).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchGoodsDetail(id: id)
            }
        } receiveValue: { goodsDetail in
            DispatchQueue.main.async {
                self.orderGoodsDeliveryFeeFromCart.updateValue(goodsDetail.deliveryFee, forKey: id)
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchOrderGoodsInfo(publishers: [AnyPublisher<Goods, APIError>]) {
        Publishers.MergeMany(publishers).eraseToAnyPublisher().subscribe(on: DispatchQueue.global(qos: .background)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchOrderGoodsInfo(publishers: publishers)
            }
        } receiveValue: { goodsInfo in
            withAnimation(.easeInOut) {
                DispatchQueue.main.async {
                    self.orderGoodsInfoList.updateValue(goodsInfo, forKey: goodsInfo.id)
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func sendCartGoodsRequest(token: String) {
        guard isSendGoodsPossible, let goodID = goodsDetail?.id else {
            return
        }
        
        APIService.sendCartGoods(goods: seletedGoods, goodsID: goodID, token: token).subscribe(on: DispatchQueue.global(qos: .background)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.sendCartGoodsRequest(token: token)
            }
        } receiveValue: { data in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.completeSendCartGoods = true
                }
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchCartGoods(token: String) {
        APIService.fetchCartGoods(token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchCartGoods(token: token)
            }
        } receiveValue: { cartGoodsList in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.pickUpCart = cartGoodsList.filter({ goods in
                        return goods.cartMethod == .pickUpOrder
                    })
                    
                    self.deliveryCart = cartGoodsList.filter({ goods in
                        return goods.cartMethod == .deliveryOrder
                    })
                    
                    self.updateCartData()
                    self.isCartGoodsListLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func deleteCartGoods(token: String) {
        withAnimation(.easeInOut) {
            self.isCartGoodsListLoading = true
        }
        var publishers = [AnyPublisher<CartGoodsList, APIError>]()
        switch orderType {
            case .pickUpOrder:
                self.pickUpCart.forEach { goods in
                    if let isSelected = cartGoodsSelections[goods.id], isSelected {
                        publishers.append(APIService.deleteCartGoods(id: goods.id, token: token))
                        cartGoodsSelections.removeValue(forKey: goods.id)
                    }
                }
                break
            case .deliveryOrder:
                self.deliveryCart.forEach { goods in
                    if let isSelected = cartGoodsSelections[goods.id], isSelected {
                        publishers.append(APIService.deleteCartGoods(id: goods.id, token: token))
                        cartGoodsSelections.removeValue(forKey: goods.id)
                    }
                }
                break
        }
        
        Publishers.MergeMany(publishers).eraseToAnyPublisher().subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).last().sink { completion in
            self.completionHandler(completion: completion) {
                self.deleteCartGoods(token: token)
            }
        } receiveValue: { goodsList in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.completeSendCartGoods = true
                }
                
                withAnimation(.spring()) {
                    self.fetchCartGoods(token: token)
                    DispatchQueue.main.async {
                        switch self.orderType {
                            case .pickUpOrder:
                                self.pickUpCart = goodsList
                            case .deliveryOrder:
                                self.deliveryCart = goodsList
                        }
                        
                        self.isCartGoodsListLoading = false
                    }
                }
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func deleteIndividualCartGoods(id: Int, token: String) {
        APIService.deleteCartGoods(id: id, token: token).subscribe(on: DispatchQueue.global(qos: .userInteractive)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.deleteIndividualCartGoods(id: id, token: token)
            }
        } receiveValue: { data in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.fetchCartGoods(token: token)
                    self.updateCartData()
                    self.isCartGoodsListLoading = false
                    
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func updateCartGoods(id: Int, quantity: Int, token: String) {
        APIService.updateCartGoods(id: id, quantity: quantity, token: token).subscribe(on: DispatchQueue.global(qos: .userInteractive)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.updateCartGoods(id: id, quantity: quantity, token: token)
            }
        } receiveValue: { data in
            DispatchQueue.main.async {
                self.fetchCartGoods(token: token)
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func sendOrderGoodsFromDetailGoods(buyerName: String, phoneNumber: String, address: Address?, deliveryRequest: String?, token: String) {
        guard let goodsID = goodsDetail?.id else {
            return
        }
        
        APIService.sendOrderGoodsFromDetailGoods(id: goodsID, buyerName: buyerName, phoneNumber: phoneNumber, address: address, orderMethod: self.orderType.rawValue, deliveryRequest: deliveryRequest, orderItems: self.orderGoods, token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).sink { completion in
            self.completionHandler(completion: completion) {
                self.sendOrderGoodsFromDetailGoods(buyerName: buyerName, phoneNumber: phoneNumber, address: address, deliveryRequest: deliveryRequest, token: token)
            }
        } receiveValue: { orderGoods in
            DispatchQueue.main.async {
                self.orderGoods.removeAll()
                self.orderGoodsListFromCart.removeAll()
                self.cartIDList.removeAll()
                self.orderCompleteGoods = orderGoods
                var publishers: [Int: AnyPublisher<Goods, APIError>] = [Int: AnyPublisher<Goods, APIError>]()
                
                orderGoods.orderItems.forEach { goods in
                    if let id = goods.itemID, !publishers.contains(where: { key, value in
                        return id == key
                    }) {
                        publishers.updateValue(APIService.fetchGoodsDetail(id: id), forKey: id)
                    }
                }
                
                self.fetchOrderGoodsInfo(publishers: publishers.values.shuffled())
                self.isSendOrderGoodsLoading = false
                self.isOrderComplete = true
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func sendOrderGoodsFromCart(buyerName: String, phoneNumber: String, address: Address?, deliveryRequest: String?, token: String) {
        APIService.sendOrderGoodsFromCart(cartIDList: self.cartIDList, buyerName: buyerName, phoneNumber: phoneNumber, address: address, orderMethod: self.orderType.rawValue, deliveryRequset: deliveryRequest, orderItems: self.orderGoods, token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).sink { completion in
            self.completionHandler(completion: completion) {
                self.sendOrderGoodsFromCart(buyerName: buyerName, phoneNumber: phoneNumber, address: address, deliveryRequest: deliveryRequest, token: token)
            }
        } receiveValue: { orderGoods in
            DispatchQueue.main.async {
                self.orderGoods.removeAll()
                self.orderGoodsListFromCart.removeAll()
                self.cartIDList.removeAll()
                self.orderCompleteGoods = orderGoods
                
                var publishers: [Int: AnyPublisher<Goods, APIError>] = [Int: AnyPublisher<Goods, APIError>]()
                
                orderGoods.orderItems.forEach { goods in
                    if let id = goods.itemID, !publishers.contains(where: { key, value in
                        return id == key
                    }) {
                        publishers.updateValue(APIService.fetchGoodsDetail(id: id), forKey: id)
                    }
                }
                
                self.fetchOrderGoodsInfo(publishers: publishers.values.shuffled())
                
                self.isSendOrderGoodsLoading = false
                self.isOrderComplete = true
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchOrderGoodsList(token: String) {
        APIService.fetchOrderGoodsList(token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchOrderGoodsList(token: token)
            }
        } receiveValue: { orderGoodsList in
            DispatchQueue.main.async {
                self.orderCompleteGoodsList = orderGoodsList.sorted(by: { lhs, rhs in
                    return lhs.createdAt > rhs.createdAt
                })
                
                self.pickUpOrderCount = 0
                self.deliveryOrderCount = 0
                
                var publishers: [Int: AnyPublisher<Goods, APIError>] = [Int: AnyPublisher<Goods, APIError>]()
                
                self.orderCompleteGoodsList.forEach { orderGoods in
                    if orderGoods.orderMethod == .pickUpOrder {
                        self.pickUpOrderCount += orderGoods.orderItems.count
                    } else {
                        self.deliveryOrderCount += orderGoods.orderItems.count
                    }
                    
                    orderGoods.orderItems.forEach { goods in
                        if let id = goods.itemID, !publishers.contains(where: { key, value in
                            return id == key
                        }) {
                            publishers.updateValue(APIService.fetchGoodsDetail(id: id), forKey: id)
                        }
                    }
                }
                
                self.fetchOrderGoodsInfo(publishers: publishers.values.shuffled())
                
                withAnimation(.easeInOut) {
                    self.isOrderGoodsListLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func sendIsScrap(id: Int, token: String) {
        APIService.sendIsScrap(id: id, token: token).subscribe(on: DispatchQueue.global(qos: .userInteractive)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.sendIsScrap(id: id, token: token)
            }
        } receiveValue: { scrap in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.goodsDetail?.scraped = true
                    self.goodsDetail?.scrapCount = scrap.scrapCount
                }
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func sendIsScrapFromCart(id: Int, token: String) {
        APIService.sendIsScrap(id: id, token: token).subscribe(on: DispatchQueue.global(qos: .background)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.sendIsScrapFromCart(id: id, token: token)
            }
        } receiveValue: { message        in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.completeSendCartGoods = true
                }
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func deleteIsScrap(id: Int, token: String) {
        APIService.deleteIsScrap(id: id, token: token).subscribe(on: DispatchQueue.global(qos: .userInteractive)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.deleteIsScrap(id: id, token: token)
            }
        } receiveValue: { scrap in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.goodsDetail?.scraped = false
                    self.goodsDetail?.scrapCount = scrap.scrapCount
                }
                
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .store(in: &subscriptions)
    }
    
    func fetchScrapList(token: String) {
        APIService.fetchScrapList(token: token).subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchCartGoods(token: token)
            }
        } receiveValue: { scrapList in
            DispatchQueue.main.async {
                self.scrapGoodsList = scrapList
                self.isScrapListLoading = false
            }
        }
        .store(in: &subscriptions)
    }
    
    func completionHandler(completion: Subscribers.Completion<APIError>, retryAction: @escaping () -> Void) {
        switch completion {
            case .failure(let error):
                switch error {
                    case .authenticationFailure, .alreadyCartGoods, .isNoneCartGoods:
                        DispatchQueue.main.async {
                            self.error = APIError.convert(error: error)
                            self.errorView = ErrorView(retryAction: {}, closeAction: {
                                self.error = nil
                                self.errorView = nil
                            })
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    case .invalidResponse(statusCode: let statusCode):
                        DispatchQueue.main.async {
                            self.error = .invalidResponse(statusCode: statusCode)
                            self.errorView = ErrorView(retryAction: {
                                self.error = nil
                                self.errorView = nil
                                retryAction()
                            }, closeAction: {
                                self.error = nil
                                self.errorView = nil
                            })
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    case .cannotNetworkConnect:
                        DispatchQueue.main.async {
                            self.error = .cannotNetworkConnect
                            self.errorView = ErrorView(retryAction: {
                                self.error = nil
                                self.errorView = nil
                                retryAction()
                            }, closeAction: {
                                self.error = nil
                                self.errorView = nil
                            })
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    case .urlError(let error):
                        DispatchQueue.main.async {
                            self.error = .urlError(error)
                            self.errorView = ErrorView(retryAction: {
                                self.error = nil
                                self.errorView = nil
                                retryAction()
                            }, closeAction: {
                                self.error = nil
                                self.errorView = nil
                            })
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    case .jsonDecodeError:
                        DispatchQueue.main.async {
                            self.message = "데이터 디코딩 에러"
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    case .jsonEncodeError:
                        DispatchQueue.main.async {
                            self.message = "데이터 인코딩 에러"
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                    default:
                        DispatchQueue.main.async {
                            self.error = .unknown(error)
                            self.errorView = ErrorView(retryAction: {
                                self.error = nil
                                self.errorView = nil
                                retryAction()
                            }, closeAction: {
                                self.error = nil
                                self.errorView = nil
                            })
                            self.hapticFeedback.notificationOccurred(.error)
                        }
                }
                break
            case .finished:
                break
        }
    }
    
    func updateCartData() {
        self.selectedCartGoodsCount = 0
        self.selectedCartGoodsPrice = 0
        self.cartGoodsSelections.values.forEach { isSelected in
            self.selectedCartGoodsCount += isSelected ? 1 : 0
        }
        
        switch orderType {
            case .pickUpOrder:
                self.pickUpCart.forEach { goods in
                    selectedCartGoodsPrice += (cartGoodsSelections[goods.id] ?? false) ? goods.price : 0
                }
                break
            case .deliveryOrder:
                self.deliveryCart.forEach { goods in
                    selectedCartGoodsPrice += (cartGoodsSelections[goods.id] ?? false) ? goods.price : 0
                }
                break
        }
    }
    
    func searchGoods(searchText: String) {
        APIService.fetchGoodsList().subscribe(on: DispatchQueue.global(qos: .userInitiated)).retry(1).sink { completion in
            self.completionHandler(completion: completion) {
                self.fetchGoodsList()
            }
        } receiveValue: { goodsList in
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.searchList = goodsList.filter({ goods in
                        let isDiscription = goods.description?.contains(searchText) ?? false
                        return goods.title.contains(searchText) || goods.seller.name.contains(searchText) || goods.seller.method.rawValue.contains(searchText) || isDiscription
                    })
                    
                    self.isSearchLoading = false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func reset() {
        error = nil
        errorView = nil
        goodsList = GoodsList()
        goodsDetail = nil
        isGoodsListLoading = true
        isGoodsDetailLoading = true
        isCategoryLoading = true
        isCartGoodsListLoading = true
        isSendOrderGoodsLoading = false
        message = nil
        pickUpCart = CartGoodsList()
        deliveryCart = CartGoodsList()
        seletedGoods = CartGoodsRequest(quantity: 0, cartMethod: .pickUpOrder)
        categoryList = [Category]()
        cartGoodsSelections = [Int: Bool]()
        selectedCartGoodsCount = 0
        selectedCartGoodsPrice = 0
        isSendGoodsPossible = false
        completeSendCartGoods = false
        cartGoodsCount = 0
        orderType = .deliveryOrder
        orderGoodsListFromCart = CartGoodsList()
        orderGoods = [OrderItem]()
        cartIDList = [Int]()
        orderCompleteGoodsList = OrderGoodsRespnoseList()
        pickUpOrderCount = 0
        deliveryOrderCount = 0
        orderCompleteGoods = nil
        isOrderGoodsListLoading = true
        isOrderComplete = false
        showOrderView = false
        orderGoodsInfoList = [Int: Goods]()
        scrapGoodsList = ScrapGoodsList()
        isScrapListLoading = true
        searchList = GoodsList()
        isSearchLoading = false
    }
}
