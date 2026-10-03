//
//  AppSettings.swift
//  PcComponentIA
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {

    @Published var modoTaller: Bool {
        didSet {
            UserDefaults.standard.set(
                modoTaller,
                forKey: "modoTaller"
            )
        }
    }

    init() {
        if UserDefaults.standard.object(
            forKey: "modoTaller"
        ) == nil {
            modoTaller = true
        } else {
            modoTaller = UserDefaults.standard.bool(
                forKey: "modoTaller"
            )
        }
    }

    var esquemaColor: ColorScheme {
        modoTaller ? .dark : .light
    }

    func alternarTema() {
        modoTaller.toggle()
    }
}
