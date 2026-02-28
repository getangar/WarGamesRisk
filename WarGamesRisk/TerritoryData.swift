// TerritoryData.swift
// High-detail world map coastlines + 42 Risk territories
// Mercator projection: x 0..1 = 170°W→180°E, y 0..1 = 60°S→85°N

import SpriteKit

private func geo(_ lon: Double, _ lat: Double) -> CGPoint {
    CGPoint(x: (lon + 170.0) / 350.0, y: (lat + 60.0) / 145.0)
}

// MARK: - Territory Definitions

struct TerritoryDef {
    let id: Int; let name: String; let shortName: String
    let continent: String; let x: CGFloat; let y: CGFloat; let adjacentIDs: [Int]
}

let allTerritories: [TerritoryDef] = {
    func t(_ id: Int, _ n: String, _ s: String, _ c: String, _ lon: Double, _ lat: Double, _ a: [Int]) -> TerritoryDef {
        let p = geo(lon, lat); return TerritoryDef(id: id, name: n, shortName: s, continent: c, x: p.x, y: p.y, adjacentIDs: a)
    }
    return [
        t(0,  "Alaska",              "ALSK", "North America", -150, 63,  [1, 3, 37]),
        t(1,  "Northwest Territory",  "NWTR", "North America", -120, 67,  [0, 2, 3, 4]),
        t(2,  "Greenland",           "GRLD", "North America", -42,  72,  [1, 4, 5, 13]),
        t(3,  "Alberta",             "ALBT", "North America", -115, 55,  [0, 1, 4, 6]),
        t(4,  "Ontario",             "ONTR", "North America", -88,  52,  [1, 2, 3, 5, 6, 7]),
        t(5,  "Quebec",              "QUBC", "North America", -72,  52,  [2, 4, 7]),
        t(6,  "Western US",          "WUSA", "North America", -110, 40,  [3, 4, 7, 8]),
        t(7,  "Eastern US",          "EUSA", "North America", -82,  36,  [4, 5, 6, 8]),
        t(8,  "Central America",     "CAME", "North America", -95,  20,  [6, 7, 9]),
        t(9,  "Venezuela",   "VNZL", "South America", -67, 8,   [8, 10, 11]),
        t(10, "Brazil",      "BRZL", "South America", -50, -10, [9, 11, 12, 21]),
        t(11, "Peru",        "PERU", "South America", -75, -12, [9, 10, 12]),
        t(12, "Argentina",   "ARGN", "South America", -63, -35, [10, 11]),
        t(13, "Iceland",          "ICLD", "Europe",  -20, 65,  [2, 14, 15]),
        t(14, "Scandinavia",      "SCAN", "Europe",   15, 62,  [13, 15, 17, 19]),
        t(15, "Great Britain",    "GRBR", "Europe",   -3, 55,  [13, 14, 16, 17]),
        t(16, "Western Europe",   "WEUR", "Europe",    2, 46,  [15, 17, 18, 21]),
        t(17, "Northern Europe",  "NEUR", "Europe",   15, 52,  [14, 15, 16, 18, 19]),
        t(18, "Southern Europe",  "SEUR", "Europe",   18, 43,  [16, 17, 19, 21, 22, 35]),
        t(19, "Ukraine",          "UKRN", "Europe",   38, 52,  [14, 17, 18, 26, 35, 30]),
        t(20, "Madagascar",   "MDGS", "Africa",  47, -20, [23, 24]),
        t(21, "North Africa",  "NAFR", "Africa",   5, 25,  [10, 16, 18, 22, 23, 25]),
        t(22, "Egypt",         "EGPT", "Africa",  30, 27,  [18, 21, 23, 35]),
        t(23, "East Africa",   "EAFR", "Africa",  35, 0,   [20, 21, 22, 24, 25]),
        t(24, "South Africa",  "SAFR", "Africa",  25, -30, [20, 23, 25]),
        t(25, "Congo",         "CONG", "Africa",  20, -5,  [21, 23, 24]),
        t(26, "Ural",         "URAL", "Asia",  60, 60,   [19, 27, 30, 33]),
        t(27, "Siberia",      "SIBR", "Asia",  90, 65,   [26, 28, 29, 31, 33]),
        t(28, "Yakutsk",      "YAKT", "Asia", 130, 64,   [27, 29, 37]),
        t(29, "Irkutsk",      "IRKT", "Asia", 105, 55,   [27, 28, 31, 37]),
        t(30, "Afghanistan",  "AFGH", "Asia",  65, 35,   [19, 26, 33, 34, 35]),
        t(31, "Mongolia",     "MNGL", "Asia", 105, 47,   [27, 29, 33, 37]),
        t(32, "Japan",        "JAPN", "Asia", 138, 37,   [37]),
        t(33, "China",        "CHIN", "Asia",  98, 35,   [26, 27, 30, 31, 34, 36]),
        t(34, "India",        "INDA", "Asia",  78, 22,   [30, 33, 35, 36]),
        t(35, "Middle East",  "MDST", "Asia",  45, 30,   [18, 19, 22, 30, 34]),
        t(36, "Siam",         "SIAM", "Asia", 102, 15,   [33, 34, 38]),
        t(37, "Kamchatka",    "KMCH", "Asia", 160, 60,   [0, 28, 29, 31, 32]),
        t(38, "Indonesia",    "INDO", "Australia", 115, -3,  [36, 39, 40]),
        t(39, "New Guinea",   "NGUI", "Australia", 145, -5,  [38, 40, 41]),
        t(40, "W. Australia", "WAUS", "Australia", 125, -28, [38, 39, 41]),
        t(41, "E. Australia", "EAUS", "Australia", 148, -27, [39, 40]),
    ]
}()

