import UIKit

enum NetworkMethod: String {
    case get
    case post
}

enum NetworkError: Error {
    case data
    case encoding(error: Error)
    case decoding(error: Error)
}

protocol NetworkEndPoint {
    var baseURL: URL { get }
    var network: Network { get }
    var jsonDecoder: JSONDecoder { get }
    var urlRequest: URLRequest { get }
}

extension NetworkEndPoint {
    var baseURL: URL {
        guard let url = URL(string: "https://tonytrejodev.free.beeceptor.com") else {
            fatalError("URL could not be found.")
        }
        return url
    }
    
    var session: URLSession { .shared }
    var network: Network { Network() }
    var jsonDecoder: JSONDecoder { JSONDecoder() }
}

typealias NetworkResult<T: Codable> = Result<T, NetworkError>

struct Network {
    
    func getCryptos(networkRequest: NetworkEndPoint,
                    completion: @escaping (NetworkResult<[Crypto]>) -> Void) {
    
        let request = networkRequest.urlRequest
        
        let task = networkRequest.session.dataTask(with: request) { (data, urlResponse, error) in
            
            let result: NetworkResult<[Crypto]>
            defer {
                completion(result)
            }
            
            guard let data = data else {
                return result = .failure(.data)
            }
            
            do {
                let objectDecoded = try networkRequest.jsonDecoder.decode([Crypto].self, from: data)
                result = .success(objectDecoded)
            } catch {
                result = .failure(.decoding(error: error))
            }
            
        }
        
        task.resume()
    }
    
    func createPost(networkRequest: NetworkEndPoint,
                    httpBody: Data? = nil,
                    completion: @escaping (NetworkResult<PostResponse>) -> Void) {
       
        var request = networkRequest.urlRequest
        request.httpBody = httpBody
        
        let task = networkRequest.session.dataTask(with: request) { (data, urlResponse, error) in
            
            let result: NetworkResult<PostResponse>
            defer {
                completion(result)
            }
            
            guard let data = data else {
                return result = .failure(.data)
            }
            
            do {
                let objectDecoded = try networkRequest.jsonDecoder.decode(PostResponse.self, from: data)
                result = .success(objectDecoded)
            } catch {
                result = .failure(.decoding(error: error))
            }
            
        }
        
        task.resume()
    }
}

struct Crypto: Codable {
    let symbol: String
    let price: Double
}

/*
[__lldb_expr_1.Crypto(symbol: "XRP", price: 0.51712048871858), __lldb_expr_1.Crypto(symbol: "WOZX", price: 2.86325750658067), __lldb_expr_1.Crypto(symbol: "BTC", price: 19190.426010045157), __lldb_expr_1.Crypto(symbol: "BTCV", price: 66.61105369058797), __lldb_expr_1.Crypto(symbol: "ALLBI", price: 0.00495452304336), __lldb_expr_1.Crypto(symbol: "DF", price: 0.22036849849893), __lldb_expr_1.Crypto(symbol: "ETH", price: 591.4187273438921), __lldb_expr_1.Crypto(symbol: "TRX", price: 0.02937642050303), __lldb_expr_1.Crypto(symbol: "LBC", price: 0.07171163356022), __lldb_expr_1.Crypto(symbol: "ADA", price: 0.15430348473841)]
*/
extension URLRequest {
    
    
    static func getRequest(url: URL,
                           httpMethod: NetworkMethod,
                           pathComponent: URLRequestPath) -> URLRequest {
        var baseURL = url
        baseURL.appendPathComponent(pathComponent.rawValue)
        var request = URLRequest(url: baseURL)
        request.httpMethod = httpMethod.rawValue
        
        return request
    }
}

protocol URLRequestPath {
    var rawValue: String { get }
}

enum CryptoPath: String, URLRequestPath {
    
    case cryptos
    case createpost
}

struct CryptosEndPoint: NetworkEndPoint {
    
    var urlRequest: URLRequest {
        let request = URLRequest.getRequest(url: baseURL,
                                            httpMethod: .get,
                                            pathComponent: CryptoPath.cryptos)
        return request
    }
    
    func getCryptos(completion: @escaping (NetworkResult<[Crypto]>) -> Void) {
        network.getCryptos(networkRequest: self,
                           completion: completion)
    }
}

let cryptosEndPoint = CryptosEndPoint()
cryptosEndPoint.getCryptos { (result) in
    switch result {
    case .success(let cryptos):
        print(cryptos)
    case .failure(let error):
        print(error)
    }
}

struct PostResponse: Codable {
    let status: [String: String]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        status = try container.decode([String: String].self)
    }
}

struct PostData: Codable {
    let name: String
    let text: String
}

struct CreatePostEndPoint: NetworkEndPoint {
    
    var urlRequest: URLRequest {
        let request = URLRequest.getRequest(url: baseURL,
                                            httpMethod: .post,
                                            pathComponent: CryptoPath.createpost)
        return request
    }
    
    func createPost(_ post: PostData,
                    completion: @escaping (NetworkResult<PostResponse>) -> Void) {
        
        let httpBody: Data?
        do {
            httpBody = try JSONEncoder().encode(post)
        } catch {
            return completion(.failure(.encoding(error: error)))
        }
        
        network.createPost(networkRequest: self,
                           httpBody: httpBody,
                           completion: completion)
    }
}

let createPostEndPoint = CreatePostEndPoint()
let post = PostData(name: "Tony Trejo", text: "New post!!!")
createPostEndPoint.createPost(post) { (result) in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error)
    }
}
