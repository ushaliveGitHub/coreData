//
//  Pets+CoreDataProperties.swift
//  PetPal
//
//  Created by Usha Natarajan on 9/23/18.
//  Copyright © 2018 Razeware. All rights reserved.
//
//

import Foundation
import CoreData


extension Pets {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pets> {
        return NSFetchRequest<Pets>(entityName: "Pets")
    }

    @NSManaged public var name: String?
    @NSManaged public var kind: String?
    @NSManaged public var picture: NSData?
    @NSManaged public var dob: NSDate?
    @NSManaged public var owner: Friend

}
