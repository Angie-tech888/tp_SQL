#Naelyan
USE asso_event;

SELECT e.titre, e.date_debut, l.nom_lieu, c.nom_categorie, e.prix,
       e.nb_places - COUNT(i.id_inscription) AS places_restantes
FROM evenement e
JOIN lieu l ON e.id_lieu = l.id_lieu
JOIN categorie c ON e.id_categorie = c.id_categorie
LEFT JOIN inscription i ON e.id_evenement = i.id_evenement
                       AND i.statut_inscription = 'confirmee'
WHERE e.statut_evenement = 'publie' AND e.date_debut > NOW()
GROUP BY e.id_evenement, e.titre, e.date_debut, l.nom_lieu,
         c.nom_categorie, e.prix, e.nb_places
ORDER BY e.date_debut;

SELECT e.*, l.nom_lieu, l.adresse, l.ville,
       u.prenom, u.nom_utilisateur, u.email
FROM evenement e
JOIN lieu l ON e.id_lieu = l.id_lieu
JOIN utilisateur u ON e.id_utilisateur = u.id_utilisateur
WHERE e.id_evenement = 3;

SELECT e.titre, e.date_debut
FROM evenement e
JOIN inscription i ON e.id_evenement = i.id_evenement
WHERE e.statut_evenement = 'publie'
  AND i.statut_inscription = 'confirmee'
GROUP BY e.id_evenement, e.titre, e.date_debut, e.nb_places
HAVING COUNT(*) >= e.nb_places;

SELECT e.titre, e.date_debut, l.nom_lieu, i.statut_inscription
FROM inscription i
JOIN evenement e ON i.id_evenement = e.id_evenement
JOIN lieu l ON e.id_lieu = l.id_lieu
WHERE i.id_utilisateur = 7
  AND i.statut_inscription <> 'annulee'
  AND e.date_debut > NOW()
ORDER BY e.date_debut;

SELECT u.nom_utilisateur, u.prenom, u.email,
       i.statut_inscription, i.date_inscription
FROM inscription i
JOIN utilisateur u ON i.id_utilisateur = u.id_utilisateur
WHERE i.id_evenement = 7
ORDER BY FIELD(i.statut_inscription, 'confirmee', 'liste_attente', 'annulee'),
         i.date_inscription, i.id_inscription;

SELECT u.nom_utilisateur, u.prenom, u.email
FROM inscription i
JOIN utilisateur u ON i.id_utilisateur = u.id_utilisateur
JOIN evenement e ON i.id_evenement = e.id_evenement
WHERE i.id_evenement = 7
  AND i.statut_inscription = 'liste_attente'
  AND (SELECT COUNT(*)
       FROM inscription i2
       WHERE i2.id_evenement = e.id_evenement
         AND i2.statut_inscription = 'confirmee') >= e.nb_places
ORDER BY i.date_inscription, i.id_inscription
LIMIT 1;

SELECT e.titre, e.prix * COUNT(i.id_inscription) AS recette
FROM evenement e
LEFT JOIN inscription i ON e.id_evenement = i.id_evenement
                       AND i.statut_inscription = 'confirmee'
WHERE e.statut_evenement = 'publie' AND e.date_fin < NOW()
GROUP BY e.id_evenement, e.titre, e.prix
ORDER BY recette DESC;

SELECT c.nom_categorie,
       COALESCE(ROUND(100.0 * SUM(COALESCE(i.nb_confirmes, 0))
                      / NULLIF(SUM(e.nb_places), 0), 2), 0) AS taux_remplissage
FROM categorie c
LEFT JOIN evenement e ON c.id_categorie = e.id_categorie
                     AND e.statut_evenement = 'publie'
LEFT JOIN (
    SELECT id_evenement, COUNT(*) AS nb_confirmes
    FROM inscription
    WHERE statut_inscription = 'confirmee'
    GROUP BY id_evenement
) i ON e.id_evenement = i.id_evenement
GROUP BY c.id_categorie, c.nom_categorie;

SELECT i.id_inscription, u.nom_utilisateur, u.prenom, e.titre,
       i.statut_inscription
FROM inscription i
JOIN utilisateur u ON i.id_utilisateur = u.id_utilisateur
JOIN evenement e ON i.id_evenement = e.id_evenement
WHERE e.reserve_majeurs = 1
  AND i.statut_inscription <> 'annulee'
  AND TIMESTAMPDIFF(YEAR, u.date_naissance, e.date_debut) < 18;

START TRANSACTION;

SELECT nb_places INTO @places
FROM evenement
WHERE id_evenement = 6 AND statut_evenement = 'publie'
FOR UPDATE;

SELECT COUNT(*) INTO @inscrits
FROM inscription
WHERE id_evenement = 6 AND statut_inscription = 'confirmee';

SELECT COUNT(*) INTO @deja_inscrit
FROM inscription
WHERE id_utilisateur = 7 AND id_evenement = 6;

INSERT INTO inscription (id_utilisateur, id_evenement, statut_inscription)
SELECT 7, 6, IF(@inscrits < @places, 'confirmee', 'liste_attente')
FROM evenement
WHERE id_evenement = 6 AND statut_evenement = 'publie'
  AND @deja_inscrit = 0;

COMMIT;
