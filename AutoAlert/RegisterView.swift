//
//  RegisterView.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import SwiftUI

struct RegisterView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @State var someErrorAlert = false
    @State var invalidFields = false
    @State var isUserCreated = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            TextField("Username", text: $username).padding()
            TextField("Email", text: $email).padding()
            SecureField("Password", text: $password).textContentType(.password).padding()
            Button(action: {
                verifyCredentials()
            }, label: {
                Text("Register").padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(24).padding(.horizontal).padding(.top)
            })
            
            HStack {
                Text("Already registered? ")
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Login").fontWeight(.medium)
                })
            }.padding(.top, 8)
            
            NavigationLink(
                destination: ContentView(),
                isActive: $isUserCreated,
                label: {
                    Text("")
                })
        }
        .navigationBarTitle(Text("Register"))
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $someErrorAlert) {
            Alert(title: Text(""), message: Text("Some error occured"), dismissButton: .cancel())
        }
        .alert(isPresented: $invalidFields) {
            Alert(title: Text(""), message: Text("Invalid or empty fields"), dismissButton: .cancel())
        }
    }
    
    func verifyCredentials() {
        
        if (email.isEmpty || password.isEmpty || username.isEmpty) {
            invalidFields = true
            return
        }
        let credentialsJson =
            [URLQueryItem(name: "email", value: email),
             URLQueryItem(name: "password", value: password),
             URLQueryItem(name: "username", value: username)
            ]
        
        let url = URL(string: "https://wielabs.com/speed_auditor/register.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = credentialsJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                someErrorAlert = true
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                someErrorAlert = true
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                someErrorAlert = true
                print("Error: HTTP request failed")
                return
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                postStatistics(cachedUser: user)
                isUserCreated = true
                UserDefaults.standard.set(user.id, forKey: Constants.KEY_USER_ID)
                UserDefaults.standard.set(user.username, forKey: Constants.KEY_USERNAME)
                UserDefaults.standard.setValue(user.email, forKey: Constants.KEY_EMAIL)
                UserDefaults.standard.set(isUserCreated, forKey: Constants.KEY_IS_LOGGED_IN)
            } catch {
                print("Can't decode user JSON")
                return
            }
        }
        task.resume()
    }
    
    func postStatistics(cachedUser: User) {
        let credentialsJson =
            [URLQueryItem(name: "user_id", value: String(cachedUser.id)),
             URLQueryItem(name: "departure_timestamp", value: LoginView.getCurrentTimeStamp())]
        
        let url = URL(string: "https://wielabs.com/speed_auditor/statistics.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = credentialsJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                //  someErrorAlert = true
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                // someErrorAlert = true
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                // someErrorAlert = true
                print("Error: HTTP request failed")
                return
            }
            
            do {
                let currentUser = try JSONDecoder().decode(User.self, from: data)
                    // self.user.prevAppCycleId = currentUser.prevAppCycleId
                UserDefaults.standard.set(User.getAppCycleId(), forKey: Constants.KEY_PREV_APP_CYCLE_ID)
                    User.setUserDefaultPreference(key: Constants.KEY_APP_CYCLE_ID, value: currentUser.appCycleId)
                // isUserCreated = true
            } catch {
                print("Can't decode user JSON (app cycle id)")
                return
            }
        }
        task.resume()
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
