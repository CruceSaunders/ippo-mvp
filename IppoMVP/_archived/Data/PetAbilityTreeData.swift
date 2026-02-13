import Foundation

// MARK: - Pet Ability Tree Data
// Each pet has a unique branching ability tree themed to their element.
// Trees have 8-10 nodes with 2-3 specialization branches merging at a capstone.

struct PetAbilityTreeData {
    
    // MARK: - Lookup
    static func treeForPet(_ petId: String) -> [PetAbilityNode] {
        switch petId {
        case "pet_01": return emberTree
        case "pet_02": return splashTree
        case "pet_03": return sproutTree
        case "pet_04": return zephyrTree
        case "pet_05": return pebbleTree
        case "pet_06": return sparkTree
        case "pet_07": return shadowTree
        case "pet_08": return frostTree
        case "pet_09": return blazeTree
        case "pet_10": return lunaTree
        default: return []
        }
    }
    
    static func edgesForPet(_ petId: String) -> [(from: String, to: String)] {
        let nodes = treeForPet(petId)
        var result: [(String, String)] = []
        for node in nodes {
            for prereq in node.prerequisites {
                result.append((prereq, node.id))
            }
        }
        return result
    }
    
    static func node(forPet petId: String, nodeId: String) -> PetAbilityNode? {
        treeForPet(petId).first { $0.id == nodeId }
    }
    
    // ═══════════════════════════════════════════
    // EMBER - Fire pet: RP on short sprints
    // ═══════════════════════════════════════════
    static let emberTree: [PetAbilityNode] = [
        PetAbilityNode(id: "e_core", petId: "pet_01", name: "Ignite", description: "+15% RP on sprints under 35s", tier: 0, cost: 0, effect: .rpBonus(0.15), prerequisites: [], iconName: "flame.fill", treeX: 0.50, treeY: 0.08),
        // Branch A: Quick Burn
        PetAbilityNode(id: "e_quick", petId: "pet_01", name: "Quick Burn", description: "+5% sprint speed bonus", tier: 1, cost: 1, effect: .sprintBonus(0.05), prerequisites: ["e_core"], iconName: "hare.fill", treeX: 0.25, treeY: 0.28),
        PetAbilityNode(id: "e_flash", petId: "pet_01", name: "Flash Sprint", description: "+10% RP on short sprints", tier: 2, cost: 2, effect: .rpBonus(0.10), prerequisites: ["e_quick"], iconName: "bolt.fill", treeX: 0.20, treeY: 0.48),
        PetAbilityNode(id: "e_after", petId: "pet_01", name: "Afterburner", description: "+15% all sprint rewards", tier: 3, cost: 3, effect: .sprintBonus(0.15), prerequisites: ["e_flash"], iconName: "flame.circle.fill", treeX: 0.25, treeY: 0.68),
        // Branch B: Inner Fire
        PetAbilityNode(id: "e_inner", petId: "pet_01", name: "Inner Fire", description: "+8% RP from all sources", tier: 1, cost: 1, effect: .rpBonus(0.08), prerequisites: ["e_core"], iconName: "heart.fill", treeX: 0.75, treeY: 0.28),
        PetAbilityNode(id: "e_heat", petId: "pet_01", name: "Heat Wave", description: "+12% RP bonus", tier: 2, cost: 2, effect: .rpBonus(0.12), prerequisites: ["e_inner"], iconName: "sun.max.fill", treeX: 0.80, treeY: 0.48),
        PetAbilityNode(id: "e_inferno", petId: "pet_01", name: "Inferno", description: "+20% RP on all sprints", tier: 3, cost: 3, effect: .rpBonus(0.20), prerequisites: ["e_heat"], iconName: "flame.fill", treeX: 0.75, treeY: 0.68),
        // Capstone
        PetAbilityNode(id: "e_master", petId: "pet_01", name: "Ember Master", description: "+30% RP + 10% all rewards", tier: 4, cost: 4, effect: .allBonus(0.10), prerequisites: ["e_after", "e_inferno"], iconName: "crown.fill", treeX: 0.50, treeY: 0.90),
    ]
    
