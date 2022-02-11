import SwiftUI

typealias Bottle = ListBottlesQuery.Data.ListBottle.Item
typealias Bottles = [Bottle]

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager

    @State var bottles: Bottles?
    @State var showPopover = false
    @State var isError = false

    let userId: String

    @Sendable func fetchBottles() {
        guard let apollo = Network.shared.apollo else {
            isError = true
            return
        }
        apollo.clearCache()
        apollo.fetch(query: ListBottlesQuery(
                filter: BottleFilterInput(userId: TableStringFilterInput(eq: userId)))
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let bottles = graphQLResult.data?.listBottles?.items {
                    self.bottles = bottles as? Bottles
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    func displayPopover() {
        showPopover = true
    }

    func dismissPopover() {
        showPopover = false
    }

    var body: some View {
        VStack {
            NavigationView {
                if let bottles = bottles {
                    if bottles.count == 0 {
                        VStack {
                            Spacer()
                            Text("Welcome to LastDram!").font(.title)
                            Text("You have no bottles in your collection.").padding()
                            Text("Start adding bottles by tapping the \"+\" below!").padding()
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(bottles.sorted(by: { $0.name! < $1.name! }), id: \.id) { bottle in
                                NavigationLink(bottle.name!, destination: BottleView(bottle: bottle))
                            }
                        }
                        .navigationTitle("My Bottles")
                        .onAppear(perform: fetchBottles)
                        .refreshable(action: fetchBottles)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                }
            }
            .onAppear(perform: fetchBottles)

            ZStack {
                Button(action: displayPopover) {
                    Image(systemName: "plus.circle.fill")
                            .font(.system(size: 90))
                }.popover(isPresented: $showPopover) {
                    AddBottleView(userId: userId, onBottleCreate: {
                        fetchBottles()
                        dismissPopover()
                    })
                }
                FooterView()
            }
        }.alert(isPresented: $isError) {
            Alert(title: Text("Error"),
                    message: Text("An error occurred."),
                    dismissButton: Alert.Button.default(
                            Text("Return to login"), action: { sessionManager.signOut() }
                    )
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(userId: "123")
    }
}