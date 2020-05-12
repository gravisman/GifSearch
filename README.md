# GifSearch README

This project implements a basic view controller containing a `UICollectionView` which displays Gifs fetched from giphy.com in response to user input in the search bar. The collection view uses a basic `UICollectionViewFlowLayout` to achieve a single column layout on iPhone and multicolumn layout on iPad.

## Feature notes:

1. Network requests are async to enable smooth scrolling
2. Initially we fetch small still images to minimize perceived latency of the requests
3. "Infinite" scrolling is enabled by requesting more images from the server when scrolling to the bottom
4. Select a gif to view full screen and to access sharing options such as copy and save to camera roll
5. There is no caching. The memory model allows images to be deallocated once they're unused

## Future improvements to be implemented with more time:

1. Image pre-fetching and caching for off-screen cells
2. Full dependency injection for testability, including a mock data fetcher
3. Fancier UI

## Running:
Should build out of the box and run on iPhone or iPad simulator. I was lazy setting up the project and didn't do CocoaPods or anything, so included is only a simulator version of YYImage.framework that I built, so it's not setup to run on a device. If you want to run it on a device either just swap in a device version of that framework or shoot me a quick note and I can do it.

Enjoy.