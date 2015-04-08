import re
import pprint

taxons = {
    'homo_sapiens': 9606,
    'human': 9606,
    'danio_rerio': 7955,
    'zebrafish': 7955,
    'felis_catus': 9685,
    'cat': 9685,
    'mus_musculus': 10090,
    'mouse': 10090,
    'tetraodon_nigroviridis': 99883,
    'pufferfish': 99883,
    'vicugna_pacos': 30538,
    'alpaca': 30538,
    'gallus_gallus': 9031,
    'chicken': 9031,
    'pan_troglodytes': 9598,
    'chimpanzee': 9598,
    'bos_taurus': 9913,
    'cow': 9913,
    'gorilla_gorilla': 9595,
    'gorilla': 9595,
    'cavia_porcellus': 10141,
    'guineapig': 10141,
    'pongo_abelii': 9601,
    'orangutan': 9601,
    'sus_scrofa': 9823,
    'pig': 9823,
    'rattus_norvegicus': 10116,
    'rat': 10116,
    'ovis_aries': 9940,
    'sheep': 9940,
    'choloepus_hoffmanni': 9358,
    'sloth': 9358,
    'mustela_putorius_furo': 9669,
    'ferret': 9669,
    'drosophila_melanogaster': 7227,
    'fruitfly': 7227,
    'nomascus_leucogenys': 61853,
    'gibbon': 61853,
    'equus_caballus': 9796,
    'horse': 9796,
    'dasypus_novemcinctus': 9361,
    'armadillo': 9361,
    'otolemur_garnettii': 30611,
    'bushbaby': 30611,
    'caenorhabditis_elegans': 6239,
    'celegans': 6239,
    'tursiops_truncatus': 9739,
    'dolphin': 9739,
    'loxodonta_africana': 9785,
    'elephant': 9785,
    'erinaceus_europaeus': 9365,
    'hedgehog': 9365,
    'callithrix_jacchus': 9483,
    'marmoset': 9483,
    'ailuropoda_melanoleuca': 9646,
    'panda': 9646,
    'ochotona_princeps': 9978,
    'pika': 9978,
    'ornithorhynchus_anatinus': 9258,
    'platypus': 9258
    }

def find_taxon(id):

    try:
        return int(id)

    except ValueError:
        id = id.lower()
        if id in taxons:
            return taxons[id]

    raise Exception("Unknown taxonomy")

def find_molecule_type(id):

    m = re.search(r"([A-Za-z]+)([A-Za-z])(\d+)", id)

    return m.group(2).upper()

def find_transcript_rec(rows, id):

    for t in rows['transcripts']:

        if t['id'] == id:
            return t

    return None

def find_exon_rec(rows, id, path):

    t_rows = find_transcript_rec(rows, path['transcript'])

    if not t_rows:
        return None

    for e in t_rows['exons']:
        if e['id'] == id:
            return e

    return None
