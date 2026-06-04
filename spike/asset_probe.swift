// AssetInventory 예약 API 탐침
import Foundation
import Speech

let sem = DispatchSemaphore(value: 0)
Task {
    let r = await AssetInventory.reservedLocales
    print("reservedLocales: \(r.map { $0.identifier(.bcp47) })")
    let locale = Locale(identifier: "ko-KR")
    do {
        let status = try await AssetInventory.reserve(locale: locale)
        print("reserve(locale:) → \(status)")
    } catch {
        print("reserve err: \(error)")
    }
    print("이후 reservedLocales: \(await AssetInventory.reservedLocales.map { $0.identifier(.bcp47) })")
    sem.signal()
}
_ = sem.wait(timeout: .now() + 30)
