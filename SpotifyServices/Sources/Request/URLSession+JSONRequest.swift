//
//  URLSession+JSONRequest.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

extension URLSession {
    
    func getResponse<T: Codable>(for request: URLRequest,
                                 responseType: T.Type,
                                 responseHandler: @escaping (Result<T>) -> Void) {
        
        let task = dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    responseHandler(.failure(error ?? E.unknownError))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let responseObject = try decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    responseHandler(.success(responseObject))
                }
            } catch {
                DispatchQueue.main.async {
                    responseHandler(.failure(E.unexpectedResponse(data, error)))
                }
            }
        }
        
        task.resume()
    }
}
