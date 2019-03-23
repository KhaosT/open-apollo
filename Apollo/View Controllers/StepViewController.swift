//
//  StepViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class StepViewController: BaseViewController {

    private(set) lazy var heroImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 60, weight: .bold)
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private(set) lazy var descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

// MARK: - Setup

extension StepViewController {
    
    private func setupView() {
        setupTitleLabel()
        setupDescriptionLabel()
        setupHeroImageView()
    }
    
    private func setupTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
            ]
        )
    }
    
    private func setupDescriptionLabel() {
        view.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ]
        )
    }
    
    private func setupHeroImageView() {
        view.addSubview(heroImageView)
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let layoutGuide = UILayoutGuide()
        view.addLayoutGuide(layoutGuide)
        
        NSLayoutConstraint.activate(
            [
                layoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                layoutGuide.bottomAnchor.constraint(equalTo: titleLabel.topAnchor),
                heroImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                heroImageView.centerYAnchor.constraint(equalTo: layoutGuide.centerYAnchor),
                heroImageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.2)
            ]
        )
    }
}
