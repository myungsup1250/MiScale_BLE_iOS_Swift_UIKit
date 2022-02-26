//
//  PeripheralDataTableViewCell.swift
//  KittyDocBLEUIKit
//
//  Created by 곽명섭 on 2021/01/23.
//

import UIKit

class PeripheralDataTableViewCell: UITableViewCell {
    var deviceImg: UIImageView!
    var deviceName: UILabel!
    var rssiLabel: UILabel!
    var deviceUUID: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        initUIViews()
        addSubviews()
        prepareForAutoLayout()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initUIViews() {
        deviceImg = UIImageView()
        deviceName = UILabel()
        rssiLabel = UILabel()
        deviceUUID = UILabel()
    }

    func addSubviews() {
        contentView.addSubview(makeDeviceImg())
        contentView.addSubview(makeDeviceName())
        contentView.addSubview(makeRssiLabel())
        contentView.addSubview(makeDeviceUUID())
    }
    
    func makeDeviceImg() -> UIImageView {
//        deviceImg = UIImageView()
        deviceImg.image = UIImage(imageLiteralResourceName: "PuppyDocImage")
        deviceImg.clipsToBounds = true
        deviceImg.contentMode = .scaleAspectFit
//        deviceImg.backgroundColor = .systemBlue
//        deviceImg.layer.cornerRadius = 8

        return deviceImg
    }

    func makeDeviceName() -> UILabel {
//        deviceImg = UILabel()

        deviceName.text = "deviceName"
//        deviceName.textColor = .black
//        deviceName.backgroundColor = .white
        return deviceName
    }

    func makeRssiLabel() -> UILabel {
//        rssiLabel = UILabel()

        rssiLabel.text = "rssiLabel"
        rssiLabel.font = rssiLabel.font.withSize(15)
//        rssiLabel.textColor = .black
//        rssiLabel.backgroundColor = .white
        return rssiLabel
    }

    func makeDeviceUUID() -> UILabel {
//        deviceUUID = UILabel()

        deviceUUID.text = "macAddress"
        deviceUUID.font = deviceUUID.font.withSize(12)
//        deviceUUID.textColor = .black
//        deviceUUID.backgroundColor = .white
        return deviceUUID
    }
    
    func prepareForAutoLayout() {
        deviceImg.translatesAutoresizingMaskIntoConstraints = false
        deviceName.translatesAutoresizingMaskIntoConstraints = false
        rssiLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceUUID.translatesAutoresizingMaskIntoConstraints = false
    }
        
    func setConstraints() {
        deviceImg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5)
            .isActive = true
        deviceImg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5)
            .isActive = true
        deviceImg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
            .isActive = true
        deviceImg.centerXAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30)
            .isActive = true
        deviceImg.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            .isActive = true
        
        deviceName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5)
            .isActive = true
        deviceName.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            .isActive = true
        deviceName.heightAnchor.constraint(equalToConstant: 20)
            .isActive = true
//        deviceImg.widthAnchor.constraint(equalToConstant: 20)
//            .isActive = true

        rssiLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5)
            .isActive = true
        rssiLabel.heightAnchor.constraint(equalToConstant: 20)
            .isActive = true
        rssiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            .isActive = true
//        rssiLabel.leadingAnchor.constraint(equalTo: deviceName.trailingAnchor, constant: 15)
//            .isActive = true
//        rssiLabel.widthAnchor.constraint(equalToConstant: 30)
//            .isActive = true

        deviceUUID.topAnchor.constraint(equalTo: deviceName.bottomAnchor, constant: 5)
            .isActive = true
//        macAddress.leadingAnchor.constraint(equalTo: deviceImg.trailingAnchor, constant: 50)
//            .isActive = true
        deviceUUID.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            .isActive = true
        deviceUUID.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
            .isActive = true
        deviceUUID.heightAnchor.constraint(equalToConstant: 20)
            .isActive = true
//        macAddress.widthAnchor.constraint(equalToConstant: 200)
//            .isActive = true
    }
    
    func setTableViewCell(peripheralData: PeripheralData) {
        guard peripheralData.peripheral != nil else {
            print("peripheralData.peripheral == nil!(setTableViewCell)")
            return
        }
        self.deviceImg.image = UIImage(imageLiteralResourceName: "PuppyDocImage")
        self.deviceName.text = peripheralData.peripheral!.name
        self.deviceUUID.text = peripheralData.peripheral!.identifier.uuidString // uuid?
        //print("peripheral.description : \(peripheralData.peripheral!.description)")
        self.rssiLabel.text = String(peripheralData.rssi) + "dbm"
    }
}
