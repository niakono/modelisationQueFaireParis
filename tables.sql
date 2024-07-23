DROP TABLE IF EXISTS EvenementsTemporaire CASCADE;
DROP TABLE IF EXISTS Villes CASCADE;
DROP TABLE IF EXISTS Lieux CASCADE;
DROP TABLE IF EXISTS Evenements CASCADE;
DROP TABLE IF EXISTS Tag CASCADE;
DROP TABLE IF EXISTS Contacts CASCADE;
DROP TABLE IF EXISTS Reservations CASCADE;
DROP TABLE IF EXISTS Occurrences CASCADE;
DROP TABLE IF EXISTS Transport CASCADE;
DROP TABLE IF EXISTS Images CASCADE;
DROP TABLE IF EXISTS Tags CASCADE;



CREATE TABLE EvenementsTemporaire (
    ID INT PRIMARY KEY,
    url TEXT,
    Titre TEXT,
    Chapeau TEXT,
    description TEXT,
    date_de_debut TIMESTAMPTZ,
    Date_de_fin TIMESTAMPTZ,
    occurrences TEXT,
    Description_de_la_date TEXT,
    url_de_l_image TEXT,
    texte_alternatif_de_l_image TEXT,
    credit_de_l_image TEXT,
    Mots_cles TEXT,
    Nom_du_lieu TEXT,
    adresse_du_lieu TEXT,
    code_postal TEXT,
    ville VARCHAR(100),
    coordonnees_geographiques VARCHAR(100),
    Acces_PMR BOOLEAN,
    Acces_mal_voyant BOOLEAN,
    Acces_mal_entendant BOOLEAN,
    Transport TEXT,
    Url_de_contact TEXT,
    Telephone_de_contact VARCHAR(20),
    Email_de_contact TEXT,
    URL_Facebook_associee TEXT,
    URL_Twitter_associee TEXT,
    Type_de_prix VARCHAR(100),
    Detail_du_prix TEXT,
    Type_d_acces VARCHAR(100),
    URL_de_reservation TEXT,
    URL_de_reservation_texte TEXT,
    Date_de_mise_a_jour TIMESTAMPTZ,
    Image_de_couverture TEXT,
    Programmes TEXT,
    En_ligne_address_url TEXT,
    En_ligne_address_url_text TEXT,
    En_ligne_address_text TEXT,
    Titre_event TEXT,
    audience TEXT,
    childrens TEXT,
    groupe TEXT
);

\copy EvenementsTemporaire FROM 'que-faire-a-paris.csv'  WITH (FORMAT CSV, HEADER TRUE, delimiter ';'); 




CREATE TABLE Villes(
    Code_postal TEXT PRIMARY KEY,
    Ville TEXT
);


CREATE TABLE Lieux(
    Nom_du_lieu TEXT NOT NULL PRIMARY KEY,
    adresse_du_lieu TEXT NOT NULL,
    Code_postal TEXT REFERENCES Villes,
    coordonnees_geographiques TEXT,
    Acces_mal_entendant BOOLEAN DEFAULT FALSE,
    Acces_mal_voyant BOOLEAN DEFAULT FALSE,
    Acces_PMR BOOLEAN DEFAULT FALSE
);

CREATE TABLE Transport(
    Nom_du_lieu TEXT REFERENCES Lieux,
    nom_transport TEXT
);

CREATE TABLE Evenements (
    id INT PRIMARY KEY,
    titre TEXT,
    description TEXT,
    date_de_debut TIMESTAMPTZ,
    date_de_fin TIMESTAMPTZ,
    Nom_du_lieu TEXT REFERENCES lieux(Nom_du_lieu),
    CONSTRAINT date_coherente CHECK (date_de_debut <= date_de_fin)
);

CREATE TABLE Occurrences(
    id_event INT REFERENCES Evenements,
    date_de_debut TIMESTAMPTZ,
    date_de_fin TIMESTAMPTZ,
    CHECK(date_de_fin >= date_de_debut)
);
-- Table intermédiaire
CREATE TABLE Tag (
    id_event INT REFERENCES Evenements,
    mot_cle TEXT NOT NULL,
    UNIQUE(id_event, mot_cle)
);

CREATE TABLE Tags (
    id_event INT REFERENCES Evenements,
    mot_cle TEXT NOT NULL,
    UNIQUE(id_event, mot_cle)
);

CREATE TABLE Reservations(
    id_event INT REFERENCES Evenements,
    title_event TEXT,
    Type_de_prix TEXT,
    Detail_du_prix TEXT,
    URL_de_reservation TEXT,
    URL_de_reservation_texte TEXT,
    audience TEXT
);

CREATE TABLE Contacts(
    id_event INT REFERENCES Evenements,
    url_de_contact TEXT,
    telephone_de_contact TEXT,
    Email_de_contact TEXT,
    URL_Facebook_associee TEXT,
    URL_Twitter_associee TEXT
);

CREATE TABLE Images(
    id_event INT REFERENCES Evenements,
    url_de_l_image TEXT,
    texte_alternatif_de_l_image TEXT,
    credit_de_l_image TEXT
);

DELETE FROM EvenementsTemporaire WHERE date_de_debut > date_de_fin;

INSERT INTO Villes (Code_postal, Ville) SELECT DISTINCT REPLACE(Code_postal,' ', '') as cp, Ville FROM EvenementsTemporaire WHERE Code_postal IS NOT NULL and Ville IS NOT NULL ON CONFLICT DO NOTHING;
INSERT INTO Lieux SELECT Nom_du_lieu, adresse_du_lieu, REPLACE(Code_postal,' ', ''), coordonnees_geographiques, Acces_mal_entendant, Acces_mal_voyant, Acces_PMR FROM EvenementsTemporaire WHERE Nom_du_lieu IS NOT NULL ON CONFLICT DO NOTHING;
INSERT INTO Evenements SELECT id, titre, description, date_de_debut, date_de_fin, Nom_du_lieu FROM EvenementsTemporaire;
INSERT INTO Contacts SELECT id, url_de_contact, telephone_de_contact, Email_de_contact, URL_Facebook_associee, URL_Twitter_associee FROM EvenementsTemporaire;
INSERT INTO Images SELECT id, url_de_l_image, texte_alternatif_de_l_image, credit_de_l_image FROM EvenementsTemporaire;
INSERT INTO Transport SELECT Nom_du_lieu, transport FROM EvenementsTemporaire WHERE Nom_du_lieu IS NOT NULL;
INSERT INTO Tag SELECT id, Mots_cles FROM EvenementsTemporaire WHERE Mots_cles IS NOT NULL;

CREATE OR REPLACE FUNCTION decomposer_attribut()
RETURNS VOID AS $$
DECLARE
    row_record RECORD;
    sub_partie TEXT;
BEGIN
    FOR row_record IN SELECT * FROM Tag LOOP
        -- Parcourir la chaîne de caractères dans row_record.mon_attribut
        FOR sub_partie IN SELECT regexp_split_to_table(row_record.mot_cle, ',') LOOP
            -- Inserer chaque sous-partie (mot-clé) avec son id
            INSERT INTO Tags VALUES(row_record.id_event, sub_partie);
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT decomposer_attribut();

DROP TABLE IF EXISTS Tag;

CREATE INDEX ON Tags ((lower(mot_cle)));
CREATE INDEX villes_idx ON Villes (ville);