    // ═══════════════════════════════════════════
    // SPLASH - Water pet: Passive XP
    // ═══════════════════════════════════════════
    static let splashTree: [PetAbilityNode] = [
        PetAbilityNode(id: "s_core", petId: "pet_02", name: "Flow", description: "+10% passive XP during runs", tier: 0, cost: 0, effect: .xpBonus(0.10), prerequisites: [], iconName: "drop.fill", treeX: 0.50, treeY: 0.06),
        // Branch A: Steady Stream
        PetAbilityNode(id: "s_steady", petId: "pet_02", name: "Steady Stream", description: "+5% XP over time", tier: 1, cost: 1, effect: .xpBonus(0.05), prerequisites: ["s_core"], iconName: "water.waves", treeX: 0.20, treeY: 0.22),
        PetAbilityNode(id: "s_current", petId: "pet_02", name: "Deep Current", description: "+10% XP multiplier", tier: 2, cost: 2, effect: .xpBonus(0.10), prerequisites: ["s_steady"], iconName: "tornado", treeX: 0.15, treeY: 0.42),
        PetAbilityNode(id: "s_rapids", petId: "pet_02", name: "Rapids", description: "+15% passive XP", tier: 3, cost: 3, effect: .passiveBonus(0.15), prerequisites: ["s_current"], iconName: "wind", treeX: 0.20, treeY: 0.62),
        // Branch B: Tidal Force
        PetAbilityNode(id: "s_tidal", petId: "pet_02", name: "Tidal Force", description: "+8% sprint XP", tier: 1, cost: 1, effect: .sprintBonus(0.08), prerequisites: ["s_core"], iconName: "waveform", treeX: 0.80, treeY: 0.22),
        PetAbilityNode(id: "s_wave", petId: "pet_02", name: "Wave Rider", description: "+12% sprint XP", tier: 2, cost: 2, effect: .sprintBonus(0.12), prerequisites: ["s_tidal"], iconName: "figure.surfing", treeX: 0.85, treeY: 0.42),
        PetAbilityNode(id: "s_tsunami", petId: "pet_02", name: "Tsunami", description: "+18% all XP", tier: 3, cost: 3, effect: .xpBonus(0.18), prerequisites: ["s_wave"], iconName: "cloud.heavyrain.fill", treeX: 0.80, treeY: 0.62),
        // Branch C: Hydro
        PetAbilityNode(id: "s_hydro", petId: "pet_02", name: "Hydro Pump", description: "+5% coin bonus", tier: 1, cost: 1, effect: .coinBonus(0.05), prerequisites: ["s_core"], iconName: "drop.circle.fill", treeX: 0.50, treeY: 0.22),
        PetAbilityNode(id: "s_torrent", petId: "pet_02", name: "Torrent", description: "+10% all rewards when mood is high", tier: 2, cost: 2, effect: .allBonus(0.10), prerequisites: ["s_hydro"], iconName: "humidity.fill", treeX: 0.50, treeY: 0.42),
        // Capstone
        PetAbilityNode(id: "s_master", petId: "pet_02", name: "Splash Master", description: "+25% XP + 10% all rewards", tier: 4, cost: 4, effect: .allBonus(0.10), prerequisites: ["s_rapids", "s_tsunami"], iconName: "crown.fill", treeX: 0.50, treeY: 0.88),
    ]
    
