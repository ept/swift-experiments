import Foundation

struct Constants {
    static let MY_INSTANCE_ADDRESS = "muse-trial.us1a.cloud.realm.io"
    static let AUTH_URL  = URL(string: "https://\(MY_INSTANCE_ADDRESS)")!
    static let REALM_URL = URL(string: "realms://\(MY_INSTANCE_ADDRESS)/ToDo")!
}
