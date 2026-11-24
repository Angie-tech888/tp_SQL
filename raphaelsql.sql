#comme le nom du fichier lindique  fait par Raphaël 
 
DROP DATABASE IF EXISTS asso_event;
 
CREATE DATABASE asso_event
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE asso_event;
 
CREATE TABLE utilisateur (
    id_utilisateur  INT AUTO_INCREMENT,
    nom_utilisateur VARCHAR(50)  NOT NULL,
    prenom VARCHAR(50)  NOT NULL,
    email VARCHAR(255) NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL, -- hash du mot de passe, jamais en clair
    date_naissance DATE NOT NULL,
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role VARCHAR(20)  NOT NULL DEFAULT 'membre',
    CONSTRAINT pk_utilisateur PRIMARY KEY (id_utilisateur),
    CONSTRAINT uq_utilisateur_email UNIQUE (email),
    CONSTRAINT ck_utilisateur_role CHECK (role IN ('membre', 'organisateur', 'administrateur'))
) ENGINE=InnoDB;
 
CREATE TABLE lieu (
    id_lieu INT AUTO_INCREMENT,
    nom_lieu VARCHAR(100) NOT NULL,
    adresse VARCHAR(255) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    capacite_max INT NOT NULL,
    CONSTRAINT pk_lieu PRIMARY KEY (id_lieu),
    CONSTRAINT ck_lieu_capacite CHECK (capacite_max > 0)
) ENGINE=InnoDB;
 
CREATE TABLE categorie (
    id_categorie  INT         NOT NULL AUTO_INCREMENT,
    nom_categorie VARCHAR(50) NOT NULL,
    CONSTRAINT pk_categorie PRIMARY KEY (id_categorie),
    CONSTRAINT uq_categorie_nom UNIQUE (nom_categorie)
) ENGINE=InnoDB;
 
CREATE TABLE evenement (
    id_evenement INT NOT NULL AUTO_INCREMENT,
    id_utilisateur  INT NOT NULL, -- organisateur de l'événement
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    date_debut DATETIME NOT NULL,
    date_fin DATETIME NOT NULL,
    prix DECIMAL(8,2) NOT NULL DEFAULT 0,
    nb_places INT NOT NULL,
    reserve_majeurs BOOLEAN NOT NULL DEFAULT FALSE,
    statut_evenement VARCHAR(20) NOT NULL DEFAULT 'brouillon',
    id_lieu INT NOT NULL,
    id_categorie INT NOT NULL,
    CONSTRAINT pk_evenement PRIMARY KEY (id_evenement),
    CONSTRAINT ck_evenement_dates  CHECK (date_fin > date_debut),
    CONSTRAINT ck_evenement_prix   CHECK (prix >= 0),
    CONSTRAINT ck_evenement_places CHECK (nb_places >= 1),
    CONSTRAINT ck_evenement_statut
        CHECK (statut_evenement IN ('brouillon', 'publie', 'annule')),
 
    -- RESTRICT : on ne peut pas supprimer un organisateur tant qu'un événement y fait référence
    CONSTRAINT fk_evenement_organisateur
        FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur)
        ON DELETE RESTRICT,
 
    -- RESTRICT : on ne peut pas supprimer un lieu utilisé par un événement
    CONSTRAINT fk_evenement_lieu
        FOREIGN KEY (id_lieu) REFERENCES lieu (id_lieu)
        ON DELETE RESTRICT,
 
    -- RESTRICT : on ne peut pas supprimer une catégorie utilisée par un événement
    CONSTRAINT fk_evenement_categorie
        FOREIGN KEY (id_categorie) REFERENCES categorie (id_categorie)
        ON DELETE RESTRICT
) ENGINE=InnoDB;
 
CREATE TABLE inscription (
    id_inscription INT NOT NULL AUTO_INCREMENT,
    id_utilisateur INT NOT NULL,
    id_evenement INT NOT NULL,
    date_inscription DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut_inscription VARCHAR(20) NOT NULL DEFAULT 'confirmee',
    CONSTRAINT pk_inscription PRIMARY KEY (id_inscription),
    -- un utilisateur ne peut s'inscrire qu'une seule fois à un même événement
    CONSTRAINT uq_inscription_utilisateur_evenement
        UNIQUE (id_utilisateur, id_evenement),
    CONSTRAINT ck_inscription_statut
        CHECK (statut_inscription IN ('confirmee', 'liste_attente', 'annulee')),

    -- CASCADE : si l'utilisateur est supprimé, ses inscriptions n'ont plus de sens
    CONSTRAINT fk_inscription_utilisateur
        FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur)
        ON DELETE CASCADE,

    -- CASCADE : si l'événement est supprimé, ses inscriptions sont supprimées aussi
    CONSTRAINT fk_inscription_evenement
        FOREIGN KEY (id_evenement) REFERENCES evenement (id_evenement)
        ON DELETE CASCADE
) ENGINE=InnoDB;