    // ═══════════════════════════════════════════
    // SPROUT - Plant pet: Evolution XP
    // ═══════════════════════════════════════════
    static let sproutTree: [PetAbilityNode] = [
        PetAbilityNode(id: "sp_core", petId: "pet_03", name: "Growth", description: "+20% evolution XP", tier: 0, cost: 0, effect: .petXpBonus(0.20), prerequisites: [], iconName: "leaf.fill", treeX: 0.50, treeY: 0.06),
        // Branch A: Bloom
        PetAbilityNode(id: "sp_bloom", petId: "pet_03", name: "Bloom", description: "+20% feeding XP bonus", tier: 1, cost: 1, effect: .feedingBonus(0.20), prerequisites: ["sp_core"], iconName: "camera.macro", treeX: 0.20, treeY: 0.22),
        PetAbilityNode(id: "sp_petal", petId: "pet_03", name: "Petal Dance", description: "+15% mood from feeding", tier: 2, cost: 2, effect: .feedingBonus(0.15), prerequisites: ["sp_bloom"], iconName: "leaf.circle.fill", treeX: 0.15, treeY: 0.42),
        PetAbilityNode(id: "sp_garden", petId: "pet_03", name: "Garden", description: "+25% all feeding rewards", tier: 3, cost: 3, effect: .feedingBonus(0.25), prerequisites: ["sp_petal"], iconName: "tree.fill", treeX: 0.20, treeY: 0.62),
        // Branch B: Root System
        PetAbilityNode(id: "sp_root", petId: "pet_03", name: "Root System", description: "-10% mood decay", tier: 1, cost: 1, effect: .moodDecayReduction(0.10), prerequisites: ["sp_core"], iconName: "arrow.down.to.line", treeX: 0.80, treeY: 0.22),
        PetAbilityNode(id: "sp_deep", petId: "pet_03", name: "Deep Roots", description: "-20% mood decay", tier: 2, cost: 2, effect: .moodDecayReduction(0.20), prerequisites: ["sp_root"], iconName: "arrow.branch", treeX: 0.85, treeY: 0.42),
        PetAbilityNode(id: "sp_ancient", petId: "pet_03", name: "Ancient Tree", description: "+30% pet evolution XP", tier: 3, cost: 3, effect: .petXpBonus(0.30), prerequisites: ["sp_deep"], iconName: "tree.fill", treeX: 0.80, treeY: 0.62),
        // Branch C: Overgrowth
        PetAbilityNode(id: "sp_over", petId: "pet_03", name: "Overgrowth", description: "+10% XP to ALL pets", tier: 1, cost: 2, effect: .petXpBonus(0.10), prerequisites: ["sp_core"], iconName: "leaf.arrow.circlepath", treeX: 0.50, treeY: 0.22),
        PetAbilityNode(id: "sp_forest", petId: "pet_03", name: "Forest Spirit", description: "+15% all pet bonuses", tier: 2, cost: 3, effect: .allBonus(0.05), prerequisites: ["sp_over"], iconName: "sparkles", treeX: 0.50, treeY: 0.42),
        // Capstone
        PetAbilityNode(id: "sp_master", petId: "pet_03", name: "Sprout Master", description: "+40% evolution XP + team boost", tier: 4, cost: 4, effect: .petXpBonus(0.40), prerequisites: ["sp_garden", "sp_ancient"], iconName: "crown.fill", treeX: 0.50, treeY: 0.88),
    ]
    
