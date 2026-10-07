/// `versaoMaior` do calc.js: "1.0.10" > "1.0.9"; o que não for x.y.z não dispara aviso.
public func versaoMaior(_ a: String?, _ b: String?) -> Bool {
    func partes(_ v: String?) -> [Double]? {
        guard let v else { return nil }
        let p = v.split(separator: ".", omittingEmptySubsequences: false)
        guard p.count == 3, p.allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(ehDigito) }) else { return nil }
        return p.map { Double($0)! }
    }
    guard let x = partes(a), let y = partes(b) else { return false }
    for i in 0..<3 where x[i] != y[i] { return x[i] > y[i] }
    return false
}
