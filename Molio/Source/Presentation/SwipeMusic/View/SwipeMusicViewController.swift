import UIKit
import Combine

final class SwipeMusicViewController: UIViewController {
    private let viewModel = SwipeMusicViewModel()
    private var cancellables = Set<AnyCancellable>()

    let basicBackgroundColor = UIColor(resource: .background)
    
    private let playlistSelectButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.backgroundColor = .black.withAlphaComponent(0.3)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let selectedPlaylistTitleLabel: UILabel = {
        let label = UILabel()
        label.molioMedium(text: "🎧카공할 때 듣는 플리", size: 16) // TODO: 서버 연결시 text 제거
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playlistSelectArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.image = UIImage(systemName: "chevron.down")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let musicTrackView = MusicTrackView()
    
    private let filterButton = CircleMenuButton(backgroundColor: .black.withAlphaComponent(0.2),
                                                buttonSize: 58.0,
                                                tintColor: .white,
                                                buttonImage: UIImage(systemName: "slider.horizontal.3"),
                                                buttonImageSize: (21.0, 19.0))
    
    private let dislikeButton = CircleMenuButton(backgroundColor: .black.withAlphaComponent(0.2),
                                                 buttonSize: 66.0,
                                                 tintColor: UIColor(hex: "#FF3D3D"),
                                                 buttonImage: UIImage(systemName: "xmark"),
                                                 buttonImageSize: (25.0, 29.0))
    
    private let likeButton = CircleMenuButton(backgroundColor: .black.withAlphaComponent(0.2),
                                              buttonSize: 66.0,
                                              tintColor: UIColor(resource: .main),
                                              buttonImage: UIImage(systemName: "heart.fill"),
                                              buttonImageSize: (30.0, 29.0))
    
    private let myMolioButton = CircleMenuButton(backgroundColor: .black.withAlphaComponent(0.2),
                                                 buttonSize: 58.0,
                                                 tintColor: UIColor(hex: "#FFFAFA"),
                                                 buttonImage: UIImage(systemName: "music.note"),
                                                 buttonImageSize: (18.0, 24.0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = basicBackgroundColor // TODO: 앨범의 배경색으로 지정된 이후 삭제
        setupSelectPlaylistView()
        setupMusicTrackView()
        setupMenuButtonView()
        
        setupBindings()
        viewModel.fetchMusic()
        
        addPanGestureToMusicTrack()
    }
    
    private func setupBindings() {
        viewModel.$music
            .receive(on: RunLoop.main)
            .sink { [weak self] music in
                self?.setupBackgroundColor(by: music?.artwork?.backgroundColor)
            }
            .store(in: &cancellables)
    }
    
    private func setupBackgroundColor(by cgColor: CGColor?) {
        view.backgroundColor = cgColor.map(UIColor.init(cgColor:)) ?? basicBackgroundColor
    }
    
    private func addPanGestureToMusicTrack() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        musicTrackView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        card.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
                
        if gesture.state == .ended {
            // 스와이프 임계값 : 카드를 특정 거리 이상 스와이프되었는지를 확인한다.
            let swipeThreshold: CGFloat = 200
            
            // X축으로 이동한 거리가 스와이프 임계값을 넘은 경우
            if abs(translation.x) > swipeThreshold {
                let direction: CGFloat = translation.x > 0 ? 1 : -1 // 좌우 판단
                // 화면 밖으로 이동하는 애니메이션
                UIView.animate(withDuration: 0.3, animations: {
                    card.center = CGPoint(x: card.center.x + direction * self.view.frame.width, y: card.center.y)
                }) { _ in
                    // 애니메이션 이후 카드 제거 및 새로운 카드 설정
                    card.removeFromSuperview()
                    self.setupMusicTrackView()
                }
            } else {
                // 다시 원래 자리로 되돌린다.
                UIView.animate(withDuration: 0.3) {
                    card.center = self.view.center
                    card.transform = .identity
                }
            }
        }
    }
    
    private func setupSelectPlaylistView() {
        view.addSubview(playlistSelectButton)
        view.addSubview(selectedPlaylistTitleLabel)
        view.addSubview(playlistSelectArrowImageView)
        
        NSLayoutConstraint.activate([
            playlistSelectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            playlistSelectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playlistSelectButton.widthAnchor.constraint(equalToConstant: 192),
            playlistSelectButton.heightAnchor.constraint(equalToConstant: 39)
        ])
        
        NSLayoutConstraint.activate([
            selectedPlaylistTitleLabel.leadingAnchor.constraint(
                equalTo: playlistSelectButton.leadingAnchor, constant: 15),
            selectedPlaylistTitleLabel.centerYAnchor.constraint(equalTo: playlistSelectButton.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            playlistSelectArrowImageView.leadingAnchor.constraint(
                equalTo: selectedPlaylistTitleLabel.trailingAnchor, constant: 10),
            playlistSelectArrowImageView.trailingAnchor.constraint(
                equalTo: playlistSelectButton.trailingAnchor, constant: -15),
            playlistSelectArrowImageView.centerYAnchor.constraint(equalTo: playlistSelectButton.centerYAnchor),
            playlistSelectArrowImageView.widthAnchor.constraint(equalToConstant: 18),
            playlistSelectArrowImageView.heightAnchor.constraint(equalToConstant: 19)
        ])
    }
    
    private func setupMusicTrackView() {
        view.addSubview(musicTrackView)
        
        NSLayoutConstraint.activate([
            musicTrackView.topAnchor.constraint(equalTo: playlistSelectButton.bottomAnchor, constant: 12),
            musicTrackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            musicTrackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            musicTrackView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -107)
        ])
    }
    
    private func setupMenuButtonView() {
        view.addSubview(menuStackView)
        menuStackView.addArrangedSubview(filterButton)
        menuStackView.addArrangedSubview(dislikeButton)
        menuStackView.addArrangedSubview(likeButton)
        menuStackView.addArrangedSubview(myMolioButton)
        
        NSLayoutConstraint.activate([
            menuStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            menuStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22)
        ])
    }
}

// SwiftUI에서 SwipeViewController 미리보기
import SwiftUI
struct SwipeViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeMusicViewController {
        return SwipeMusicViewController()
    }
    
    func updateUIViewController(_ uiViewController: SwipeMusicViewController, context: Context) {
        
    }
}

struct SwipeViewController_Previews: PreviewProvider {
    static var previews: some View {
        SwipeViewControllerPreview()
            .edgesIgnoringSafeArea(.all)
    }
}