import SwiftUI

struct ContentView: View {
    @State private var chrome = ChainChrome()

    var body: some View {
        ChainScreen(chrome: chrome)
    }
}

#Preview {
    ContentView()
        .environment(ChainStore())
}
