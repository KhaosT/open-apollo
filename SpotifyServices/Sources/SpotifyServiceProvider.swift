//
//  SpotifyServiceProvider.swift
//  SpotifyServices
//
//  Created by Khaos Tian on 9/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public class SpotifyServiceProvider: NSObject {
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 60
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    
    public private(set) var currentConfiguration: ServiceConfiguration?
    private var serviceConfiguration: ServiceConfiguration {
        return currentConfiguration!
    }
    
    private var userSession: UserSession?
    private var currentUser: User?
    
    private lazy var playbackService = PlaybackService(with: self)
    
    public override init() {
        super.init()
    }
}

extension SpotifyServiceProvider {
    
    public func configure(with configuration: ServiceConfiguration) {
        self.currentConfiguration = configuration
    }
    
    public func start(completionHandler: @escaping (Result<User>) -> Void) {
        updateAccessToken { result in
            switch result {
            case .success:
                self.getUser { userResult in
                    switch userResult {
                    case .success(let user):
                        completionHandler(.success(user))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Access Token

extension SpotifyServiceProvider {
    
    private func updateAccessToken(completionHandler: @escaping (Result<UserSession>) -> Void) {
        let url = serviceConfiguration.serviceURL.appendingPathComponent("/refresh")
        var request = URLRequest(url: url)
        
        let requestBody = [
            "refresh_token": serviceConfiguration.refreshToken
        ]
        
        guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completionHandler(.failure(E.internalError))
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(error ?? E.unknownError))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let response = try? decoder.decode(RefreshTokenResponse.self, from: data) {
                
                if let refreshToken = response.refreshToken {
                    NSLog("New Refresh Token: \(refreshToken)")
                }
                
                DispatchQueue.main.async {
                    let userSession = UserSession(accessToken: response.accessToken, expireAt: Date().addingTimeInterval(TimeInterval(response.expiresIn - 300)))
                    self?.userSession = userSession
                    completionHandler(.success(userSession))
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(.failure(E.unexpectedResponse(data, error)))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - User

extension SpotifyServiceProvider {
    
    public func getUser(completionHandler: @escaping (Result<User>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getUser(with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getUser(with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getUser(with authorizationValue: String, completionHandler: @escaping (Result<User>) -> Void) {
        let url = ServiceEndpoint.userProfile.url
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: User.self) { [weak self] result in
            if let user = result.value {
                self?.currentUser = user
            }
            
            completionHandler(result)
        }
    }
}

// MARK: - Playlists

extension SpotifyServiceProvider {
    
    public func getPlaylists(offset: Int = 0, completionHandler: @escaping (Result<Paginated<SimplifiedPlaylist>>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getPlaylists(offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getPlaylists(offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getPlaylists(offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<Paginated<SimplifiedPlaylist>>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.myPlaylists.url, resolvingAgainstBaseURL: false)
        requestUrlBuilder!.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: Paginated<SimplifiedPlaylist>.self, responseHandler: completionHandler)
    }
    
    public func getPlaylist(_ id: String, completionHandler: @escaping (Result<Playlist>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getPlaylist(of: id, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getPlaylist(of: id, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getPlaylist(of id: String, with authorizationValue: String, completionHandler: @escaping (Result<Playlist>) -> Void) {
        var request = URLRequest(url: ServiceEndpoint.playlist(id).url)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: Playlist.self, responseHandler: completionHandler)
    }
}

// MARK: - Album

extension SpotifyServiceProvider {
    
    public func getAlbum(_ id: String, completionHandler: @escaping (Result<Album>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getAlbum(of: id, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getAlbum(of: id, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getAlbum(of id: String, with authorizationValue: String, completionHandler: @escaping (Result<Album>) -> Void) {
        var request = URLRequest(url: ServiceEndpoint.album(id).url)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: Album.self, responseHandler: completionHandler)
    }
}

// MARK: Categories

extension SpotifyServiceProvider {
    
    public func getCategories(country: String? = nil,
                              locale: String? = nil,
                              offset: Int = 0,
                              completionHandler: @escaping (Result<CategoriesResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getCategories(country: country, locale: locale, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getCategories(country: country, locale: locale, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getCategories(country: String?, locale: String?, offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<CategoriesResponse>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.categories.url, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        } else if let user = currentUser {
            queryItems.append(URLQueryItem(name: "country", value: user.country))
        }
        
        if let locale = locale {
            queryItems.append(URLQueryItem(name: "locale", value: locale))
        } else {
            queryItems.append(URLQueryItem(name: "locale", value: Locale.current.identifier))
        }
        
        requestUrlBuilder!.queryItems = queryItems
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: CategoriesResponse.self, responseHandler: completionHandler)
    }
}

// MARK: - Category Playlists

extension SpotifyServiceProvider {
    
    public func getCategoryPlaylists(for id: String,
                                     country: String? = nil,
                                     offset: Int = 0,
                                     completionHandler: @escaping (Result<CategoryPlaylistsResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getCategoryPlaylists(for: id, country: country, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getCategoryPlaylists(for: id, country: country, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getCategoryPlaylists(for id: String, country: String?, offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<CategoryPlaylistsResponse>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.categoryPlaylists(id).url, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "50"),
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        } else if let user = currentUser {
            queryItems.append(URLQueryItem(name: "country", value: user.country))
        }
        
        requestUrlBuilder!.queryItems = queryItems
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: CategoryPlaylistsResponse.self, responseHandler: completionHandler)
    }
}

// MARK: - Featured Playlists

extension SpotifyServiceProvider {
    
    public func getFeaturedPlaylists(country: String? = nil,
                                     locale: String? = nil,
                                     timestamp: Date? = nil,
                                     offset: Int = 0,
                                     completionHandler: @escaping (Result<FeaturedPlaylistsResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getFeaturedPlaylists(country: country, locale: locale, timestamp: timestamp, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getFeaturedPlaylists(country: country, locale: locale, timestamp: timestamp, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getFeaturedPlaylists(country: String?, locale: String?, timestamp: Date?, offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<FeaturedPlaylistsResponse>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.featuredPlaylists.url, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        } else if let user = currentUser {
            queryItems.append(URLQueryItem(name: "country", value: user.country))
        }
        
        if let locale = locale {
            queryItems.append(URLQueryItem(name: "locale", value: locale))
        } else {
            queryItems.append(URLQueryItem(name: "locale", value: Locale.current.identifier))
        }
        
        if let timestamp = timestamp {
            let timestampValue = ISO8601DateFormatter.string(from: timestamp, timeZone: .autoupdatingCurrent, formatOptions: .withInternetDateTime)
            queryItems.append(URLQueryItem(name: "timestamp", value: timestampValue))
        } else {
            let timestampValue = ISO8601DateFormatter.string(from: Date(), timeZone: .autoupdatingCurrent, formatOptions: .withInternetDateTime)
            queryItems.append(URLQueryItem(name: "timestamp", value: timestampValue))
        }
        
        requestUrlBuilder!.queryItems = queryItems
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: FeaturedPlaylistsResponse.self, responseHandler: completionHandler)
    }
}

// MARK: - New Releases

extension SpotifyServiceProvider {
    
    public func getNewReleases(country: String? = nil,
                               offset: Int = 0,
                               completionHandler: @escaping (Result<NewReleasesResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getNewReleases(country: country, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getNewReleases(country: country, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getNewReleases(country: String?, offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<NewReleasesResponse>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.newReleases.url, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        } else if let user = currentUser {
            queryItems.append(URLQueryItem(name: "country", value: user.country))
        }
        
        requestUrlBuilder!.queryItems = queryItems
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: NewReleasesResponse.self, responseHandler: completionHandler)
    }
}

// MARK: - Search

extension SpotifyServiceProvider {
    
    public func search(_ keyword: String, completionHandler: @escaping (Result<SearchResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.search(keyword, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            search(keyword, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func search(_ keyword: String, with authorizationValue: String, completionHandler: @escaping (Result<SearchResponse>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.search.url, resolvingAgainstBaseURL: false)
        let queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "type", value: "album,artist,playlist,track"),
        ]
        
        requestUrlBuilder!.queryItems = queryItems
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: SearchResponse.self, responseHandler: completionHandler)
    }
}

// MARK: - Artist

extension SpotifyServiceProvider {
    
    public func getArtistAlbums(_ id: String, offset: Int = 0, completionHandler: @escaping (Result<Paginated<SimplifiedAlbum>>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.getArtistAlbums(id, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            getArtistAlbums(id, offset: offset, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func getArtistAlbums(_ id: String, offset: Int, with authorizationValue: String, completionHandler: @escaping (Result<Paginated<SimplifiedAlbum>>) -> Void) {
        var requestUrlBuilder = URLComponents(url: ServiceEndpoint.artistAlbums(id).url, resolvingAgainstBaseURL: false)
        requestUrlBuilder!.queryItems = [
            URLQueryItem(name: "market", value: "from_token"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        var request = URLRequest(url: requestUrlBuilder!.url!)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: Paginated<SimplifiedAlbum>.self, responseHandler: completionHandler)
    }
}

// MARK: - Track

extension SpotifyServiceProvider {
    
    public func track(for trackId: String, completionHandler: @escaping (Result<Track>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.track(for: trackId, with: userSession.authorizationValue, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            track(for: trackId, with: userSession.authorizationValue, completionHandler: completionHandler)
        }
    }
    
    private func track(for trackId: String, with authorizationValue: String, completionHandler: @escaping (Result<Track>) -> Void) {
        var request = URLRequest(url: ServiceEndpoint.track(trackId).url)
        
        request.httpMethod = "GET"
        request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        
        urlSession.getResponse(for: request, responseType: Track.self, responseHandler: completionHandler)
    }
}

// MARK: - Audio Track

extension SpotifyServiceProvider {
    
    public func audioTrack(for track: Track, offlineOnly: Bool) -> SpotifyAudioTrack? {
        return playbackService.audioTrack(for: track, offlineOnly: offlineOnly)
    }
}

// MARK: - Track Info

extension SpotifyServiceProvider {
    
    func trackFileInfo(for trackId: String, completionHandler: @escaping (Result<TrackFileInfo>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.trackFileInfo(for: trackId, with: userSession.accessToken, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            trackFileInfo(for: trackId, with: userSession.accessToken, completionHandler: completionHandler)
        }
    }
    
    private func trackFileInfo(for trackId: String, with accessToken: String, completionHandler: @escaping (Result<TrackFileInfo>) -> Void) {
        
        guard let publicKeyString = KeychainServices.shared.deviceKeyPublicKeyData?.base64EncodedString() else {
            DispatchQueue.main.async {
                completionHandler(.failure(E.internalError))
            }
            return
        }
        
        let url = serviceConfiguration.trackServiceURL.appendingPathComponent("/track")
        var request = URLRequest(url: url)
        
        let requestBody = [
            "track_id": trackId,
            "token": accessToken,
            "public_key": publicKeyString
        ]
        
        guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completionHandler(.failure(E.internalError))
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(error ?? E.unknownError))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let response = try? decoder.decode(TrackFileInfo.self, from: data) {
                DispatchQueue.main.async {
                    completionHandler(.success(response))
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(.failure(E.unexpectedResponse(data, error)))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Tracks Info

extension SpotifyServiceProvider {
    
    func tracksInfo(for trackIds: [String], completionHandler: @escaping (Result<[TrackFileInfo]>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.tracksInfo(for: trackIds, with: userSession.accessToken, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            tracksInfo(for: trackIds, with: userSession.accessToken, completionHandler: completionHandler)
        }
    }
    
    private func tracksInfo(for trackIds: [String], with accessToken: String, completionHandler: @escaping (Result<[TrackFileInfo]>) -> Void) {
        
        guard let publicKeyString = KeychainServices.shared.deviceKeyPublicKeyData?.base64EncodedString() else {
            DispatchQueue.main.async {
                completionHandler(.failure(E.internalError))
            }
            return
        }
        
        let url = serviceConfiguration.trackServiceURL.appendingPathComponent("/tracks")
        var request = URLRequest(url: url)
        
        let requestBody: [String: Any] = [
            "track_ids": trackIds,
            "token": accessToken,
            "public_key": publicKeyString
        ]
        
        guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completionHandler(.failure(E.internalError))
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(error ?? E.unknownError))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let response = try? decoder.decode(TracksInfo.self, from: data) {
                DispatchQueue.main.async {
                    completionHandler(.success(response.tracks))
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(.failure(E.unexpectedResponse(data, error)))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Storage Resolve

extension SpotifyServiceProvider {
    
    func resolveStorage(for fileId: String, completionHandler: @escaping (Result<FileStorageResolveResponse>) -> Void) {
        guard let userSession = userSession else {
            completionHandler(.failure(E.missingUserSession))
            return
        }
        
        if userSession.isExpired {
            updateAccessToken { [weak self] result in
                switch result {
                case .success(let userSession):
                    self?.resolveStorage(for: fileId, with: userSession.accessToken, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            resolveStorage(for: fileId, with: userSession.accessToken, completionHandler: completionHandler)
        }
    }
    
    private func resolveStorage(for fileId: String, with accessToken: String, completionHandler: @escaping (Result<FileStorageResolveResponse>) -> Void) {
        let url = serviceConfiguration.serviceURL.appendingPathComponent("/storage-resolve")
        var request = URLRequest(url: url)
        
        let requestBody = [
            "file_id": fileId,
            "access_token": accessToken
        ]
        
        guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completionHandler(.failure(E.internalError))
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(error ?? E.unknownError))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let response = try? decoder.decode(FileStorageResolveResponse.self, from: data) {
                DispatchQueue.main.async {
                    completionHandler(.success(response))
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(.failure(E.unexpectedResponse(data, error)))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Downloaded Playlist

extension SpotifyServiceProvider {
    
    public func downloadedPlaylists() -> [Playlist] {
        return LocalStorageManager.shared.savedPlaylists()
    }
}
