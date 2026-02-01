import Foundation

/// Mock Strava API responses for development and testing
enum MockStravaData {

    // MARK: - Athletes

    static let athletes: [StravaAthleteProfile] = [
        StravaAthleteProfile(
            id: 12345678,
            firstName: "James",
            lastName: "Wilson",
            profileImageURL: URL(string: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/12345678/large.jpg"),
            city: "London",
            country: "United Kingdom",
            sex: "M",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15))
        ),
        StravaAthleteProfile(
            id: 23456789,
            firstName: "Emma",
            lastName: "Thompson",
            profileImageURL: URL(string: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/23456789/large.jpg"),
            city: "Manchester",
            country: "United Kingdom",
            sex: "F",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1998, month: 7, day: 22))
        ),
        StravaAthleteProfile(
            id: 34567890,
            firstName: "Oliver",
            lastName: "Brown",
            profileImageURL: URL(string: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/34567890/large.jpg"),
            city: "Bristol",
            country: "United Kingdom",
            sex: "M",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1988, month: 11, day: 8))
        ),
        StravaAthleteProfile(
            id: 45678901,
            firstName: "Sophie",
            lastName: "Davies",
            profileImageURL: nil,
            city: "Edinburgh",
            country: "United Kingdom",
            sex: "F",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 2007, month: 5, day: 30))
        ),
        StravaAthleteProfile(
            id: 56789012,
            firstName: "William",
            lastName: "Taylor",
            profileImageURL: URL(string: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/56789012/large.jpg"),
            city: "Cardiff",
            country: "United Kingdom",
            sex: "M",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1985, month: 9, day: 12))
        )
    ]

    // MARK: - Strava Activities (Raw API Format)

    static let stravaActivities: [StravaActivity] = [
        // James Wilson's activities
        StravaActivity(
            id: 10000001,
            name: "Morning Thames Paddle",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-3600 * 4),
            startDateLocal: Date().addingTimeInterval(-3600 * 4),
            elapsedTime: 3845,
            movingTime: 3602,
            distance: 8750.5,
            maxSpeed: 4.8,
            averageSpeed: 2.43,
            startLatlng: [51.4615, -0.3015],
            endLatlng: [51.4812, -0.2734],
            map: StravaMap(
                id: "a10000001",
                polyline: "_{p~Fz`kM_@wBs@cDg@}Bi@wBk@_Ce@}Bo@kCw@aDm@kCi@}Bc@iBa@{Ac@_Bg@sBi@sB",
                summaryPolyline: "_{p~Fz`kM_@wBs@cDg@}Bi@wBk@_Ce@}Bo@kC"
            )
        ),
        StravaActivity(
            id: 10000002,
            name: "Evening Sprint Session - River Lea",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 - 3600 * 2),
            startDateLocal: Date().addingTimeInterval(-86400 - 3600 * 2),
            elapsedTime: 2456,
            movingTime: 2312,
            distance: 5890.2,
            maxSpeed: 5.2,
            averageSpeed: 2.55,
            startLatlng: [51.5742, -0.0356],
            endLatlng: [51.5621, -0.0412],
            map: StravaMap(
                id: "a10000002",
                polyline: "k~q~Fj_iMh@vBd@~Ab@|Af@~Ad@xAb@rAh@~Aj@dBl@hBj@~An@fB",
                summaryPolyline: "k~q~Fj_iMh@vBd@~Ab@|Af@~Ad@xA"
            )
        ),
        StravaActivity(
            id: 10000003,
            name: "Long Distance Challenge - Grand Union Canal",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-86400 * 2),
            startDateLocal: Date().addingTimeInterval(-86400 * 2),
            elapsedTime: 10845,
            movingTime: 9876,
            distance: 25420.8,
            maxSpeed: 4.1,
            averageSpeed: 2.57,
            startLatlng: [51.5312, -0.4521],
            endLatlng: [51.6234, -0.5012],
            map: StravaMap(
                id: "a10000003",
                polyline: "crp~Ff~rMw@cDu@cDq@aDo@_Dm@aDk@cDi@cDg@cDe@cDc@cDa@cD",
                summaryPolyline: "crp~Ff~rMw@cDu@cDq@aDo@_Dm@aD"
            )
        ),

        // Emma Thompson's activities
        StravaActivity(
            id: 10000004,
            name: "Salford Quays Training",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-3600 * 8),
            startDateLocal: Date().addingTimeInterval(-3600 * 8),
            elapsedTime: 4512,
            movingTime: 4234,
            distance: 9876.3,
            maxSpeed: 4.5,
            averageSpeed: 2.33,
            startLatlng: [53.4712, -2.2876],
            endLatlng: [53.4621, -2.2654],
            map: StravaMap(
                id: "a10000004",
                polyline: "mfufMlwdNa@wBc@yBe@{Bg@}Bi@_Ck@aCm@cCo@eCq@gC",
                summaryPolyline: "mfufMlwdNa@wBc@yBe@{Bg@}B"
            )
        ),
        StravaActivity(
            id: 10000005,
            name: "Manchester Ship Canal Sprint",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 * 3),
            startDateLocal: Date().addingTimeInterval(-86400 * 3),
            elapsedTime: 1876,
            movingTime: 1756,
            distance: 4521.7,
            maxSpeed: 5.8,
            averageSpeed: 2.58,
            startLatlng: [53.4534, -2.3012],
            endLatlng: [53.4612, -2.2876],
            map: StravaMap(
                id: "a10000005",
                polyline: "cautMxedNm@cCk@aCi@_Cg@}Be@{Bc@yBa@wB_@uB",
                summaryPolyline: "cautMxedNm@cCk@aCi@_Cg@}B"
            )
        ),

        // Oliver Brown's activities
        StravaActivity(
            id: 10000006,
            name: "Avon Gorge Challenge",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-86400),
            startDateLocal: Date().addingTimeInterval(-86400),
            elapsedTime: 5234,
            movingTime: 4876,
            distance: 12340.5,
            maxSpeed: 5.1,
            averageSpeed: 2.53,
            startLatlng: [51.4534, -2.6234],
            endLatlng: [51.4712, -2.5876],
            map: StravaMap(
                id: "a10000006",
                polyline: "i~n~F`gcLq@aDo@cDm@aDk@cDi@cDg@cDe@cDc@cD",
                summaryPolyline: "i~n~F`gcLq@aDo@cDm@aDk@cD"
            )
        ),
        StravaActivity(
            id: 10000007,
            name: "Bristol Harbour Loop",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 * 4),
            startDateLocal: Date().addingTimeInterval(-86400 * 4),
            elapsedTime: 3654,
            movingTime: 3412,
            distance: 7865.2,
            maxSpeed: 4.3,
            averageSpeed: 2.30,
            startLatlng: [51.4498, -2.5987],
            endLatlng: [51.4498, -2.5987],
            map: StravaMap(
                id: "a10000007",
                polyline: "kwn~FvxbLa@yBc@{Be@}Bg@_Ci@aCk@cCm@eCo@gC",
                summaryPolyline: "kwn~FvxbLa@yBc@{Be@}Bg@_C"
            )
        ),

        // Sophie Davies's activities (Junior)
        StravaActivity(
            id: 10000008,
            name: "Edinburgh Canal Practice",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-3600 * 6),
            startDateLocal: Date().addingTimeInterval(-3600 * 6),
            elapsedTime: 2134,
            movingTime: 1987,
            distance: 4532.1,
            maxSpeed: 4.0,
            averageSpeed: 2.28,
            startLatlng: [55.9521, -3.1876],
            endLatlng: [55.9612, -3.1654],
            map: StravaMap(
                id: "a10000008",
                polyline: "s`}gIrwfWe@{Bc@yBa@wB_@uB]sB[qBYoBWmB",
                summaryPolyline: "s`}gIrwfWe@{Bc@yBa@wB_@uB"
            )
        ),
        StravaActivity(
            id: 10000009,
            name: "Junior Club Session - Water of Leith",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 * 2 - 3600 * 3),
            startDateLocal: Date().addingTimeInterval(-86400 * 2 - 3600 * 3),
            elapsedTime: 1876,
            movingTime: 1723,
            distance: 3876.4,
            maxSpeed: 3.8,
            averageSpeed: 2.25,
            startLatlng: [55.9423, -3.2134],
            endLatlng: [55.9512, -3.1987],
            map: StravaMap(
                id: "a10000009",
                polyline: "ex|gIbbgWg@}Bi@_Ck@aCm@cCo@eCq@gCs@iC",
                summaryPolyline: "ex|gIbbgWg@}Bi@_Ck@aCm@cC"
            )
        ),

        // William Taylor's activities (Masters)
        StravaActivity(
            id: 10000010,
            name: "Cardiff Bay Morning Paddle",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-3600 * 5),
            startDateLocal: Date().addingTimeInterval(-3600 * 5),
            elapsedTime: 4234,
            movingTime: 3945,
            distance: 9234.6,
            maxSpeed: 4.6,
            averageSpeed: 2.34,
            startLatlng: [51.4612, -3.1654],
            endLatlng: [51.4534, -3.1432],
            map: StravaMap(
                id: "a10000010",
                polyline: "gmn~FhijKi@_Ck@aCm@cCo@eCq@gCs@iCu@kCw@mC",
                summaryPolyline: "gmn~FhijKi@_Ck@aCm@cCo@eC"
            )
        ),
        StravaActivity(
            id: 10000011,
            name: "Taff Trail Endurance",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 * 5),
            startDateLocal: Date().addingTimeInterval(-86400 * 5),
            elapsedTime: 7654,
            movingTime: 7123,
            distance: 16543.2,
            maxSpeed: 4.2,
            averageSpeed: 2.32,
            startLatlng: [51.4823, -3.1789],
            endLatlng: [51.5234, -3.2012],
            map: StravaMap(
                id: "a10000011",
                polyline: "qun~FxpjKu@kCs@iCq@gCo@eCm@cCk@aCi@_Cg@}B",
                summaryPolyline: "qun~FxpjKu@kCs@iCq@gCo@eC"
            )
        ),

        // Additional activities for variety
        StravaActivity(
            id: 10000012,
            name: "River Wye Speed Test",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-86400 * 6),
            startDateLocal: Date().addingTimeInterval(-86400 * 6),
            elapsedTime: 1234,
            movingTime: 1156,
            distance: 3210.5,
            maxSpeed: 6.2,
            averageSpeed: 2.78,
            startLatlng: [51.8412, -2.7234],
            endLatlng: [51.8534, -2.7012],
            map: StravaMap(
                id: "a10000012",
                polyline: "eqs~F`odLw@mCy@oC{@qC}@sC_AuCaAwC",
                summaryPolyline: "eqs~F`odLw@mCy@oC{@qC"
            )
        ),
        StravaActivity(
            id: 10000013,
            name: "Lake Windermere Crossing",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-86400 * 7),
            startDateLocal: Date().addingTimeInterval(-86400 * 7),
            elapsedTime: 8765,
            movingTime: 8234,
            distance: 18765.3,
            maxSpeed: 4.0,
            averageSpeed: 2.28,
            startLatlng: [54.3612, -2.9234],
            endLatlng: [54.4234, -2.9012],
            map: StravaMap(
                id: "a10000013",
                polyline: "wc~eMrqhNo@eCq@gCs@iCu@kCw@mCy@oC{@qC",
                summaryPolyline: "wc~eMrqhNo@eCq@gCs@iCu@kC"
            )
        ),
        StravaActivity(
            id: 10000014,
            name: "Norfolk Broads Explorer",
            type: "Canoeing",
            sportType: "Canoeing",
            startDate: Date().addingTimeInterval(-86400 * 8),
            startDateLocal: Date().addingTimeInterval(-86400 * 8),
            elapsedTime: 12456,
            movingTime: 11234,
            distance: 28765.8,
            maxSpeed: 3.9,
            averageSpeed: 2.56,
            startLatlng: [52.6234, 1.5432],
            endLatlng: [52.6876, 1.5987],
            map: StravaMap(
                id: "a10000014",
                polyline: "gfhbIo}~Aa@wBc@yBe@{Bg@}Bi@_Ck@aC",
                summaryPolyline: "gfhbIo}~Aa@wBc@yBe@{Bg@}B"
            )
        ),
        StravaActivity(
            id: 10000015,
            name: "River Cam Sprint",
            type: "Kayaking",
            sportType: "Kayaking",
            startDate: Date().addingTimeInterval(-86400 * 9),
            startDateLocal: Date().addingTimeInterval(-86400 * 9),
            elapsedTime: 1567,
            movingTime: 1432,
            distance: 3654.2,
            maxSpeed: 5.5,
            averageSpeed: 2.55,
            startLatlng: [52.2012, 0.1234],
            endLatlng: [52.2134, 0.1356],
            map: StravaMap(
                id: "a10000015",
                polyline: "kv`bIqb}@m@cCo@eCq@gCs@iCu@kC",
                summaryPolyline: "kv`bIqb}@m@cCo@eCq@gC"
            )
        )
    ]

    // MARK: - Token Responses

    static let tokenResponse = StravaTokenResponse(
        tokenType: "Bearer",
        expiresAt: Int(Date().addingTimeInterval(21600).timeIntervalSince1970),
        expiresIn: 21600,
        refreshToken: "mock_refresh_token_abc123xyz789",
        accessToken: "mock_access_token_def456uvw012",
        athlete: StravaAthleteResponse(
            id: 12345678,
            firstname: "James",
            lastname: "Wilson",
            profile: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/12345678/large.jpg",
            city: "London",
            country: "United Kingdom",
            sex: "M"
        )
    )

    // MARK: - Converted App Activities

    static func convertToAppActivities() -> [Activity] {
        stravaActivities.enumerated().map { index, stravaActivity in
            let userId = ["user-001", "user-002", "user-003", "user-004", "user-005"][index % 5]
            let activityType: ActivityType = stravaActivity.type == "Kayaking" ? .kayaking : .canoeing

            let startCoord: Coordinate? = stravaActivity.startLatlng.map {
                Coordinate(latitude: $0[0], longitude: $0[1])
            }
            let endCoord: Coordinate? = stravaActivity.endLatlng.map {
                Coordinate(latitude: $0[0], longitude: $0[1])
            }

            return Activity(
                id: "activity-\(stravaActivity.id)",
                stravaId: stravaActivity.id,
                userId: userId,
                name: stravaActivity.name,
                activityType: activityType,
                startDate: stravaActivity.startDate,
                elapsedTime: TimeInterval(stravaActivity.elapsedTime),
                movingTime: TimeInterval(stravaActivity.movingTime),
                distance: stravaActivity.distance,
                maxSpeed: stravaActivity.maxSpeed,
                averageSpeed: stravaActivity.averageSpeed,
                startLocation: startCoord,
                endLocation: endCoord,
                polyline: stravaActivity.map?.summaryPolyline,
                isGPSVerified: true,
                isUKActivity: true,
                flagCount: index == 5 ? 2 : 0,
                status: .verified,
                importedAt: stravaActivity.startDate.addingTimeInterval(3600)
            )
        }
    }

    // MARK: - Segment Efforts (for fastest 1km/5km)

    static let segmentEfforts: [StravaSegmentEffort] = [
        StravaSegmentEffort(
            id: 1001,
            name: "Thames 1km Sprint Section",
            elapsedTime: 234,
            movingTime: 228,
            distance: 1000
        ),
        StravaSegmentEffort(
            id: 1002,
            name: "Grand Union 5km Challenge",
            elapsedTime: 1156,
            movingTime: 1123,
            distance: 5000
        ),
        StravaSegmentEffort(
            id: 1003,
            name: "Salford Quays 1km",
            elapsedTime: 245,
            movingTime: 238,
            distance: 1000
        ),
        StravaSegmentEffort(
            id: 1004,
            name: "Bristol Harbour 5km Loop",
            elapsedTime: 1234,
            movingTime: 1198,
            distance: 5000
        ),
        StravaSegmentEffort(
            id: 1005,
            name: "Cardiff Bay 1km Sprint",
            elapsedTime: 223,
            movingTime: 218,
            distance: 1000
        )
    ]
}

// MARK: - Mock Service Extension

extension StravaService {
    /// Returns mock data instead of making API calls (for development)
    static func mockFetchActivities() -> [StravaActivity] {
        MockStravaData.stravaActivities
    }

    static func mockFetchAthlete() -> StravaAthleteProfile {
        MockStravaData.athletes[0]
    }

    static func mockTokenResponse() -> StravaTokenResponse {
        MockStravaData.tokenResponse
    }
}
