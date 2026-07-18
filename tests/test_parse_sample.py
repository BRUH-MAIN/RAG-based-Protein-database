from pathlib import Path

from ingest.parse_and_load import iter_records, map_record

FIXTURE_PATH = Path(__file__).parent / "fixtures" / "sample.dat"


def _mapped_by_entry():
    records = list(iter_records(FIXTURE_PATH, limit=10))
    return {r.accessions[0]: map_record(r) for r in records}


def test_fixture_has_three_records():
    records = list(iter_records(FIXTURE_PATH, limit=10))
    assert len(records) == 3


def test_core_protein_fields():
    mapped = _mapped_by_entry()["P58486"]
    protein = mapped["protein"]
    assert protein["entry"] == "P58486"
    assert protein["entry_name"] == "MENC_SALTY"
    assert protein["organism"].startswith("Salmonella typhimurium")
    assert protein["sequence"].startswith("MRSAQVYRWQIP")
    assert "o-succinylbenzoate synthase" in protein["protein_names"]


def test_active_sites_match_known_positions():
    mapped = _mapped_by_entry()["P58486"]
    positions = {(s["position"], s["description"]) for s in mapped["active_sites"]}
    assert ("133", "Proton donor") in positions
    assert ("235", "Proton acceptor") in positions


def test_binding_sites_capture_ligand_and_position():
    mapped = _mapped_by_entry()["P58486"]
    assert mapped["binding_sites"], "expected at least one binding site"
    assert all(site["ligand"] == "Mg(2+)" for site in mapped["binding_sites"])
    assert all(site["start_position"] == site["end_position"] for site in mapped["binding_sites"])


def test_pathways_and_family_extracted():
    mapped = _mapped_by_entry()["P58486"]
    assert any("menaquinone" in p for p in mapped["pathways"])
    assert mapped["protein_families"] == ["mandelate racemase/muconate lactonizing enzyme family"]


def test_disease_involvement_has_omim_id():
    mapped = _mapped_by_entry()["P01308"]
    diseases = {d["omim_id"]: d["disease_name"] for d in mapped["disease_involvement"]}
    assert diseases["616214"] == "Hyperproinsulinemia (HPRI)"


def test_pharmaceutical_use_and_family():
    mapped = _mapped_by_entry()["P01308"]
    assert mapped["pharmaceutical_uses"], "expected a pharmaceutical use entry"
    assert mapped["protein_families"] == ["insulin family"]


def test_interactions_parsed_from_single_comment():
    mapped = _mapped_by_entry()["P01308"]
    partners = {i["interacting_protein"] for i in mapped["interactions"]}
    assert "IDE (P14735-1)" in partners


def test_genes_extracted():
    mapped = _mapped_by_entry()["P01308"]
    assert mapped["genes"] == ["INS"]


def test_taxonomic_lineage_ordered():
    mapped = _mapped_by_entry()["P01308"]
    lineage = mapped["taxonomic_lineage"]
    assert lineage[0] == {"rank_order": 0, "lineage_path": "Eukaryota"}
    assert lineage[1]["rank_order"] == 1


def test_hemoglobin_binding_sites_include_heme_and_bpg():
    mapped = _mapped_by_entry()["P68871"]
    ligands = {site["ligand"] for site in mapped["binding_sites"]}
    assert "heme b" in ligands
    assert "(2R)-2,3-bisphosphoglycerate" in ligands
