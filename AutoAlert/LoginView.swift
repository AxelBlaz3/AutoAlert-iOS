//
//  LoginView.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import SwiftUI

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var someErrorAlert = false
    @State var incorrectCredentialsAlert = false
    @State var isUserLoggedIn = false
    
    var body: some View {
        VStack {
            TextField("Email", text: $email).padding()
            SecureField("Password", text: $password).textContentType(.password).padding()
            Button(action: {
                verifyCredentials()
            }, label: {
                Text("Login").padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(24).padding(.horizontal).padding(.top)
            })
            
            HStack{
                Text("New user? ")
                NavigationLink(destination: RegisterView()) {
                    Text("Register").fontWeight(.medium)
                        .navigationBarTitle(Text("Login"))
                }
                
            }.padding(.top, 8)
            
            NavigationLink(
                destination: ContentView(),
                isActive: $isUserLoggedIn,
                label: {
                    Text("")
                })
        }
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $someErrorAlert) {
            Alert(title: Text(""), message: Text("Some error occured"), dismissButton: .cancel())
        }
        .alert(isPresented: $incorrectCredentialsAlert) {
            Alert(title: Text(""), message: Text("Incorrect credentials"), dismissButton: .default(Text("OK"), action: {}))
        }
        .onAppear {
           // load()
        }
    }
    
    func verifyCredentials() {
        if (email.isEmpty || password.isEmpty) {
            incorrectCredentialsAlert = true
            return
        }
        let credentialsJson =
            [URLQueryItem(name: "email", value: email),
             URLQueryItem(name: "password", value: password)
            ]
        
        let url = URL(string: "https://wielabs.com/speed_auditor/login.php")!
        
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
                incorrectCredentialsAlert = true
                print("Error: HTTP request failed")
                return
            }
            
            do {
                let currentUser = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    User.setUserDefaultPreference(key: Constants.KEY_EMAIL, value: currentUser.email)
                    User.setUserDefaultPreference(key: Constants.KEY_USERNAME, value: currentUser.username)
                    User.setUserDefaultPreference(key: Constants.KEY_USER_ID, value: currentUser.id)
                    postStatistics(cachedUser: currentUser)
                    isUserLoggedIn = true
                    UserDefaults.standard.set(isUserLoggedIn, forKey: Constants.KEY_IS_LOGGED_IN)
                }
            } catch {
                print("Can't decode user JSON")
                return
            }
        }
        task.resume()
    }
    
    func updateStatistics(columnNameToBeUpdated: String, prevAppCycleId: Int, appCycleEndTimestamp: String) {
        if (prevAppCycleId == -1) {
            return
        }
        let credentialsJson =
            [URLQueryItem(name: "update_column_name", value: columnNameToBeUpdated),
             URLQueryItem(name: "app_cycle_id", value: String(prevAppCycleId)),
             URLQueryItem(name: "timestamp", value: appCycleEndTimestamp)
            ]
        
        let url = URL(string: "https://wielabs.com/speed_auditor/update_statistics.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = credentialsJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        print("Posting update statistics...")
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            print("Done with task")
            guard error == nil else {
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                print("Error: HTTP request failed")
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
                    
                
                if (!User.getLastClosedTimestamp().isEmpty && User.getPrevAppCycleId() > 0) {
                    self.updateStatistics(columnNameToBeUpdated: "app_cycle_end_timestamp", prevAppCycleId: User.getPrevAppCycleId(), appCycleEndTimestamp: User.getLastClosedTimestamp())
                }
                // isUserCreated = true
            } catch {
                print("Can't decode user JSON (app cycle id)")
                return
            }
        }
        task.resume()
    }
    
    static func getCurrentTimeStamp() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
