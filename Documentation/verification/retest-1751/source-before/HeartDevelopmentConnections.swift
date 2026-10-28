import Foundation

/// Mechanism links connect normal development to the existing anomaly models.
/// They describe a developmental relationship, not a single cause of every CHD.
struct HeartDevelopmentConnection: Identifiable {
    let id: String
    let stage: Int
    let lesson: String
    let process: String
    let difference: String
    let consequence: String

    var timing: String {
        switch id {
        case "atrial": "During atrial partitioning"
        case "cushion": "During formation of the central AV junction"
        case "ventricular": "During ventricular partitioning and junction closure"
        case "outflow", "tga": "During outflow division and ventricular alignment"
        case "arch": "During arch development; effects may emerge as the ductus closes"
        default: "At the transition after birth"
        }
    }
    static func at(_ position: Double) -> [Self] {
        // These markers associate processes, not a diagnostic onset at an exact day.
        let stage = HeartDevelopmentTimeline.stage(position)
        let ids: [String]
        if (5...6).contains(position) && position != 5 {
            ids = ["outflow", "tga", "arch"]
        } else {
            switch stage {
            case 4: ids = ["atrial", "cushion"]
            case 5: ids = ["ventricular", "cushion", "outflow"]
            case 6: ids = ["outflow", "tga", "arch"]
            case 7: ids = ["ductus", "arch"]
            default: ids = []
            }
        }
        return ids.compactMap { id in all.first { $0.id == id } }
    }


    static let all: [Self] = [
        .init(id: "atrial", stage: 4, lesson: "Atrial Septal Defect (ASD)",
              process: "The atria develop overlapping walls and a flap that supports fetal circulation.",
              difference: "If atrial septal tissue develops incompletely, an abnormal opening can remain. A normal fetal opening is not itself an ASD.",
              consequence: "After birth, blood can pass between the atria through that opening."),
        .init(id: "ventricular", stage: 5, lesson: "Ventricular Septal Defect (VSD)",
              process: "Growing and joining tissues partition the ventricular chambers.",
              difference: "Incomplete formation or joining can leave a communication between the ventricles.",
              consequence: "Blood can cross between the pumping chambers instead of staying in separate routes."),
        .init(id: "outflow", stage: 6, lesson: "Tetralogy of Fallot",
              process: "The developing outlets align with the ventricles as the outflow tract is divided.",
              difference: "Altered outlet alignment is associated with a narrowed pulmonary outlet, an overriding aorta and a ventricular septal defect.",
              consequence: "The route to the lungs can be obstructed. The resulting circulation depends on the degree of obstruction."),
        .init(id: "ductus", stage: 7, lesson: "Patent Ductus Arteriosus (PDA)",
              process: "Before birth, the ductus arteriosus connects the pulmonary artery and aorta. It normally closes after birth.",
              difference: "If this vessel remains open, it is called a patent ductus arteriosus.",
              consequence: "After birth, the persisting connection can send additional blood towards the lungs."),
        .init(id: "cushion", stage: 4, lesson: "Atrioventricular Septal Defect (AVSD)",
              process: "The atrioventricular junction develops coordinated walls and valve openings between upper and lower chambers.",
              difference: "Abnormal development here can leave a central septal defect and abnormal AV valve anatomy. It is more than a hole in one wall.",
              consequence: "Blood can cross between chambers, and valve leakage can add to the heart’s workload."),
        .init(id: "tga", stage: 6, lesson: "Transposition of the Great Arteries (TGA)",
              process: "The outlets must connect to the appropriate ventricles as the heart develops.",
              difference: "In TGA, the aorta arises from the right ventricle and the pulmonary artery from the left. The division morph does not simulate how TGA develops.",
              consequence: "The two circulations run in parallel; connections allowing blood to mix become important."),
        .init(id: "arch", stage: 6, lesson: "Coarctation of the Aorta",
              process: "The arch and its branches remodel while the fetal ductus provides a connection between the great arteries.",
              difference: "Coarctation is a narrowed aortic segment. Its development is multifactorial; this marker does not assign one mechanism or exact onset.",
              consequence: "The narrowing can obstruct systemic flow. Its effects may become more apparent as the ductus closes after birth.")
    ]

    static func forLesson(_ name: String) -> Self? { forLessons(name).first }
    static func forLessons(_ name: String) -> [Self] {
        if let anomaly = all.first(where: { $0.lesson == name }) { return [anomaly] }
        let ids: [String]
        if name.localizedCaseInsensitiveContains("atrial septation") { ids = ["atrial"] }
        else if name.localizedCaseInsensitiveContains("cushion") { ids = ["cushion", "ventricular"] }
        else if name.localizedCaseInsensitiveContains("ventricular septation") { ids = ["ventricular"] }
        else if name.localizedCaseInsensitiveContains("outflow") { ids = ["outflow", "tga", "arch"] }
        else if name.localizedCaseInsensitiveContains("circulatory transition") { ids = ["ductus", "arch"] }
        else { ids = [] }
        return ids.compactMap { id in all.first { $0.id == id } }
    }
}
