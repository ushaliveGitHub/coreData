//
//  Friend+CoreDataProperties.swift
//  PetPal
//
//  Created by Usha Natarajan on 9/23/18.
//  Copyright © 2018 Razeware. All rights reserved.
//
//

import Foundation
import CoreData


extension Friend {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Friend> {
        return NSFetchRequest<Friend>(entityName: "Friend")
    }

    @NSManaged public var address: String?
    @NSManaged public var dob: NSDate?
    @NSManaged public var eyeColor: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var picture: NSData?
    @NSManaged public var pets: NSSet?

}

// MARK: Generated accessors for pets
extension Friend {

    @objc(addPetsObject:)
    @NSManaged public func addToPets(_ value: Pets)

    @objc(removePetsObject:)
    @NSManaged public func removeFromPets(_ value: Pets)

    @objc(addPets:)
    @NSManaged public func addToPets(_ values: NSSet)

    @objc(removePets:)
    @NSManaged public func removeFromPets(_ values: NSSet)

}