    // ═══════════════════════════════════════════
    // ZEPHYR - Air pet: Encounter chance
    // ═══════════════════════════════════════════
    static let zephyrTree: [PetAbilityNode] = [
        PetAbilityNode(id: "z_core", petId: "pet_04", name: "Tailwind", description: "+10% encounter chance", tier: 0, cost: 0, effect: .encounterBonus(0.10), prerequisites: [], iconName: "wind", treeX: 0.50, treeY: 0.08),
        // Branch A: Gust
        PetAbilityNode(id: "z_gust", petId: "pet_04", name: "Gust", description: "+5% sprint frequency", tier: 1, cost: 1, effect: .encounterBonus(0.05), prerequisites: ["z_core"], iconName: "wind.circle.fill", treeX: 0.25, treeY: 0.28),
        PetAbilityNode(id: "z_storm", petId: "pet_04", name: "Storm Runner", description: "+10% encounter rate", tier: 2, cost: 2, effect: .encounterBonus(0.10), prerequisites: ["z_gust"], iconName: "cloud.bolt.fill", treeX: 0.20, treeY: 0.48),
        PetAbilityNode(id: "z_cyclone", petId: "pet_04", name: "Cyclone", description: "+15% all encounter bonuses", tier: 3, cost: 3, effect: .encounterBonus(0.15), prerequisites: ["z_storm"], iconName: "tornado", treeX: 0.25, treeY: 0.68),
        // Branch B: Breeze
        PetAbilityNode(id: "z_breeze", petId: "pet_04", name: "Breeze", description: "+8% passive rewards", tier: 1, cost: 1, effect: .passiveBonus(0.08), prerequisites: ["z_core"], iconName: "leaf.fill", treeX: 0.75, treeY: 0.28),
        PetAbilityNode(id: "z_drift", petId: "pet_04", name: "Drift", description: "+12% passive XP", tier: 2, cost: 2, effect: .xpBonus(0.12), prerequisites: ["z_breeze"], iconName: "cloud.fill", treeX: 0.80, treeY: 0.48),
        PetAbilityNode(id: "z_jet", petId: "pet_04", name: "Jet Stream", description: "+5% all sprint rewards", tier: 3, cost: 3, effect: .sprintBonus(0.05), prerequisites: ["z_drift"], iconName: "airplane", treeX: 0.75, treeY: 0.68),
        // Capstone
        PetAbilityNode(id: "z_master", petId: "pet_04", name: "Zephyr Master", description: "+20% encounters + 10% rewards", tier: 4, cost: 4, effect: .allBonus(0.10), prerequisites: ["z_cyclone", "z_jet"], iconName: "crown.fill", treeX: 0.50, treeY: 0.90),
    ]
    
    // ═══════════════════════════════════════════
    // PEBBLE - Stone pet: Mood decay reduction
    // ═══════════════════════════════════════════
    static let pebbleTree: [PetAbilityNode] = [
        PetAbilityNode(id: "p_core", petId: "pet_05", name: "Fortitude", description: "-15% mood decay", tier: 0, cost: 0, effect: .moodDecayReduction(0.15), prerequisites: [], iconName: "mountain.2.fill", treeX: 0.50, treeY: 0.08),
        // Branch A: Stone Wall
        PetAbilityNode(id: "p_wall", petId: "pet_05", name: "Stone Wall", description: "-10% additional mood decay", tier: 1, cost: 1, effect: .moodDecayReduction(0.10), prerequisites: ["p_core"], iconName: "shield.fill", treeX: 0.25, treeY: 0.28),
        PetAbilityNode(id: "p_fortress", petId: "pet_05", name: "Fortress", description: "+10% mood from feeding", tier: 2, cost: 2, effect: .feedingBonus(0.10), prerequisites: ["p_wall"], iconName: "building.2.fill", treeX: 0.20, treeY: 0.48),
        PetAbilityNode(id: "p_iron", petId: "pet_05", name: "Iron Will", description: "-25% mood decay", tier: 3, cost: 3, effect: .moodDecayReduction(0.25), prerequisites: ["p_fortress"], iconName: "shield.lefthalf.filled", treeX: 0.25, treeY: 0.68),
        // Branch B: Earthen Shield
        PetAbilityNode(id: "p_earth", petId: "pet_05", name: "Earthen Shield", description: "+5% all rewards", tier: 1, cost: 1, effect: .allBonus(0.05), prerequisites: ["p_core"], iconName: "globe.americas.fill", treeX: 0.75, treeY: 0.28),
        PetAbilityNode(id: "p_quake", petId: "pet_05", name: "Earthquake", description: "+10% RP from sprints", tier: 2, cost: 2, effect: .rpBonus(0.10), prerequisites: ["p_earth"], iconName: "waveform.path.ecg", treeX: 0.80, treeY: 0.48),
        PetAbilityNode(id: "p_titan", petId: "pet_05", name: "Titan", description: "+15% all rewards", tier: 3, cost: 3, effect: .allBonus(0.15), prerequisites: ["p_quake"], iconName: "figure.strengthtraining.traditional", treeX: 0.75, treeY: 0.68),
        // Capstone
        PetAbilityNode(id: "p_master", petId: "pet_05", name: "Pebble Master", description: "Minimal mood decay + 10% bonus", tier: 4, cost: 4, effect: .allBonus(0.10), prerequisites: ["p_iron", "p_titan"], iconName: "crown.fill", treeX: 0.50, treeY: 0.90),
    ]
    
