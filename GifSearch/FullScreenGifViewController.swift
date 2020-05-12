//
//  FullScreenGifViewController.swift
//  GifSearch
//
//  Created by Luke Hiesterman on 5/9/20.
//

import UIKit
import YYImage

class FullScreenGifViewController: UIViewController
{
    var model : GifSearchResponse.SearchResult.GifModel.GifURLModel
    var imageFetcher : ImageFetcher
    var imageView : YYAnimatedImageView?
    var imageFetchTask : URLSessionDataTask?

    init(model : GifSearchResponse.SearchResult.GifModel.GifURLModel, imageFetcher : ImageFetcher)
    {
        self.model = model
        self.imageFetcher = imageFetcher
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        effectView.frame = view.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(effectView)

        let imageView = YYAnimatedImageView()
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.imageView = imageView

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))

        let toolbar = UIToolbar()
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed(_:)))]

        imageFetchTask = imageFetcher.fetchImage(from: model.url) { [weak self] (image, error) in
            self?.imageView?.image = image
        }
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        imageFetchTask?.cancel()
    }

    @objc func doneButtonPressed(_ sender : NSObject)
    {
        dismiss(animated: true)
    }

    @objc func shareButtonPressed(_ sender : UIBarButtonItem)
    {
        guard let image = imageView?.image else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        navigationController?.present(activityController, animated: true)
    }
}
