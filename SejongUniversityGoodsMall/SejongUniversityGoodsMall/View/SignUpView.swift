//
//  SignUpView.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/01/27.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    @Binding var showDatePicker: Bool
    @Binding var userBirth: String
    
    @State private var vibrateOffset: CGFloat = .zero
    
    init(showDatePicker: Binding<Bool>, userBirth: Binding<String>) {
        self._showDatePicker = showDatePicker
        self._userBirth = userBirth
    }
    
    var body: some View {
        ScrollView {
            registeredUserPage()
            
            termsPage()
            
            signUpButton()
        }
        .frame(maxWidth: 500)
        .onTapGesture {
            currentField = nil
        }
        .onDisappear() {
            userBirth = ""
        }
        .fullScreenCover(isPresented: $loginViewModel.isSignUpComplete) {
            signUpComplete {
                loginViewModel.isSignUpComplete = false
                dismiss()
            }
        }
    }
    
    @State private var fullAgreement: Bool = false
    @State private var agreeTermsOfUse: Bool = false
    @State private var agreePersonalInfo: Bool = false
    @State private var agreeMarketingInfo: Bool = false
    
    @ViewBuilder
    func termsPage() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    if !fullAgreement {
                        agreeTermsOfUse = true
                        agreePersonalInfo = true
                        agreeMarketingInfo = true
                    }
                    fullAgreement = true
                }
            } label: {
                HStack {
                    Label("동의", systemImage: "checkmark.circle.fill")
                        .font(.title2)
                        .labelStyle(.iconOnly)
                        .foregroundColor(fullAgreement ? Color("main-highlight-color") : Color("shape-bkg-color"))
                    
                    Text("약관에 전체 동의합니다.")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("main-text-color"))
                    
                    Spacer()
                }
                .padding()
            }
            
            Rectangle()
                .foregroundColor(Color("shape-bkg-color"))
                .frame(height: 1)
            
            termsLinks(title: "이용약관 (필수)", checked: agreeTermsOfUse) {
                TermsOfUseView()
                    .navigationTitle("이용약관 (필수)")
                    .modifier(NavigationColorModifier())
            } action: {
                withAnimation(.easeInOut) {
                    agreeTermsOfUse.toggle()
                    if !agreeTermsOfUse {
                        fullAgreement = false
                    }
                    
                    
                    if agreeTermsOfUse, agreePersonalInfo, agreeMarketingInfo {
                        fullAgreement = true
                    }
                }
            }
            
            termsLinks(title: "개인정보 수집 및 이용 (필수)", checked: agreePersonalInfo) {
                PrivacyPolicyView()
                    .navigationTitle("개인정보 수집 및 이용 (필수)")
                    .modifier(NavigationColorModifier())
            } action: {
                withAnimation(.easeInOut) {
                    agreePersonalInfo.toggle()
                    if !agreePersonalInfo {
                        fullAgreement = false
                    }
                    
                    
                    if agreeTermsOfUse, agreePersonalInfo, agreeMarketingInfo {
                        fullAgreement = true
                    }
                }
            }
            .padding(.bottom)
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("shape-bkg-color"))
        }
        .padding()
    }
    
    @ViewBuilder
    func termsLinks(title: String, checked: Bool, destination: () -> some View, action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) {
                Label("동의", systemImage: "checkmark.circle.fill")
                    .font(.title2)
                    .labelStyle(.iconOnly)
                    .foregroundColor(checked ? Color("main-highlight-color") : Color("shape-bkg-color"))
            }
            
            NavigationLink(destination: destination) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Label(title, systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
                .foregroundColor(Color("main-text-color"))
            }
        }
        .padding([.horizontal, .top])
    }
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var userName: String = ""
    @State private var isValidEmail: Bool = false
    @State private var isValidPassword: Bool = false
    @State private var verifyPassword: String = ""
    @State private var isSamePassword: Bool = false
    
    @FocusState private var currentField: FocusedTextField?
    
    @ViewBuilder
    func registeredUserPage() -> some View {
        VStack {
            HStack {
                Text("이메일 등록")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("main-text-color"))
                
                Spacer()
            }
            
            VStack {
                TextField("사용하실 이메일을 입력해주세요.", text: $email, prompt: Text("사용하실 이메일을 입력해주세요."))
                    .modifier(TextFieldModifier(text: $email, isValidInput: .constant((isValidEmail ? !loginViewModel.isAlreadyEmail : false)), currentField: _currentField, font: .subheadline.bold(), keyboardType: .emailAddress, contentType: .emailAddress, focusedTextField: .emailField, submitLabel: .next))
                    .onTapGesture {
                        currentField = .emailField
                        showDatePicker = false
                    }
                    .onSubmit {
                        currentField = .passwordField
                    }
                    .onChange(of: email) { newValue in
                        withAnimation(.easeInOut) {
                            loginViewModel.isAlreadyEmail = false
                            
                            if(newValue.range(of:"^\\w+([-+.']\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$", options: .regularExpression) != nil) {
                                isValidEmail = true
                            } else {
                                isValidEmail = false
                            }
                        }
                    }
                    .overlay {
                        if isValidEmail && email != "" {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    if loginViewModel.isAlreadyEmail {
                        Text("이미 존재하는 이메일 입니다.")
                            .font(.caption2)
                            .foregroundColor(Color("main-highlight-color"))
                    } else {
                        Text(!isValidEmail && email != "" ? "올바르지 않는 이메일 주소입니다." : " ")
                            .font(.caption2)
                            .foregroundColor(Color("main-highlight-color"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .modifier(VibrateAnimation(animatableData: vibrateOffset))
            .onChange(of: loginViewModel.isAlreadyEmail) { newValue in
                withAnimation(.spring()) {
                    vibrateOffset += newValue ? 1 : 0
                }
            }
            
            VStack {
                SecureField("비밀번호(8자리 이상)", text: $password, prompt: Text("비밀번호(8자리 이상)"))
                    .modifier(TextFieldModifier(text: $password, isValidInput: $isValidPassword, currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .newPassword, focusedTextField: .passwordField, submitLabel: .next))
                    .onTapGesture {
                        currentField = .passwordField
                        showDatePicker = false
                    }
                    .onSubmit {
                        currentField = .verifyPasswordField
                    }
                    .onChange(of: password) { newValue in
                        withAnimation(.easeInOut) {
                            isValidPassword = newValue.count >= 8 ? true : false
                            if newValue == "" {
                                verifyPassword = ""
                            }
                        }
                    }
                    .overlay {
                        if isValidPassword && password != "" && isSamePassword {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    Text(!isValidPassword && password != "" ? "비밀번호는 8자리 이상으로 설정할 수 있습니다." : " ")
                        .font(.caption)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            VStack {
                SecureField("비밀번호 확인", text: $verifyPassword, prompt: Text("비밀번호 확인"))
                    .modifier(TextFieldModifier(text: $verifyPassword, isValidInput: $isSamePassword, currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .newPassword, focusedTextField: .verifyPasswordField, submitLabel: .next))
                    .onTapGesture {
                        currentField = .verifyPasswordField
                        showDatePicker = false
                    }
                    .onSubmit {
                        currentField = .nameField
                    }
                    .onChange(of: verifyPassword) { newValue in
                        withAnimation(.easeInOut) {
                            isSamePassword = newValue == password ? true : false
                        }
                    }
                    .overlay {
                        if isValidEmail && verifyPassword != "" && isSamePassword {
                            HStack {
                                Spacer()
                                
                                DrawingCheckmarkView()
                            }
                            .padding()
                        }
                    }
                
                HStack {
                    Text(!isSamePassword && verifyPassword != "" ? "비밀번호가 일치하지 않습니다." : " ")
                        .font(.caption2)
                        .foregroundColor(Color("main-highlight-color"))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            HStack {
                Text("프로필 정보")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("main-text-color"))
                
                Spacer()
            }
            .padding(.top)
            
            VStack {
                TextField("이름", text: $userName, prompt: Text("이름"))
                    .modifier(TextFieldModifier(text: $userName, isValidInput: .constant(true), currentField: _currentField, font: .subheadline.bold(), keyboardType: .default, contentType: .username, focusedTextField: .nameField, submitLabel: .next))
                    .onTapGesture {
                        currentField = .nameField
                        showDatePicker = false
                    }
                    .onSubmit {
                        withAnimation(.spring()) {
                            currentField = nil
                            showDatePicker = true
                        }
                    }
                
                HStack {
                    Text(" ")
                        .font(.caption2)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Button {
                withAnimation(.spring()) {
                    currentField = nil
                    appViewModel.showMessageBoxBackground = true
                    showDatePicker = true
                }
            } label: {
                HStack {
                    TextField("생년월일", text: $userBirth, prompt: Text("생년월일"))
                        .font(.subheadline.bold())
                    
                    Spacer()
                }
                .disabled(true)
                .multilineTextAlignment(.leading)
                .padding(10)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("shape-bkg-color"))
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func signUpButton() -> some View {
        Button {
            withAnimation(.easeInOut) {
                loginViewModel.isAlreadyEmail = false
            }
            loginViewModel.isLoading = true
            loginViewModel.signUp(email: email, password: password, userName: userName, birth: userBirth)
        } label: {
            HStack {
                Spacer()
                
                if loginViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .tint(Color("main-highlight-color"))
                } else {
                    Text("회원가입 완료")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor((agreeTermsOfUse && agreePersonalInfo && isValidEmail && isSamePassword && email != "" && password != "" && verifyPassword != "" && userName != "" && userBirth != "") && !loginViewModel.isLoading ? Color("main-highlight-color") : Color("main-shape-bkg-color"))
        }
        .disabled((!(agreeTermsOfUse && agreePersonalInfo && isValidEmail && isSamePassword && email != "" && password != "" && verifyPassword != "" && userName != "" && userBirth != "")) || loginViewModel.isLoading)
        .padding()
        .padding(.bottom, 20)
    }
    
    
    @ViewBuilder
    func textFieldBackground(isValidInput: Bool, input: String) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isValidInput || input == "" ? Color("shape-bkg-color") : Color("main-highlight-color"))
    }
    
    @State private var showCompleteTitle: Bool = false
    @State private var showCompleteContents: Bool = false
    @ViewBuilder
    func signUpComplete(action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Spacer()
            
            if showCompleteTitle {
                Text("환영합니다!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("main-text-color"))
                    .transition(.move(edge: .bottom))
            }
            
            Spacer()
                .frame(height: 70)
            
            if showCompleteContents {
                VStack {
                    Text("회원가입이 완료되었습니다.")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("main-text-color"))
                        .padding(.bottom, 50)
                    
                    Text("아래 버튼을 클릭 후,")
                        .foregroundColor(Color("main-text-color"))
                    
                    Text("기존 계정으로 로그인 버튼을 클릭해 주세요.")
                        .foregroundColor(Color("main-text-color"))
                }
            }
            
            Spacer()
            
            if showCompleteContents {
                Button(action: action) {
                    HStack {
                        Spacer()
                        
                        Text("처음으로 돌아가기")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                        
                        Spacer()
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color("main-highlight-color"))
                }
            }
        }
        .padding()
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) {
                    showCompleteTitle = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring()) {
                    showCompleteContents = true
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                SignUpView(showDatePicker: .constant(false), userBirth: .constant(""))
                    .environmentObject(LoginViewModel())
                    .environmentObject(AppViewModel())
            }
        } else {
            NavigationView {
                SignUpView(showDatePicker: .constant(false), userBirth: .constant(""))
                    .environmentObject(AppViewModel())
                    .environmentObject(LoginViewModel())
            }
        }
    }
}