    // ═══════════════════════════════════════════
    // SPARK - Electric pet: Loot box coins
    // ═══════════════════════════════════════════
    static let sparkTree: [PetAbilityNode] = [
        PetAbilityNode(id: "sk_core", petId: "pet_06", name: "Energize", description: "+25% coins from loot boxes", tier: 0, cost: 0, effect: .coinBonus(0.25), prerequisites: [], iconName: "bolt.fill", treeX: 0.50, treeY: 0.06),
        // Branch A: Voltage
        PetAbilityNode(id: "sk_volt", petId: "pet_06", name: "Voltage", description: "+10% loot quality", tier: 1, cost: 1, effect: .lootQualityBonus(0.10), prerequisites: ["sk_core"], iconName: "bolt.circle.fill", treeX: 0.20, treeY: 0.22),
        PetAbilityNode(id: "sk_amp", petId: "pet_06", name: "Amplify", description: "+15% coin gains", tier: 2, cost: 2, effect: .coinBonus(0.15), prerequisites: ["sk_volt"], iconName: "speaker.wave.3.fill", treeX: 0.15, treeY: 0.42),
        PetAbilityNode(id: "sk_surge", petId: "pet_06", name: "Power Surge", description: "+20% loot box rewards", tier: 3, cost: 3, effect: .coinBonus(0.20), prerequisites: ["sk_amp"], iconName: "bolt.trianglebadge.exclamationmark.fill", treeX: 0.20, treeY: 0.62),
        // Branch B: Circuit
        PetAbilityNode(id: "sk_circuit", petId: "pet_06", name: "Circuit", description: "+5 gems per loot box", tier: 1, cost: 1, effect: .coinBonus(0.05), prerequisites: ["sk_core"], iconName: "cpu", treeX: 0.80, treeY: 0.22),
        PetAbilityNode(id: "sk_charge", petId: "pet_06", name: "Charge Up", description: "+10% gem rewards", tier: 2, cost: 2, effect: .coinBonus(0.10), prerequisites: ["sk_circuit"], iconName: "battery.100.bolt", treeX: 0.85, treeY: 0.42),
        PetAbilityNode(id: "sk_tesla", petId: "pet_06", name: "Tesla Coil", description: "+15% all currency rewards", tier: 3, cost: 3, effect: .allBonus(0.15), prerequisites: ["sk_charge"], iconName: "antenna.radiowaves.left.and.right", treeX: 0.80, treeY: 0.62),
        // Branch C: Overload
        PetAbilityNode(id: "sk_over", petId: "pet_06", name: "Overload", description: "+10% rare loot chance", tier: 1, cost: 2, effect: .lootLuckBonus(0.10), prerequisites: ["sk_core"], iconName: "exclamationmark.triangle.fill", treeX: 0.50, treeY: 0.22),
        PetAbilityNode(id: "sk_chain", petId: "pet_06", name: "Chain Lightning", description: "+15% loot luck", tier: 2, cost: 3, effect: .lootLuckBonus(0.15), prerequisites: ["sk_over"], iconName: "bolt.horizontal.fill", treeX: 0.50, treeY: 0.42),
        // Capstone
        PetAbilityNode(id: "sk_master", petId: "pet_06", name: "Spark Master", description: "+30% all currency + rare loot", tier: 4, cost: 4, effect: .allBonus(0.15), prerequisites: ["sk_surge", "sk_tesla"], iconName: "crown.fill", treeX: 0.50, treeY: 0.88),
    ]
    
