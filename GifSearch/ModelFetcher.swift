//
//  ModelFetcher.swift
//  GifSearch
//
//  Created by Luke Hiesterman on 5/9/20.
//

import Foundation
import UIKit

struct GifSearchResponse : Decodable
{
    struct SearchResult : Decodable, Equatable, Hashable
    {
        struct GifModel : Decodable, Equatable
        {
            struct GifURLModel : Decodable, Equatable
            {
                var width : String
                var height : String
                var url : URL
            }

            var original : GifURLModel
            var downsized : GifURLModel
            var fixedWidthSmallStill : GifURLModel
        }

        var id : String
        var title : String
        var images : GifModel

        var hashValue : Int { id.hashValue }

        func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
    }

    var data: [SearchResult]
}

class ModelFetcher
{
    enum Sections : String {
        case main
    }

    let urlSession : URLSession

    init(urlSession : URLSession)
    {
        self.urlSession = urlSession
    }

    func fetchModel(searchText : String, snapshot : NSDiffableDataSourceSnapshot<Sections, GifSearchResponse.SearchResult>? = nil, resultLimit : Int = 100, handler: @escaping (NSDiffableDataSourceSnapshot<Sections, GifSearchResponse.SearchResult>) -> Void) -> URLSessionDataTask
    {
        var requestComponents = URLComponents(string: "https://api.giphy.com/v1/gifs/search")!
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "api_key", value: "ZsUpUm2L6cVbvei347EQNp7HrROjbOdc"))
        queryItems.append(URLQueryItem(name: "q", value: searchText))
        queryItems.append(URLQueryItem(name: "limit", value: String(resultLimit)))
        if let snapshot = snapshot {
            queryItems.append(URLQueryItem(name: "offset", value: String(snapshot.numberOfItems)))
        }
        requestComponents.queryItems = queryItems

        let dataTask = urlSession.dataTask(with: URLRequest(url: requestComponents.url!)) { data, response, error in
            guard let data = data, error == nil else { return }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let resultModel = try! decoder.decode(GifSearchResponse.self, from: data)

            DispatchQueue.main.async {
                var modelSnapshot: NSDiffableDataSourceSnapshot<Sections, GifSearchResponse.SearchResult>
                if let snapshot = snapshot {
                    modelSnapshot = snapshot
                }
                else {
                    modelSnapshot = NSDiffableDataSourceSnapshot<Sections, GifSearchResponse.SearchResult>()
                    modelSnapshot.appendSections([.main])
                }

                modelSnapshot.appendItems(resultModel.data)
                handler(modelSnapshot)
            }

        }

        dataTask.resume()
        return dataTask
    }
}
