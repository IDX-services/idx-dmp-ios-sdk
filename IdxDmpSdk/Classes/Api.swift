final class Api {
    private static func makeRequest(
        requestUrl: String,
        method: String = "GET",
        queryItems: [String: String?]? = [:]
    ) -> URLRequest {
        var urlComponent = URLComponents(string: requestUrl)!
        urlComponent.queryItems = queryItems?.map{item in
            return URLQueryItem(name: item.key, value: item.value)
        }
        
        var request = URLRequest(
            url: urlComponent.url!,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
    
    private static func sendRequest(request: URLRequest, completionHandler: @escaping (Data, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else {
                print("Response data is empty")
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(data, error)
            }
        }.resume()
    }
    
    static func get(
        url: String,
        queryItems: [String: String?]? = nil,
        completionHandler: @escaping (Data, Error?) -> Void
    ) {
        let request = makeRequest(requestUrl: url, method: "GET", queryItems: queryItems)

        sendRequest(request: request, completionHandler: completionHandler)
    }
    
    static func post(
        url: String,
        queryItems: [String: String?]? = nil,
        body: Encodable? = nil,
        completionHandler: @escaping (Data, Error?) -> Void
    ) {
        var request = makeRequest(requestUrl: url, method: "POST", queryItems: queryItems)
        
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        sendRequest(request: request, completionHandler: completionHandler)
    }
}