    // ═══════════════════════════════════════════
    // SHADOW - Dark pet: Catch rate
    // ═══════════════════════════════════════════
    static let shadowTree: [PetAbilityNode] = [
        PetAbilityNode(id: "sh_core", petId: "pet_07", name: "Stealth", description: "+5% catch rate", tier: 0, cost: 0, effect: .catchRateBonus(0.05), prerequisites: [], iconName: "eye.slash.fill", treeX: 0.50, treeY: 0.08),
        // Branch A: Cloak
        PetAbilityNode(id: "sh_cloak", petId: "pet_07", name: "Cloak", description: "+3% catch rate", tier: 1, cost: 1, effect: .catchRateBonus(0.03), prerequisites: ["sh_core"], iconName: "person.fill.questionmark", treeX: 0.25, treeY: 0.28),
        PetAbilityNode(id: "sh_vanish", petId: "pet_07", name: "Vanish", description: "+5% catch rate", tier: 2, cost: 2, effect: .catchRateBonus(0.05), prerequisites: ["sh_cloak"], iconName: "figure.walk.departure", treeX: 0.20, treeY: 0.48),
        PetAbilityNode(id: "sh_assassin", petId: "pet_07", name: "Shadow Strike", description: "+8% catch rate", tier: 3, cost: 3, effect: .catchRateBonus(0.08), prerequisites: ["sh_vanish"], iconName: "hand.raised.slash.fill", treeX: 0.25, treeY: 0.68),
        // Branch B: Phantom
        PetAbilityNode(id: "sh_phantom", petId: "pet_07", name: "Phantom", description: "+5% encounter rate", tier: 1, cost: 1, effect: .encounterBonus(0.05), prerequisites: ["sh_core"], iconName: "moon.fill", treeX: 0.75, treeY: 0.28),
        PetAbilityNode(id: "sh_night", petId: "pet_07", name: "Night Walker", description: "+10% passive rewards", tier: 2, cost: 2, effect: .passiveBonus(0.10), prerequisites: ["sh_phantom"], iconName: "moon.stars.fill", treeX: 0.80, treeY: 0.48),
        PetAbilityNode(id: "sh_void", petId: "pet_07", name: "Void Step", description: "+10% all bonuses at night", tier: 3, cost: 3, effect: .allBonus(0.10), prerequisites: ["sh_night"], iconName: "circle.slash", treeX: 0.75, treeY: 0.68),
        // Capstone
        PetAbilityNode(id: "sh_master", petId: "pet_07", name: "Shadow Master", description: "+10% catch + 15% all rewards", tier: 4, cost: 4, effect: .catchRateBonus(0.10), prerequisites: ["sh_assassin", "sh_void"], iconName: "crown.fill", treeX: 0.50, treeY: 0.90),
    ]
    