// MARK: - Continent Outlines (high-detail coastlines)

struct ContinentOutline { let name: String; let paths: [[CGPoint]] }

let continentOutlines: [ContinentOutline] = [

    // ===================== NORTH AMERICA =====================
    ContinentOutline(name: "North America", paths: [
        [   // Main landmass
            geo(-168, 53), geo(-166, 54), geo(-164, 56), geo(-162, 58), geo(-160, 59),
            geo(-157, 58), geo(-155, 59), geo(-153, 60), geo(-151, 60), geo(-149, 61),
            geo(-147, 61), geo(-145, 60), geo(-143, 60), geo(-141, 59), geo(-139, 58),
            geo(-137, 57), geo(-136, 56), geo(-135, 55), geo(-134, 54), geo(-133, 54),
            geo(-132, 55), geo(-131, 56), geo(-130, 55), geo(-130, 53),
            geo(-129, 52), geo(-128, 51), geo(-127, 50), geo(-126, 49), geo(-125, 49),
            geo(-124, 48), geo(-124, 47), geo(-124, 46), geo(-124, 44),
            geo(-124, 43), geo(-123, 42), geo(-123, 40), geo(-122, 39),
            geo(-121, 37), geo(-120, 36), geo(-119, 35), geo(-118, 34), geo(-117, 33),
            geo(-117, 32), geo(-116, 31), geo(-115, 30), geo(-114, 29),
            geo(-113, 28), geo(-112, 27), geo(-111, 26), geo(-110, 25),
            geo(-109, 24), geo(-108, 23), geo(-107, 22), geo(-106, 21),
            geo(-105, 20), geo(-104, 19), geo(-102, 18), geo(-100, 17),
            geo(-98, 17), geo(-96, 16), geo(-94, 16), geo(-92, 15),
            geo(-90, 15), geo(-88, 14), geo(-87, 14), geo(-86, 13),
            geo(-85, 12), geo(-84, 11), geo(-83, 10), geo(-82, 9), geo(-80, 9),
            // Caribbean coast back north
            geo(-80, 9), geo(-81, 10), geo(-83, 11), geo(-84, 13),
            geo(-85, 14), geo(-86, 15), geo(-87, 16), geo(-88, 18),
            geo(-89, 19), geo(-90, 20), geo(-91, 21),
            // Yucatan
            geo(-90, 21), geo(-89, 21), geo(-88, 20), geo(-87, 20),
            geo(-87, 21), geo(-88, 22), geo(-90, 22),
            // Gulf coast
            geo(-91, 23), geo(-91, 25), geo(-92, 27), geo(-93, 28),
            geo(-93, 29), geo(-92, 30), geo(-91, 30), geo(-90, 30),
            geo(-89, 30), geo(-88, 30), geo(-87, 30), geo(-86, 30),
            geo(-85, 30), geo(-84, 30), geo(-83, 30),
            // Florida
            geo(-82, 30), geo(-82, 29), geo(-81, 28), geo(-81, 27),
            geo(-80, 26), geo(-80, 25), geo(-81, 25), geo(-82, 25),
            geo(-82, 26), geo(-82, 27), geo(-82, 28), geo(-83, 29),
            geo(-83, 30),
            // East coast
            geo(-82, 31), geo(-81, 32), geo(-80, 33), geo(-79, 34),
            geo(-78, 35), geo(-77, 36), geo(-76, 37), geo(-75, 38),
            geo(-75, 39), geo(-74, 40), geo(-74, 41), geo(-73, 41),
            geo(-72, 41), geo(-71, 42), geo(-70, 42), geo(-70, 43),
            geo(-69, 44), geo(-68, 44), geo(-67, 45), geo(-67, 44),
            geo(-66, 44), geo(-65, 44), geo(-64, 44), geo(-63, 46),
            // Maritimes
            geo(-61, 46), geo(-60, 47), geo(-59, 47), geo(-57, 48),
            geo(-56, 48), geo(-55, 48), geo(-54, 47), geo(-53, 47),
            geo(-53, 48), geo(-55, 50), geo(-56, 51), geo(-57, 52),
            geo(-58, 53), geo(-60, 54), geo(-60, 55),
            // Labrador
            geo(-61, 56), geo(-62, 58), geo(-63, 59), geo(-64, 60),
            geo(-66, 61), geo(-68, 62), geo(-70, 62), geo(-73, 62),
            geo(-76, 63), geo(-78, 63), geo(-79, 63),
            // Hudson Bay west coast
            geo(-80, 62), geo(-80, 60), geo(-80, 58), geo(-80, 56),
            geo(-80, 55), geo(-81, 54), geo(-82, 54), geo(-83, 55),
            geo(-84, 56), geo(-85, 57), geo(-86, 57),
            // Hudson Bay south
            geo(-85, 55), geo(-83, 52), geo(-82, 51), geo(-80, 52),
            // Hudson Bay east coast back up
            geo(-80, 55), geo(-80, 58), geo(-81, 60), geo(-82, 62),
            geo(-84, 63), geo(-86, 63), geo(-88, 63),
            // Arctic coast westward
            geo(-90, 64), geo(-92, 65), geo(-94, 66), geo(-96, 67),
            geo(-98, 67), geo(-100, 68), geo(-102, 68), geo(-104, 69),
            geo(-106, 69), geo(-108, 69), geo(-110, 70), geo(-112, 70),
            geo(-115, 70), geo(-118, 71), geo(-120, 71),
            geo(-122, 72), geo(-125, 72), geo(-128, 72),
            geo(-130, 72), geo(-132, 71), geo(-135, 71),
            geo(-138, 71), geo(-140, 70), geo(-142, 70),
            geo(-145, 70), geo(-148, 71), geo(-150, 71),
            geo(-152, 71), geo(-155, 70), geo(-157, 69),
            geo(-158, 68), geo(-160, 66), geo(-162, 64),
            geo(-164, 62), geo(-165, 60), geo(-166, 58),
            geo(-167, 56), geo(-168, 54), geo(-168, 53),
        ],
        [   // Greenland
            geo(-52, 60), geo(-50, 60), geo(-48, 61), geo(-46, 61),
            geo(-44, 60), geo(-42, 60), geo(-40, 61), geo(-38, 62),
            geo(-36, 63), geo(-34, 64), geo(-30, 66), geo(-26, 68),
            geo(-22, 70), geo(-20, 72), geo(-18, 74), geo(-18, 76),
            geo(-19, 77), geo(-20, 78), geo(-22, 79), geo(-26, 80),
            geo(-30, 81), geo(-34, 82), geo(-38, 82), geo(-42, 82),
            geo(-46, 81), geo(-48, 80), geo(-50, 79), geo(-52, 78),
            geo(-54, 76), geo(-55, 74), geo(-56, 72), geo(-57, 70),
            geo(-56, 68), geo(-54, 66), geo(-52, 64), geo(-50, 62),
            geo(-52, 60),
        ],
    ]),

    // ===================== SOUTH AMERICA =====================
    ContinentOutline(name: "South America", paths: [
        [
            geo(-78, 10), geo(-77, 11), geo(-76, 11), geo(-75, 11),
            geo(-73, 12), geo(-72, 12), geo(-70, 12), geo(-68, 11),
            geo(-66, 11), geo(-64, 10), geo(-62, 9), geo(-60, 8),
            geo(-58, 7), geo(-56, 6), geo(-54, 4), geo(-52, 3),
            geo(-50, 2), geo(-48, 0), geo(-46, -1), geo(-44, -2),
            geo(-42, -3), geo(-40, -5), geo(-39, -8), geo(-38, -10),
            geo(-37, -12), geo(-37, -13), geo(-38, -15), geo(-39, -17),
            geo(-39, -18), geo(-40, -20), geo(-41, -22), geo(-42, -23),
            geo(-44, -23), geo(-46, -24), geo(-47, -25), geo(-48, -27),
            geo(-49, -28), geo(-50, -30), geo(-51, -31), geo(-52, -33),
            geo(-53, -34), geo(-55, -36), geo(-57, -38), geo(-59, -39),
            geo(-61, -40), geo(-63, -42), geo(-64, -44), geo(-65, -46),
            geo(-66, -48), geo(-67, -50), geo(-68, -52), geo(-69, -54),
            geo(-70, -53), geo(-72, -50), geo(-73, -48), geo(-74, -46),
            geo(-74, -44), geo(-73, -42), geo(-73, -40), geo(-72, -38),
            geo(-71, -36), geo(-71, -33), geo(-71, -30), geo(-71, -28),
            geo(-70, -25), geo(-70, -22), geo(-70, -20), geo(-70, -18),
            geo(-71, -16), geo(-72, -15), geo(-74, -14), geo(-75, -12),
            geo(-76, -10), geo(-77, -8), geo(-78, -5), geo(-79, -3),
            geo(-80, 0), geo(-80, 2), geo(-80, 4), geo(-79, 6),
            geo(-78, 8), geo(-78, 10),
        ],
    ]),

    // ===================== EUROPE =====================
    ContinentOutline(name: "Europe", paths: [
        [   // Iberia → France → Benelux → North Sea → Scandinavia → Baltic → Balkans → Med
            geo(-9, 37), geo(-9, 38), geo(-8, 39), geo(-8, 40), geo(-9, 41),
            geo(-9, 42), geo(-9, 43), geo(-8, 44), geo(-6, 44), geo(-4, 44),
            geo(-2, 43), geo(-1, 43), geo(0, 44), geo(1, 43), geo(3, 43),
            geo(4, 44), geo(3, 46), geo(1, 47), geo(-1, 48), geo(-3, 48),
            geo(-4, 48), geo(-5, 49), geo(-5, 50), geo(-4, 51),
            geo(-3, 52), geo(-1, 51), geo(0, 51), geo(1, 51), geo(2, 51),
            geo(3, 52), geo(4, 52), geo(5, 53), geo(6, 54), geo(7, 54),
            geo(8, 55), geo(9, 55), geo(10, 56),
            // Jutland
            geo(9, 56), geo(9, 57), geo(10, 57), geo(10, 58), geo(11, 58),
            geo(12, 57), geo(12, 56), geo(11, 55),
            // Scandinavia
            geo(12, 57), geo(12, 58), geo(13, 59), geo(14, 60),
            geo(15, 61), geo(16, 62), geo(17, 63), geo(17, 64),
            geo(18, 65), geo(18, 66), geo(18, 68), geo(19, 69),
            geo(20, 70), geo(21, 71), geo(23, 71), geo(25, 71),
            geo(27, 71), geo(28, 71), geo(30, 70), geo(30, 69),
            geo(31, 68), geo(30, 67), geo(29, 66), geo(28, 65),
            geo(28, 64), geo(27, 63), geo(26, 62), geo(25, 61),
            geo(25, 60), geo(24, 59), geo(24, 58),
            // Baltic
            geo(23, 57), geo(22, 56), geo(21, 56), geo(20, 55),
            geo(19, 55), geo(18, 55), geo(16, 54), geo(14, 54),
            geo(13, 54), geo(12, 54),
            // South through Poland
            geo(14, 53), geo(14, 52), geo(16, 51), geo(18, 50),
            geo(20, 49), geo(20, 48), geo(21, 47), geo(22, 46),
            geo(22, 45), geo(23, 44), geo(24, 43), geo(25, 42),
            geo(26, 41), geo(26, 40), geo(26, 39), geo(25, 38),
            // Greece
            geo(24, 38), geo(23, 37), geo(23, 36), geo(22, 37),
            geo(21, 38), geo(20, 39), geo(20, 40), geo(21, 40),
            geo(21, 38), geo(20, 37), geo(22, 36),
            // Back west through Med
            geo(20, 38), geo(19, 40), geo(18, 40),
            // Italy
            geo(18, 40), geo(17, 39), geo(16, 38), geo(15, 38),
            geo(16, 39), geo(16, 40), geo(15, 41), geo(14, 41),
            geo(13, 42), geo(13, 43), geo(12, 44), geo(12, 45),
            geo(13, 46), geo(14, 46), geo(13, 46),
            geo(12, 45), geo(10, 44), geo(8, 44),
            geo(6, 43), geo(4, 42), geo(3, 42), geo(2, 41),
            geo(0, 40), geo(-1, 39), geo(-2, 38), geo(-3, 37),
            geo(-4, 36), geo(-5, 36), geo(-6, 37), geo(-7, 37),
            geo(-8, 37), geo(-9, 37),
        ],
        [   // Great Britain
            geo(-5, 50), geo(-4, 51), geo(-3, 52), geo(-3, 53),
            geo(-4, 54), geo(-5, 55), geo(-5, 56), geo(-4, 57),
            geo(-3, 58), geo(-4, 58), geo(-5, 58), geo(-6, 57),
            geo(-6, 56), geo(-5, 55), geo(-5, 54), geo(-4, 53),
            geo(-3, 52), geo(-5, 51), geo(-5, 50),
        ],
        [   // Ireland
            geo(-10, 51), geo(-9, 52), geo(-8, 53), geo(-7, 54),
            geo(-8, 55), geo(-10, 55), geo(-10, 54), geo(-10, 53),
            geo(-10, 52), geo(-10, 51),
        ],
        [   // Iceland
            geo(-24, 64), geo(-22, 64), geo(-20, 65), geo(-18, 66),
            geo(-15, 66), geo(-14, 66), geo(-13, 65), geo(-14, 64),
            geo(-16, 63), geo(-18, 63), geo(-20, 63), geo(-22, 63),
            geo(-24, 64),
        ],
        [   // Corsica+Sardinia
            geo(9, 39), geo(9, 41), geo(10, 42), geo(9, 42),
            geo(8, 41), geo(9, 39),
        ],
        [   // Sicily
            geo(13, 37), geo(15, 38), geo(16, 37), geo(14, 36), geo(13, 37),
        ],
    ]),

    // ===================== AFRICA =====================
    ContinentOutline(name: "Africa", paths: [
        [
            geo(-17, 14), geo(-17, 15), geo(-16, 16), geo(-16, 18),
            geo(-17, 20), geo(-17, 21), geo(-16, 23), geo(-15, 25),
            geo(-14, 26), geo(-13, 28), geo(-12, 30), geo(-10, 32),
            geo(-8, 34), geo(-6, 35), geo(-4, 36), geo(-2, 35),
            geo(0, 36), geo(2, 37), geo(4, 37), geo(6, 37),
            geo(8, 37), geo(9, 36), geo(10, 35), geo(10, 34),
            geo(10, 33), geo(11, 33), geo(12, 33), geo(13, 33),
            geo(14, 33), geo(15, 33), geo(16, 33), geo(17, 32),
            geo(18, 32), geo(20, 32), geo(22, 32), geo(24, 32),
            geo(25, 32), geo(27, 31), geo(28, 31), geo(30, 31),
            geo(31, 31), geo(32, 31), geo(33, 30), geo(34, 30),
            geo(35, 30), geo(34, 28), geo(34, 26), geo(35, 24),
            geo(36, 22), geo(37, 20), geo(38, 18), geo(39, 16),
            geo(40, 14), geo(41, 12), geo(42, 12), geo(43, 11),
            geo(45, 11), geo(47, 10), geo(48, 10), geo(50, 8),
            geo(50, 6), geo(50, 4), geo(49, 2), geo(48, 0),
            geo(46, -1), geo(44, -2), geo(42, -4), geo(41, -6),
            geo(40, -8), geo(39, -10), geo(38, -11),
            geo(37, -12), geo(36, -14), geo(36, -16), geo(35, -18),
            geo(35, -20), geo(36, -22), geo(36, -24), geo(35, -26),
            geo(34, -28), geo(33, -29), geo(32, -30), geo(31, -32),
            geo(30, -33), geo(29, -34), geo(28, -34), geo(27, -34),
            geo(26, -34), geo(25, -34), geo(23, -34),
            geo(21, -34), geo(20, -34), geo(19, -33), geo(18, -33),
            geo(17, -32), geo(17, -31), geo(16, -30), geo(15, -28),
            geo(14, -26), geo(13, -22), geo(13, -18), geo(12, -14),
            geo(12, -10), geo(12, -6), geo(11, -4), geo(10, -2),
            geo(10, 0), geo(9, 1), geo(9, 3), geo(8, 4), geo(7, 5),
            geo(6, 5), geo(5, 5), geo(4, 5), geo(3, 6),
            geo(2, 6), geo(1, 5), geo(0, 5), geo(-1, 5),
            geo(-3, 5), geo(-4, 5), geo(-6, 5), geo(-8, 5),
            geo(-10, 6), geo(-11, 7), geo(-12, 8), geo(-13, 9),
            geo(-14, 10), geo(-15, 11), geo(-16, 12), geo(-16, 13),
            geo(-17, 14),
        ],
        [   // Madagascar
            geo(44, -12), geo(46, -14), geo(48, -16), geo(50, -18),
            geo(50, -20), geo(50, -22), geo(49, -24), geo(48, -25),
            geo(46, -26), geo(44, -24), geo(43, -22), geo(43, -20),
            geo(43, -18), geo(43, -16), geo(44, -14), geo(44, -12),
        ],
    ]),

    // ===================== ASIA =====================
    ContinentOutline(name: "Asia", paths: [
        [   // Turkey → Middle East → India → SE Asia → China → Korea → Russia → Arctic
            geo(26, 42), geo(28, 42), geo(30, 42), geo(32, 40),
            geo(33, 38), geo(34, 37), geo(36, 37), geo(37, 37),
            geo(38, 37), geo(40, 38), geo(42, 37), geo(44, 37),
            geo(44, 36), geo(46, 34), geo(48, 30), geo(49, 28),
            geo(50, 27), geo(51, 25), geo(52, 24), geo(54, 23),
            geo(56, 22), geo(56, 24), geo(57, 25), geo(59, 25),
            geo(61, 25), geo(63, 25), geo(65, 25), geo(66, 24),
            geo(68, 23), geo(69, 22),
            // India
            geo(70, 21), geo(71, 20), geo(72, 19), geo(73, 17),
            geo(73, 16), geo(74, 14), geo(75, 12), geo(76, 10),
            geo(77, 8), geo(78, 8), geo(79, 9), geo(80, 10),
            geo(80, 12), geo(80, 14), geo(81, 16), geo(82, 17),
            geo(84, 18), geo(86, 20), geo(88, 22), geo(89, 22),
            geo(90, 22), geo(91, 22),
            // Bangladesh / Myanmar
            geo(92, 21), geo(93, 20), geo(94, 18), geo(95, 16),
            geo(96, 15), geo(97, 14), geo(98, 12), geo(98, 10),
            geo(99, 8), geo(100, 6), geo(101, 4), geo(102, 2),
            geo(103, 1), geo(104, 1),
            // Back up Vietnam coast
            geo(104, 2), geo(105, 5), geo(106, 8), geo(106, 10),
            geo(107, 12), geo(108, 14), geo(108, 16), geo(108, 18),
            geo(109, 19), geo(110, 20), geo(111, 21), geo(112, 22),
            geo(113, 22), geo(114, 22), geo(116, 23), geo(117, 24),
            geo(118, 25), geo(119, 26), geo(120, 27), geo(121, 28),
            geo(121, 30), geo(122, 31), geo(122, 32), geo(121, 33),
            geo(120, 34), geo(120, 35),
            // Korea
            geo(122, 35), geo(124, 35), geo(126, 34), geo(127, 35),
            geo(128, 36), geo(129, 37), geo(129, 38), geo(130, 39),
            geo(130, 40), geo(130, 42), geo(130, 43),
            // Russian Pacific coast
            geo(131, 43), geo(132, 44), geo(133, 46), geo(134, 48),
            geo(135, 50), geo(136, 51), geo(138, 52), geo(139, 53),
            geo(140, 54), geo(141, 55), geo(142, 56), geo(143, 57),
            geo(145, 58), geo(147, 59), geo(149, 60), geo(151, 60),
            geo(153, 60), geo(155, 61), geo(157, 62), geo(159, 63),
            // Kamchatka
            geo(160, 63), geo(162, 62), geo(162, 60), geo(161, 58),
            geo(160, 56), geo(161, 55), geo(162, 56), geo(163, 58),
            geo(165, 60), geo(167, 62), geo(170, 64), geo(173, 65),
            geo(176, 66), geo(178, 66), geo(180, 65),
            // Arctic coast west
            geo(178, 68), geo(175, 69), geo(172, 70), geo(168, 71),
            geo(164, 72), geo(160, 72), geo(155, 72), geo(150, 73),
            geo(145, 73), geo(140, 72), geo(135, 72), geo(130, 73),
            geo(125, 73), geo(120, 73), geo(115, 73), geo(110, 72),
            geo(105, 73), geo(100, 73), geo(95, 73), geo(90, 73),
            geo(85, 72), geo(80, 72), geo(75, 72), geo(70, 72),
            geo(65, 71), geo(60, 70), geo(55, 68), geo(50, 67),
            geo(48, 66), geo(45, 65), geo(42, 64),
            geo(40, 62), geo(38, 60), geo(36, 58), geo(35, 56),
            geo(34, 54), geo(33, 52), geo(32, 50), geo(31, 48),
            geo(30, 46), geo(30, 44), geo(30, 42),
            geo(28, 42), geo(26, 42),
        ],
        [   // Japan main islands
            geo(130, 31), geo(131, 32), geo(132, 33), geo(133, 34),
            geo(134, 34), geo(135, 35), geo(136, 35), geo(137, 36),
            geo(138, 36), geo(139, 37), geo(140, 38), geo(140, 39),
            geo(141, 40), geo(142, 42), geo(143, 43), geo(144, 44),
            geo(145, 45), geo(145, 44), geo(144, 43), geo(143, 42),
            geo(142, 41), geo(141, 40), geo(140, 39), geo(140, 38),
            geo(139, 37), geo(138, 36), geo(136, 35), geo(134, 34),
            geo(133, 33), geo(131, 32), geo(130, 31),
        ],
        [   // Sri Lanka
            geo(80, 6), geo(81, 7), geo(82, 7), geo(82, 8),
            geo(81, 9), geo(80, 8), geo(80, 7), geo(80, 6),
        ],
        [   // Taiwan
            geo(120, 22), geo(121, 23), geo(122, 25), geo(121, 25),
            geo(120, 24), geo(120, 22),
        ],
    ]),

    // ===================== AUSTRALIA =====================
    ContinentOutline(name: "Australia", paths: [
        [   // Main landmass
            geo(115, -15), geo(117, -15), geo(119, -15), geo(121, -14),
            geo(123, -14), geo(125, -14), geo(127, -14), geo(129, -13),
            geo(130, -12), geo(131, -12), geo(133, -12), geo(135, -12),
            geo(136, -13), geo(137, -14), geo(136, -16), geo(136, -17),
            geo(137, -17), geo(138, -16), geo(139, -17), geo(140, -18),
            geo(141, -17), geo(142, -16), geo(143, -15), geo(144, -15),
            geo(145, -15), geo(146, -17), geo(147, -18), geo(148, -20),
            geo(149, -21), geo(150, -23), geo(151, -24), geo(152, -26),
            geo(153, -27), geo(153, -28), geo(153, -30),
            geo(152, -32), geo(151, -33), geo(150, -35), geo(148, -37),
            geo(147, -38), geo(145, -38), geo(143, -38),
            geo(141, -38), geo(139, -37), geo(137, -36), geo(135, -35),
            geo(133, -34), geo(131, -34), geo(129, -33),
            geo(127, -33), geo(125, -34), geo(123, -34), geo(121, -34),
            geo(119, -33), geo(117, -33), geo(115, -32),
            geo(114, -30), geo(114, -28), geo(113, -26), geo(113, -24),
            geo(113, -22), geo(114, -21), geo(115, -20),
            geo(116, -19), geo(117, -19), geo(118, -18),
            geo(119, -17), geo(118, -17), geo(117, -16), geo(115, -15),
        ],
        [   // Tasmania
            geo(145, -40), geo(146, -41), geo(148, -42), geo(148, -43),
            geo(147, -43), geo(146, -42), geo(145, -41), geo(145, -40),
        ],
        [   // New Zealand North
            geo(166, -35), geo(167, -36), geo(168, -37), geo(172, -38),
            geo(174, -38), geo(176, -38), geo(178, -37),
            geo(176, -37), geo(174, -37), geo(172, -37),
            geo(170, -36), geo(168, -36), geo(166, -35),
        ],
        [   // New Zealand South
            geo(166, -42), geo(168, -44), geo(170, -45), geo(172, -46),
            geo(174, -46), geo(172, -45), geo(170, -44),
            geo(168, -43), geo(166, -42),
        ],
        [   // Papua New Guinea
            geo(141, -3), geo(143, -4), geo(145, -5), geo(147, -6),
            geo(149, -6), geo(151, -5), geo(152, -4), geo(150, -3),
            geo(148, -2), geo(146, -2), geo(144, -2), geo(142, -2),
            geo(141, -3),
        ],
        [   // Borneo
            geo(108, 4), geo(110, 3), geo(112, 2), geo(114, 2),
            geo(116, 1), geo(118, 0), geo(118, -1), geo(117, -3),
            geo(116, -4), geo(114, -4), geo(112, -3), geo(110, -2),
            geo(108, -1), geo(108, 1), geo(108, 4),
        ],
        [   // Sumatra
            geo(95, 5), geo(97, 3), geo(99, 1), geo(101, -1),
            geo(103, -3), geo(105, -5), geo(105, -6),
            geo(104, -5), geo(102, -3), geo(100, -1),
            geo(98, 1), geo(96, 3), geo(95, 5),
        ],
        [   // Java
            geo(106, -6), geo(108, -7), geo(110, -7), geo(112, -8),
            geo(114, -8), geo(115, -8), geo(114, -7), geo(112, -7),
            geo(110, -6), geo(108, -6), geo(106, -6),
        ],
        [   // Sulawesi
            geo(119, -1), geo(120, 0), geo(122, 1), geo(123, 0),
            geo(124, -1), geo(123, -3), geo(122, -4), geo(121, -5),
            geo(120, -4), geo(119, -3), geo(119, -1),
        ],
        [   // Philippines
            geo(118, 8), geo(119, 10), geo(120, 12), geo(121, 14),
            geo(122, 15), geo(123, 14), geo(124, 12), geo(125, 10),
            geo(124, 9), geo(122, 8), geo(120, 8), geo(118, 8),
        ],
    ]),
]
