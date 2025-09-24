//
//  ImageGallery.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/14/25.
//

import SwiftUI
import Kingfisher

struct ImageGallery: View {
    let imageURLs: [String]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.element) { index, url in
                        KFImage(URL(string: url))
                            .placeholder {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("sharkPrimaryColor")))
                                        .scaleEffect(1.5)
                                }
                            }
                            .onFailure { error in
                                print("갤러리 이미지 로드 실패: \(error)")
                            }
                            .fade(duration: 0.25)
                            .cacheOriginalImage()
                            .scaleFactor(UIScreen.main.scale)
                            .resizable()
                            .scaledToFill()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.width)
                .clipped()
                
                if imageURLs.count > 1 {
                    Text("\(currentIndex + 1)/\(imageURLs.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                }
            }
            
            if imageURLs.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<imageURLs.count, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color("sharkPrimaryColor") : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
    }
}

struct CustomAsyncImageView: View {
    let imageUrlString: String
    let localImage: UIImage?
    
    init(imageUrlString: String, localImage: UIImage? = nil) {
        self.imageUrlString = imageUrlString
        self.localImage = localImage
    }
    
    var body: some View {
        if let localImage = localImage {
            Image(uiImage: localImage)
                .resizable()
                .scaledToFill()
        } else {
            KFImage(URL(string: imageUrlString))
                .placeholder {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("sharkPrimaryColor")))
                        .scaleEffect(1.5)
                }
                .onFailure { error in
                    print("이미지 로드 실패: \(error.localizedDescription)")
                }
                .fade(duration: 0.25)
                .cacheOriginalImage()
                .scaleFactor(UIScreen.main.scale)
                .resizable()
                .scaledToFill()
        }
    }
}

struct RefreshableAsyncImageView: View {
    let imageUrlString: String
    let forceRefresh: Bool
    
    init(imageUrlString: String, forceRefresh: Bool = false) {
        self.imageUrlString = imageUrlString
        self.forceRefresh = forceRefresh
    }
    
    var body: some View {
        KFImage(URL(string: imageUrlString))
            .placeholder {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("sharkPrimaryColor")))
                    .scaleEffect(1.5)
            }
            .onFailure { error in
                print("이미지 로드 실패: \(error.localizedDescription)")
            }
            .setProcessor(forceRefresh ? DownsamplingImageProcessor(size: CGSize(width: 500, height: 500)) : DefaultImageProcessor.default)
            .loadDiskFileSynchronously()
            .fade(duration: 0.25)
            .forceRefresh(forceRefresh)
            .resizable()
            .scaledToFill()
    }
}
