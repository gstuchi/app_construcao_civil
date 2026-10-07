// swift-tools-version: 6.2
import PackageDescription

/* Núcleo do Custta nativo: cálculo, modelo, normalização e sincronização, sem tela e sem
   Firebase. Roda com `swift test` no Mac; o app (app-ios/Custta.xcodeproj) o usa como pacote local. */
let package = Package(
    name: "CusttaNucleo",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "CusttaNucleo", targets: ["CusttaNucleo"])],
    targets: [
        .target(name: "CusttaNucleo"),
        .testTarget(name: "CusttaNucleoTests", dependencies: ["CusttaNucleo"]),
    ]
)
