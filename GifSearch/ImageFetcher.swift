//
//  ImageFetcher.swift
//  GifSearch
//
//  Created by Luke Hiesterman on 5/9/20.
//

import Foundation
import YYImage

class ImageFetcher
{
    let urlSession : URLSession

    init(urlSession : URLSession)
    {
        self.urlSession = urlSession
    }

    func fetchImage(from url : URL, handler : @escaping (YYImage?, Error?) -> Void) -> URLSessionDataTask
    {
        let task = urlSession.dataTask(with: url) { data, _, error in
            if let data = data {
                DispatchQueue.main.async { handler(YYImage(data: data), error) }
            }
            else  {
                DispatchQueue.main.async { handler(nil, error) }
            }
        }

        task.resume()
        return task
    }
}
