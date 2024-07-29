//
//  DataController.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "PlacesDataModel")
    
    init() {
        container.loadPersistentStores(completionHandler: {description, error in
            if let error = error {
                print("Core Data failed to load \(error.localizedDescription)")
            }
        })
    }
}