    // ═══════════════════════════════════════════
    // FROST - Ice pet: Feeding XP
    // ═══════════════════════════════════════════
    static let frostTree: [PetAbilityNode] = [
        PetAbilityNode(id: "f_core", petId: "pet_08", name: "Preserve", description: "+50% feeding XP", tier: 0, cost: 0, effect: .feedingBonus(0.50), prerequisites: [], iconName: "snowflake", treeX: 0.50, treeY: 0.06),
        // Branch A: Deep Freeze
        PetAbilityNode(id: "f_freeze", petId: "pet_08", name: "Deep Freeze", description: "+1 extra feeding per day", tier: 1, cost: 1, effect: .feedingBonus(0.20), prerequisites: ["f_core"], iconName: "thermometer.snowflake", treeX: 0.20, treeY: 0.22),
        PetAbilityNode(id: "f_cryo", petId: "pet_08", name: "Cryo Chamber", description: "+30% feeding XP", tier: 2, cost: 2, effect: .feedingBonus(0.30), prerequisites: ["f_freeze"], iconName: "snowflake.circle.fill", treeX: 0.15, treeY: 0.42),
        PetAbilityNode(id: "f_absolute", petId: "pet_08", name: "Absolute Zero", description: "+40% feeding rewards", tier: 3, cost: 3, effect: .feedingBonus(0.40), prerequisites: ["f_cryo"], iconName: "thermometer.low", treeX: 0.20, treeY: 0.62),
        // Branch B: Glacial
        PetAbilityNode(id: "f_glacial", petId: "pet_08", name: "Glacial", description: "+15% mood from feeding", tier: 1, cost: 1, effect: .feedingBonus(0.15), prerequisites: ["f_core"], iconName: "drop.triangle.fill", treeX: 0.80, treeY: 0.22),
        PetAbilityNode(id: "f_icicle", petId: "pet_08", name: "Icicle Shield", description: "-15% mood decay", tier: 2, cost: 2, effect: .moodDecayReduction(0.15), prerequisites: ["f_glacial"], iconName: "shield.fill", treeX: 0.85, treeY: 0.42),
        PetAbilityNode(id: "f_blizzard", petId: "pet_08", name: "Blizzard", description: "+10% all pet XP", tier: 3, cost: 3, effect: .petXpBonus(0.10), prerequisites: ["f_icicle"], iconName: "cloud.snow.fill", treeX: 0.80, treeY: 0.62),
        // Branch C: Permafrost
        PetAbilityNode(id: "f_perma", petId: "pet_08", name: "Permafrost", description: "+10% passive feeding bonus", tier: 1, cost: 2, effect: .feedingBonus(0.10), prerequisites: ["f_core"], iconName: "snowflake.slash", treeX: 0.50, treeY: 0.22),
        PetAbilityNode(id: "f_arctic", petId: "pet_08", name: "Arctic Wind", description: "+5% all rewards", tier: 2, cost: 3, effect: .allBonus(0.05), prerequisites: ["f_perma"], iconName: "wind.snow", treeX: 0.50, treeY: 0.42),
        // Capstone
        PetAbilityNode(id: "f_master", petId: "pet_08", name: "Frost Master", description: "+60% feeding + 15% all", tier: 4, cost: 4, effect: .allBonus(0.15), prerequisites: ["f_absolute", "f_blizzard"], iconName: "crown.fill", treeX: 0.50, treeY: 0.88),
    ]
    
    // ═══════════════════════════════════════════
    // BLAZE - Fire pet: RP on long sprints
    // ═══════════════════════════════════════════
    static let blazeTree: [PetAbilityNode] = [
        PetAbilityNode(id: "b_core", petId: "pet_09", name: "Intensity", description: "+30% RP on sprints over 40s", tier: 0, cost: 0, effect: .rpBonus(0.30), prerequisites: [], iconName: "flame.fill", treeX: 0.50, treeY: 0.08),
        // Branch A: Sustained Burn
        PetAbilityNode(id: "b_sustain", petId: "pet_09", name: "Sustained Burn", description: "+10% long sprint RP", tier: 1, cost: 1, effect: .rpBonus(0.10), prerequisites: ["b_core"], iconName: "flame.circle.fill", treeX: 0.25, treeY: 0.28),
        PetAbilityNode(id: "b_endure", petId: "pet_09", name: "Endurance", description: "+15% sprint rewards", tier: 2, cost: 2, effect: .sprintBonus(0.15), prerequisites: ["b_sustain"], iconName: "figure.run", treeX: 0.20, treeY: 0.48),
        PetAbilityNode(id: "b_furnace", petId: "pet_09", name: "Furnace", description: "+20% RP on long sprints", tier: 3, cost: 3, effect: .rpBonus(0.20), prerequisites: ["b_endure"], iconName: "flame.fill", treeX: 0.25, treeY: 0.68),
        // Branch B: Wildfire
        PetAbilityNode(id: "b_wild", petId: "pet_09", name: "Wildfire", description: "+8% RP spread to XP", tier: 1, cost: 1, effect: .xpBonus(0.08), prerequisites: ["b_core"], iconName: "flame.circle.fill", treeX: 0.75, treeY: 0.28),
        PetAbilityNode(id: "b_scorch", petId: "pet_09", name: "Scorch", description: "+12% all sprint rewards", tier: 2, cost: 2, effect: .sprintBonus(0.12), prerequisites: ["b_wild"], iconName: "sun.max.fill", treeX: 0.80, treeY: 0.48),
        PetAbilityNode(id: "b_nova", petId: "pet_09", name: "Supernova", description: "+10% all rewards", tier: 3, cost: 3, effect: .allBonus(0.10), prerequisites: ["b_scorch"], iconName: "star.fill", treeX: 0.75, treeY: 0.68),
        // Capstone
        PetAbilityNode(id: "b_master", petId: "pet_09", name: "Blaze Master", description: "+35% RP + 15% all", tier: 4, cost: 4, effect: .allBonus(0.15), prerequisites: ["b_furnace", "b_nova"], iconName: "crown.fill", treeX: 0.50, treeY: 0.90),
    ]
    
