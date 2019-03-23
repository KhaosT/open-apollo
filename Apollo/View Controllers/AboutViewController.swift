//
//  AboutViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: BaseViewController {

    var sections: [ListableSection<ListableType>] = []
    
    private lazy var aboutTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.indicatorStyle = .white
        tableView.backgroundColor = Color.background
        tableView.separatorColor = Color.backgroundVibrant
        
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "Cell")

        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTapDoneButton))
        
        setupTableView()
        populateContent()
    }
    
    @objc
    private func didTapDoneButton() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension AboutViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionItem = sections[section]
        return sectionItem.associatedRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].associatedRows[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.title
        
        switch item.rowType {
        case .version:
            cell.detailTextLabel?.text = item.content as? String
            cell.accessoryType = .none
        case .developer:
            cell.detailTextLabel?.text = item.content as? String
            cell.accessoryType = .disclosureIndicator
        case .email:
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
        case .acknowledgements:
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        case .privacy:
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionItem = sections[section]
        return sectionItem.header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionItem = sections[section]
        return sectionItem.footer
    }
}

// MARK: - UITableViewDelegate

extension AboutViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let item = sections[indexPath.section].associatedRows[indexPath.row]
        
        switch item.rowType {
        case .version:
            return false
        case .acknowledgements,
             .developer,
             .privacy,
             .email:
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].associatedRows[indexPath.row]
        
        switch item.rowType {
        case .version:
            break
        case .developer:
            UIApplication.shared.open(URL(string: "https://twitter.com/KhaosT")!, options: [:], completionHandler: nil)
        case .email:
            presentEmailViewController()
        case .acknowledgements:
            presentAcknowledgementsViewController()
        case .privacy:
            presentPrivacyPolicyViewController()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Action

extension AboutViewController {
    
    private func presentEmailViewController() {
        guard MFMailComposeViewController.canSendMail() else {
            UIApplication.shared.open(URL(string: "mailto:feedback@awas.app?subject=Apollo%20Feedback")!, options: [:], completionHandler: nil)
            return
        }
        
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = self
        viewController.setToRecipients(["feedback@awas.app"])
        viewController.setSubject("Apollo Feedback")
        if let appVersion = self.appVersion {
            viewController.setMessageBody("\n\n======\nVersion: \(appVersion)", isHTML: false)
        }
        
        present(viewController, animated: true, completion: nil)
    }
    
    private func presentAcknowledgementsViewController() {
        guard let url = Bundle.main.url(forResource: "Acknowledgement", withExtension: "html") else {
            return
        }
        
        let viewController = WebViewController(url: url, title: "Acknowledgements")
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func presentPrivacyPolicyViewController() {
        guard let url = Bundle.main.url(forResource: "Privacy", withExtension: "html") else {
            return
        }
        
        let viewController = WebViewController(url: url, title: "Privacy Policy")
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension AboutViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Setup

extension AboutViewController {
    
    private func setupTableView() {
        view.addSubview(aboutTableView)
        aboutTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                aboutTableView.topAnchor.constraint(equalTo: view.topAnchor),
                aboutTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                aboutTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                aboutTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
    }
    
    private func populateContent() {
        
        // Version
        
        if let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            let versionSection = ListableSection<ListableType>()
            let versionRow = ListableRow<ListableType>(type: .version, title: "Version", cellIdentifier: "Cell", content: "\(shortVersion) (\(buildNumber))")
            versionSection.associatedRows.append(versionRow)
            sections.append(versionSection)
        }
        
        // Developer
        
        let developerSection = ListableSection<ListableType>()
        let developerRow = ListableRow<ListableType>(type: .developer, title: "Developer", cellIdentifier: "Cell", content: "@KhaosT")
        developerSection.associatedRows.append(developerRow)
        
        let emailRow = ListableRow<ListableType>(type: .email, title: "Submit Feedback", cellIdentifier: "Cell")
        developerSection.associatedRows.append(emailRow)
        
        developerSection.footer = "Since it's just me working on the app, I may not be able to respond to all the emails. Thanks for understanding."
        
        sections.append(developerSection)
        
        // Info
        
        let infoSection = ListableSection<ListableType>()
        
        let acknowledgementsRow = ListableRow<ListableType>(type: .acknowledgements, title: "Acknowledgements", cellIdentifier: "Cell")
        infoSection.associatedRows.append(acknowledgementsRow)
        
        let privacyRow = ListableRow<ListableType>(type: .privacy, title: "Privacy Policy", cellIdentifier: "Cell")
        infoSection.associatedRows.append(privacyRow)
        
        sections.append(infoSection)
    }
    
    private var appVersion: String? {
        if let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(shortVersion) (\(buildNumber))"
        } else {
            return nil
        }
    }
}

// MARK: - Content

extension AboutViewController {
    
    enum ListableType {
        case version
        case developer
        case email
        case acknowledgements
        case privacy
    }
}
