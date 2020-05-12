//
//  ViewController.swift
//  GifSearch
//
//  Created by Luke Hiesterman on 5/7/20.
//

import YYImage
import UIKit

class GifCell : UICollectionViewCell
{
    var activeDataTask : URLSessionDataTask?
    var model : GifSearchResponse.SearchResult?
    var imageView = YYAnimatedImageView()

    override init(frame : CGRect)
    {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    required init?(coder : NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse()
    {
        model = nil
        activeDataTask?.cancel()
        imageView.image = nil
    }

    func apply(model : GifSearchResponse.SearchResult, imageFetcher : ImageFetcher)
    {
        // first fetch a small still image to minimize latency to first frame,
        // then fetch a version with all the frames
        activeDataTask = imageFetcher.fetchImage(from: model.images.fixedWidthSmallStill.url) { [weak self] (image, error) in
            guard let self = self,
                  let image = image
            else { return }

            self.imageView.image = image

            self.activeDataTask = imageFetcher.fetchImage(from: model.images.downsized.url) { [weak self] (image, error) in
                self?.imageView.image = image
            }
        }
    }
}

class ViewController : UIViewController, UISearchBarDelegate, UICollectionViewDelegateFlowLayout
{
    @IBOutlet var collectionView : UICollectionView?
    @IBOutlet var searchBar : UISearchBar?
    var diffableDataSource : UICollectionViewDiffableDataSource<ModelFetcher.Sections, GifSearchResponse.SearchResult>?
    var searchTask : URLSessionDataTask?

    // for testing purposes I could create an initializer that allows injecting these dependencies with mock versions
    lazy var urlSession : URLSession = { URLSession(configuration: .default) }()
    lazy var imageFetcher : ImageFetcher = { ImageFetcher(urlSession: urlSession) }()
    lazy var modelFetcher : ModelFetcher = { ModelFetcher(urlSession: urlSession) }()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        guard let collectionView = collectionView else { preconditionFailure("failed to load collection view from storyboard") }

        collectionView.register(GifCell.self, forCellWithReuseIdentifier: "GifCell")

        diffableDataSource = UICollectionViewDiffableDataSource<ModelFetcher.Sections, GifSearchResponse.SearchResult>(collectionView: collectionView) { [weak self] (cv, indexPath, model) -> UICollectionViewCell? in
            guard let self = self else { return nil }

            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "GifCell", for: indexPath) as? GifCell else { preconditionFailure("got the wrong cell class from the collection view") }

            cell.apply(model: model, imageFetcher: self.imageFetcher)
            return cell
        }
        collectionView.dataSource = diffableDataSource
    }

    func search(for text : String)
    {
        searchTask?.cancel()

        searchTask = modelFetcher.fetchModel(searchText: text, handler: { [weak self] snapshot in
            self?.diffableDataSource?.apply(snapshot)
            self?.searchTask = nil
        })
    }

    func searchBarSearchButtonClicked(_ searchBar : UISearchBar)
    {
        searchBar.resignFirstResponder() // we already did the searching in textDidChange
    }

    func searchBar(_ searchBar : UISearchBar, textDidChange searchText : String)
    {
        // let's avoid firing network requests for the first couple characters
        // another idea is to include a delay waiting for another character to be typed
        // that would be a balancing act with perceived responsiveness and would require a bunch of testing to get right
        if searchText.count >= 3 {
            search(for: searchText)
        }
    }

    func collectionView(_ collectionView : UICollectionView, layout collectionViewLayout : UICollectionViewLayout, sizeForItemAt indexPath : IndexPath) -> CGSize
    {
        guard let itemModel = diffableDataSource?.itemIdentifier(for: indexPath) else { return .zero}

        let originalWidth = Int(itemModel.images.original.width)!
        let originalHeight = Int(itemModel.images.original.height)!
        let aspectRatio = CGFloat(originalHeight) / CGFloat(originalWidth)

        // this sizing method is quick and cheap but not terrible
        // full width on phones
        // 3 columsn on tablet portrait and 4 column on tablet landscape
        let boundsWidth = collectionView.bounds.width
        let displayWidth = traitCollection.horizontalSizeClass == .regular ? (boundsWidth / 3.1) : boundsWidth
        return CGSize(width: displayWidth, height: aspectRatio * displayWidth)
    }

    func collectionView(_ collectionView : UICollectionView, didSelectItemAt indexPath : IndexPath)
    {
        searchBar?.resignFirstResponder()
        guard let itemModel = diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        let fullScreenController = FullScreenGifViewController(model: itemModel.images.original, imageFetcher: imageFetcher)
        let navigationController = UINavigationController(rootViewController: fullScreenController)
        present(navigationController, animated: true)
    }

    func scrollViewDidScroll(_ scrollView : UIScrollView)
    {
        // if we scroll to the bottom, fetch more stuff

        guard let currentSnapshot = diffableDataSource?.snapshot(),
              let searchText = searchBar?.text,
              let collectionView = collectionView,
              searchTask == nil,
              currentSnapshot.numberOfItems > 0
        else { return }

        if collectionView.contentOffset.y >= collectionView.contentSize.height - collectionView.bounds.height {
            searchTask = modelFetcher.fetchModel(searchText: searchText, snapshot: currentSnapshot) { [weak self] snapshot in
                self?.diffableDataSource?.apply(snapshot)
                self?.searchTask = nil
            }
        }
    }

    func scrollViewWillBeginDragging(_ scrollView : UIScrollView)
    {
        searchBar?.resignFirstResponder()
    }
}