    // ═══════════════════════════════════════════
    // LUNA - Celestial pet: All pet bonuses
    // ═══════════════════════════════════════════
    static let lunaTree: [PetAbilityNode] = [
        PetAbilityNode(id: "l_core", petId: "pet_10", name: "Blessing", description: "+5% to ALL other pet bonuses", tier: 0, cost: 0, effect: .allBonus(0.05), prerequisites: [], iconName: "moon.fill", treeX: 0.50, treeY: 0.06),
        // Branch A: Moonlight
        PetAbilityNode(id: "l_moon", petId: "pet_10", name: "Moonlight", description: "+5% team-wide boost", tier: 1, cost: 1, effect: .allBonus(0.05), prerequisites: ["l_core"], iconName: "moon.circle.fill", treeX: 0.20, treeY: 0.22),
        PetAbilityNode(id: "l_glow", petId: "pet_10", name: "Lunar Glow", description: "+8% XP for all pets", tier: 2, cost: 2, effect: .petXpBonus(0.08), prerequisites: ["l_moon"], iconName: "sparkle", treeX: 0.15, treeY: 0.42),
        PetAbilityNode(id: "l_tide", petId: "pet_10", name: "Lunar Tide", description: "+10% all pet evolution XP", tier: 3, cost: 3, effect: .petXpBonus(0.10), prerequisites: ["l_glow"], iconName: "moon.stars.fill", treeX: 0.20, treeY: 0.62),
        // Branch B: Eclipse
        PetAbilityNode(id: "l_eclipse", petId: "pet_10", name: "Eclipse", description: "+8% rare loot chance", tier: 1, cost: 1, effect: .lootLuckBonus(0.08), prerequisites: ["l_core"], iconName: "circle.lefthalf.filled", treeX: 0.80, treeY: 0.22),
        PetAbilityNode(id: "l_shadow", petId: "pet_10", name: "Penumbra", description: "+5% catch rate", tier: 2, cost: 2, effect: .catchRateBonus(0.05), prerequisites: ["l_eclipse"], iconName: "circle.dashed", treeX: 0.85, treeY: 0.42),
        PetAbilityNode(id: "l_solar", petId: "pet_10", name: "Solar Flare", description: "+12% all rewards during sprints", tier: 3, cost: 3, effect: .sprintBonus(0.12), prerequisites: ["l_shadow"], iconName: "sun.max.fill", treeX: 0.80, treeY: 0.62),
        // Branch C: Celestial
        PetAbilityNode(id: "l_celestial", petId: "pet_10", name: "Celestial", description: "+10% to ALL bonuses", tier: 1, cost: 2, effect: .allBonus(0.10), prerequisites: ["l_core"], iconName: "sparkles", treeX: 0.50, treeY: 0.22),
        PetAbilityNode(id: "l_cosmos", petId: "pet_10", name: "Cosmos", description: "+15% all rewards", tier: 2, cost: 3, effect: .allBonus(0.15), prerequisites: ["l_celestial"], iconName: "globe", treeX: 0.50, treeY: 0.42),
        // Capstone
        PetAbilityNode(id: "l_master", petId: "pet_10", name: "Luna Master", description: "+20% ALL bonuses to everything", tier: 4, cost: 4, effect: .allBonus(0.20), prerequisites: ["l_tide", "l_solar"], iconName: "crown.fill", treeX: 0.50, treeY: 0.88),
    ]
}
