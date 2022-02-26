//
//  ViewController.swift
//  MiScaleBLEUiKit
//
//  Created by 곽명섭 on 2021/05/12.
//

import UIKit

class ViewController: UIViewController {

    var proceedBtn: UIButton!// = nil = UIButton()
    var guideLabel: UILabel!// = nil = UILabel()
    var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
    var deviceManager = MiScaleManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.traitCollection.userInterfaceStyle == .light {
            userInterfaceStyle = .light
        } else if self.traitCollection.userInterfaceStyle == .dark {
            userInterfaceStyle = .dark
        } else {
            userInterfaceStyle = .unspecified
        }
        print("ViewController.viewDidLoad()")
        initUIViews()
        addSubviews()
        prepareForAutoLayout()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController.viewWillAppear()")
        if deviceManager.isConnected {
            print("\tAnd connected to KittyDoc!")
            // 배터리 레벨 등 화면에 보여주기?
//            DispatchQueue.background(delay: 0.1, background: nil) {
//                self.guideLabel.text = "Connected! Battery : " + String(self.deviceManager.batteryLevel)
//            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ViewController.viewWillDisappear()")
    }

    func initUIViews() {
        proceedBtn = UIButton()
        guideLabel = UILabel()
    }
    
    func addSubviews() {
        view.addSubview(makeProceedBtn())
        view.addSubview(makeGuideLabel())
    }

    func makeProceedBtn() -> UIButton {
//        proceedBtn = UIButton()

        proceedBtn.setTitle("Table View", for: .normal)
        if userInterfaceStyle == .light {
            proceedBtn.setTitleColor(.white, for: .highlighted)
            proceedBtn.backgroundColor = .systemBlue
        } else if userInterfaceStyle == .dark {
            proceedBtn.setTitleColor(.black, for: .highlighted)
            proceedBtn.backgroundColor = .systemBlue
        } else {
            proceedBtn.setTitleColor(.white, for: .highlighted)
            proceedBtn.backgroundColor = .systemBlue
        }
        proceedBtn.layer.cornerRadius = 8
        proceedBtn.addTarget(self, action: #selector((didTapProceed)), for: .touchUpInside)


        return proceedBtn
    }
    func makeGuideLabel() -> UILabel {
//        guideLabel = UILabel()

        guideLabel.text = "Touch to Proceed"
        if userInterfaceStyle == .light {
            guideLabel.textColor = .black
            guideLabel.backgroundColor = .white
        } else if userInterfaceStyle == .dark {
            guideLabel.textColor = .white
            guideLabel.backgroundColor = .black
        } else {
            guideLabel.textColor = .black
            guideLabel.backgroundColor = .white
        }
//        guideLabel.layer.cornerRadius = 8


        return guideLabel
    }
    
    func prepareForAutoLayout() {
        proceedBtn.translatesAutoresizingMaskIntoConstraints = false
        guideLabel.translatesAutoresizingMaskIntoConstraints = false

    }
        
    func setConstraints() {
        proceedBtn.centerXAnchor.constraint(equalTo:view.centerXAnchor)
            .isActive = true // 부모 뷰의 centerX를 proceedBtn의 centerX로...
        proceedBtn.centerYAnchor.constraint(equalTo:view.centerYAnchor)
            .isActive = true // 부모 뷰의 centerY를 proceedBtn의 centerY로...
        proceedBtn.heightAnchor.constraint(equalToConstant: 50)
            .isActive = true // proceedBtn의 높이를 50으로...
        proceedBtn.widthAnchor.constraint(equalToConstant: 200)
            .isActive = true // proceedBtn의 너비를 200으로...
        
        guideLabel.topAnchor.constraint(equalTo: proceedBtn.bottomAnchor, constant: 10)
            .isActive = true // proceedBtn의 bottomAnchor +10를 guideLabel의 topAnchor로...
        guideLabel.centerXAnchor.constraint(equalTo:view.centerXAnchor)
            .isActive = true // guideLabel의 centerX를 부모 뷰의 centerX로...
        guideLabel.heightAnchor.constraint(equalToConstant: 50)
            .isActive = true // guideLabel의 높이를 50으로...
    }

    @objc private func didTapProceed() {
        self.performSegue(withIdentifier: "TableViewSegue", sender: nil)
        print("self.performSegue(withIdentifier: \"TableViewSegue\", sender: nil)")
//        //let alert = UIAlertController(title: "Proceed?"
//        //    , message: "Do you really want to Proceed?"
//        //    , preferredStyle: .actionSheet)
//        let alert = UIAlertController(title: "Proceed?"
//            , message: "Do you really want to Proceed?"
//            , preferredStyle: .alert)
//
//        let confirm = UIAlertAction(title: "Confirm", style: .default) { (alert: UIAlertAction!) in
//            print("Confirmed")
//        }
//        let cancel = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) in
//            print("Canceled")
//        }
//        //let dest = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) in
//            //print("Canceled")
//        //}
//        alert.addAction(confirm)
//        alert.addAction(cancel)
//        //alert.addAction(dest)
//
//        present(alert, animated: true, completion: nil)
        
        //let tableView = self.storyboard!.instantiateViewController(identifier: "TableView")
        // modally
//        tableView.modalPresentationStyle = UIModalPresentationStyle.automatic
//        tableView.modalPresentationStyle = .formSheet
//        tableView.modalPresentationStyle = .pageSheet
//        tableView.modalPresentationStyle = .popover

        //fullscreen
//        tableView.modalPresentationStyle = UIModalPresentationStyle.currentContext
//        tableView.modalPresentationStyle = .custom
        //tableView.modalPresentationStyle = .fullScreen
//        tableView.modalPresentationStyle = .overCurrentContext
//        tableView.modalPresentationStyle = .overFullScreen

//        tableView.modalTransitionStyle = UIModalTransitionStyle.coverVertical
//        tableView.modalTransitionStyle = .crossDissolve
//        tableView.modalTransitionStyle = .flipHorizontal
//        tableView.modalTransitionStyle = .partialCurl
        //present(tableView, animated: true)
    }
    
}

