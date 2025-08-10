//
//  ViewController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit
import SwiftUI

class ViewController: SKBaseController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(cellWithClass: UITableViewCell.self)
        
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        tableView.backgroundColor = .random.lighten()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("navBar.height = \(navBar.height)")
        view.layoutIfNeeded()
    }
 
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PageType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self)
        let page = PageType.allCases[indexPath.row]
        cell.textLabel?.text = page.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let page = PageType.allCases[indexPath.row]
        RouterManager.shared.navigate(to: page, from: navigationController)
    }
    
    
}


