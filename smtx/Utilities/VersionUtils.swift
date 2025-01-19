import Foundation

class VersionUtils {
    static func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
        // 确保都是有效的版本号格式
        guard components1.count == 2, components2.count == 2 else {
            return .orderedSame // 如果格式无效，认为版本相同
        }
        
        // 先比较主版本号
        if components1[0] != components2[0] {
            return components1[0] > components2[0] ? .orderedDescending : .orderedAscending
        }
        
        // 主版本号相同，比较次版本号
        if components1[1] != components2[1] {
            return components1[1] > components2[1] ? .orderedDescending : .orderedAscending
        }
        
        return .orderedSame
    }
} 