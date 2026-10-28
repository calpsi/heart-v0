import SwiftUI

struct ReferencesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 20) {
                    Image("GuidedHeart").resizable().scaledToFit().frame(width: 100, height: 100)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explore the science").font(.title2.bold())
                        Text("Sources for the developmental and anomaly models.")
                            .foregroundStyle(HeartDesign.secondary)
                    }
                }
                reference("The HUDSEN Atlas", source: "Kerwin et al. · Journal of Anatomy, 2010",
                          url: "https://doi.org/10.1111/j.1469-7580.2010.01290.x")
                reference("Human embryonic and fetal tissue resources", source: "Gerrelli et al. · Development, 2015",
                          url: "https://doi.org/10.1242/dev.122820")
                reference("Human AV canal and vestibular spine development", source: "Human embryonic tissue study · 2001", url: "https://pubmed.ncbi.nlm.nih.gov/11230106/")
                reference("Atrial septation and mesenchymal tissues", source: "Developmental anatomy review", url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6588001/")
                reference("Foramen ovale closure", source: "Experimental study; human persistence discussed", url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4162597/")
                reference("Fallot morphology", source: "Anatomical review", url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC2651859/")
                reference("Human embryonic heart reconstructions", source: "Hikspoors et al. · Communications Biology, 2022",
                          url: "https://www.nature.com/articles/s42003-022-03153-x")
                reference("Staged human heart anatomy and histology", source: "Human Developmental Biology Resource Atlas",
                          url: "https://hdbratlas.org/organ-systems/cardiovascular-system/heart.html")
                reference("Human epicardial formation", source: "Staged human embryos · PubMed",
                          url: "https://pubmed.ncbi.nlm.nih.gov/1462754/")
                reference("Fetal-to-adult valve maturation", source: "Aikawa et al. · Circulation, 2006",
                          url: "https://pubmed.ncbi.nlm.nih.gov/16534030/")
                reference("Heart formation: lateral plate mesoderm", source: "Gilbert · Developmental Biology, 6th edition",
                          url: "https://www.ncbi.nlm.nih.gov/books/NBK9982/")
                reference("Heart looping animation", source: "UNSW Embryology · teaching animation",
                          url: "https://embryology.med.unsw.edu.au/embryology/index.php?title=Heart_Looping_Movie")
                reference("Heart development", source: "UNSW Embryology",
                          url: "https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_-_Heart_Development")
                reference("Cardiovascular system development", source: "UNSW Embryology",
                          url: "https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_Development")
                reference("Development, proliferation, and growth of the mammalian heart", source: "Research review · PubMed Central",
                          url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6037201/")
                reference("Ventricular septal defects", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/ventricular-septal-defect-vsd")
                reference("Atrial septal defects", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/atrial-septal-defect-asd")
                reference("Tetralogy of Fallot", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/tetralogy-of-fallot")
                reference("Transposition of the great arteries", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/transposition-of-the-great-arteries-tga")
                reference("Coarctation of the aorta", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/coarctation-of-the-aorta")
                reference("Patent ductus arteriosus", source: "Merck Manual · Professional",
                          url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda")
                Text("Models are enlarged educational illustrations. Developmental timings are approximate post-fertilization ages. Later-anatomy references are labelled separately.")
                    .font(.subheadline).foregroundStyle(HeartDesign.secondary)
            }.padding(28)
        }
        .foregroundStyle(HeartDesign.text)
        .background(HeartDesign.surface)
        .navigationTitle("References")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }.buttonStyle(HeartSecondaryButtonStyle())
            }
        }
    }

    private func reference(_ title: String, source: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(source).font(.subheadline).foregroundStyle(HeartDesign.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(Color.accentColor)
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(HeartDesign.panel, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}

#Preview { NavigationStack { ReferencesView() } }
