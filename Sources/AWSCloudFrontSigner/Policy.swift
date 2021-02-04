import Foundation

extension CookiesSigner {
    
    func makePolicy() -> Policy {
        var condition = Condition(
            dateLessThan: EpochTime(epochTime: Int(self.dateLessThan.timeIntervalSince1970))
        )
        
        if let dateGreaterThan = self.dateGreaterThan {
            condition.dateGreaterThan = EpochTime(epochTime: Int(dateGreaterThan.timeIntervalSince1970))
        }

        if let ipAddress = self.ipAddress {
            condition.ipAddress = SourceIp(sourceIp: ipAddress)
        }

        let statement = [Statement(resource: self.policyResource, condition: condition)]
        let policy = Policy(statement: statement)
        return policy
    }
}

struct Policy : Codable {
    var statement : [Statement]

    enum CodingKeys: String, CodingKey {
        case statement = "Statement"
    }
}

struct Statement : Codable {
    var resource : String
    var condition : Condition

    enum CodingKeys: String, CodingKey {
        case resource = "Resource"
        case condition = "Condition"
    }
}

struct Condition : Codable {
    var dateLessThan : EpochTime
    var dateGreaterThan : EpochTime?
    var ipAddress : SourceIp?

    enum CodingKeys: String, CodingKey {
        case dateLessThan = "DateLessThan"
        case dateGreaterThan = "DateGreaterThan"
        case ipAddress = "IpAddress"
    }
}

struct EpochTime : Codable {
    var epochTime : Int

    enum CodingKeys: String, CodingKey {
        case epochTime = "AWS:EpochTime"
    }
}

struct SourceIp : Codable {
    var sourceIp : String
    
    enum CodingKeys: String, CodingKey {
        case sourceIp = "AWS:SourceIp"
    }
}
