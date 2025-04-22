import Foundation
import CoreData

@objc(ReadingSessionEntity)
public class ReadingSessionEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var bookId: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: Int32
}

extension ReadingSessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingSessionEntity> {
        return NSFetchRequest<ReadingSessionEntity>(entityName: "ReadingSessionEntity")
    }
} 