import Amplify
import SwiftUI

enum AuthState {
    case signUp
    case login
    case confirmCode(username: String)
    case session(user: AuthUser)
}

final class SessionManager: ObservableObject {
    @Published var authState: AuthState = .login
    @Published var authError: String = ""

    func getCurrentAuthUser() {
        if let user = Amplify.Auth.getCurrentUser() {
            authState = .session(user: user)
        } else {
            authState = .login
        }
    }

    func showSignUp() {
        authState = .signUp
        authError = ""
    }

    func showLogin() {
        authState = .login
        authError = ""
    }

    func signUp(username: String, email: String, password: String) {
        let attributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: attributes)
        _ = Amplify.Auth.signUp(username: username, password: password, options: options) { [weak self] result in
            switch result {
            case let .success(signUpResult):
                switch signUpResult.nextStep {
                case .done:
                    print("Finished sign up")
                case .confirmUser:
                    DispatchQueue.main.async {
                        self?.authState = .confirmCode(username: username)
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    self?.authError = "\(error.errorDescription)\n\(error.recoverySuggestion)"
                }
            }
        }
    }

    func confirm(username: String, code: String) {
        _ = Amplify.Auth.confirmSignUp(for: username, confirmationCode: code) { [weak self] result in
            switch result {
            case let .success(confirmResult):
                if confirmResult.isSignupComplete {
                    DispatchQueue.main.async {
                        self?.showLogin()
                    }
                }
            case let .failure(error):
                print(error)
            }
        }
    }

    func login(username: String, password: String) {
        _ = Amplify.Auth.signIn(username: username, password: password) { [weak self] result in
            switch result {
            case let .success(signInResult):
                if signInResult.isSignedIn {
                    DispatchQueue.main.async {
                        self?.getCurrentAuthUser()
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    self?.authError = "\(error.errorDescription)\n\(error.recoverySuggestion)"
                }
            }
        }
    }

    func signOut() {
        _ = Amplify.Auth.signOut { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.getCurrentAuthUser()
                }
            case let .failure(error):
                print(error)
            }
        }
    }
}
