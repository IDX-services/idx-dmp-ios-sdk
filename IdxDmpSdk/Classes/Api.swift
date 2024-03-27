final class Api {
    private static func makeRequest (
        requestUrl: String,
        method: String = "GET",
        pathParams: [String: String]? = [:],
        queryItems: [String: String?]? = [:]
    ) throws -> URLRequest {
        var url = requestUrl
        pathParams?.forEach {parameter in
            url = url.replacingOccurrences(of: ":" + parameter.key, with: parameter.value)
        }

        guard var urlComponent = URLComponents(string: url) else {
            throw EDMPError.cannotCreateUrl(from: requestUrl)
        }

        urlComponent.queryItems = queryItems?.map{item in
            return URLQueryItem(name: item.key, value: item.value)
        }
        
        guard let preparedUrl = urlComponent.url else {
            throw EDMPError.urlIsNil
        }
        
        var request = URLRequest(
            url: preparedUrl,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpShouldHandleCookies = Config.Api.cookieIsEnabled

        return request
    }
    
    private static func sendRequest(
        request: URLRequest,
        retryCount: Int = 0,
        completionHandler: @escaping (Data?, Error?) -> Void
    ) {
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            func handleResponse(_ error: EDMPError) {
                if (retryCount > 0) {
                    return sendRequest(
                        request: request,
                        retryCount: retryCount - 1,
                        completionHandler: completionHandler
                    )
                }
                
                completionHandler(nil, error)
            }

            guard let data = data else {
                return handleResponse(EDMPError.responseIsEmpty)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return handleResponse(EDMPError.responseIsEmpty)
            }

            if (httpResponse.statusCode != 200) {
                return handleResponse(EDMPError.requestError)
            }

            completionHandler(data, error)
        }.resume()
    }
    
    static func get(
        url: String,
        pathParams: [String: String]? = nil,
        queryItems: [String: String?]? = nil,
        retryCount: Int = 0,
        completionHandler: ((Data?, Error?) -> Void)? = { _,_ in }
    ) throws {
        let request = try makeRequest(requestUrl: url, method: "GET", pathParams: pathParams, queryItems: queryItems)

        sendRequest(request: request, retryCount: retryCount, completionHandler: completionHandler!)
    }
    
    static func post(
        url: String,
        pathParams: [String: String]? = nil,
        queryItems: [String: String?]? = nil,
        body: Encodable? = nil,
        retryCount: Int = 0,
        completionHandler: ((Data?, Error?) -> Void)? = { _,_ in }
    ) throws {
        var request = try makeRequest(requestUrl: url, method: "POST", pathParams: pathParams, queryItems: queryItems)
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        sendRequest(request: request, retryCount: retryCount, completionHandler: completionHandler!)
    }
}
