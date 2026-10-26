---
name: redaction-francais
description: Rédaction technique en français, en langage clair (plain language, ISO 24495-1) et selon la typographie française. À utiliser pour écrire ou relire en français une documentation, un README, un guide, une note de décision, une description de PR, un message de commit ou un message d'erreur, ou quand un skill ou l'utilisateur demande `redaction-francais`.
metadata:
  source-diataxis: "Daniele Procida, Diátaxis, licence CC BY-SA 4.0 : les quatre formes de documentation et la boussole action ou connaissance, acquisition ou application (section 1, en mots propres, sans reprise du texte). Termes français tirés de la traduction partielle du projet. https://diataxis.fr/"
  source-iso-24495-1: "ISO 24495-1:2023, Langage clair et simple — Partie 1 : Principes directeurs et lignes directrices. Norme payante, non reproduite ici. https://www.iso.org/standard/78907.html"
  source-can-asc-3-1: "CAN-ASC-3.1:2025, Langage clair, Normes d'accessibilité Canada. Norme gratuite, en français, dont les exigences recoupent en partie celles de l'ISO 24495-1. Article 13 : public cible au centre de la démarche (sections 1 et 8), 13.5 et 13.6 (section 2), 13.3 (section 3), 13.1 (section 4), 13.7 (section 6). Préface : https://accessibilite.canada.ca/normes-et-guides-techniques/base-de-donnees-des-normes-et-des-guides-techniques/can-asc-312025-langage-clair/5-preface ; article 13 : https://accessibilite.canada.ca/node/985"
  source-canada-ca: "Guide de rédaction du contenu du site Canada.ca, section 2 « Langage clair » : 2.1 formules de lisibilité (section 8), 2.2 pyramide inversée (sections 2 et 5), 2.3 et 2.5 termes techniques (section 4), 2.4 et 2.6 phrases de moins de 20 mots, verbes plutôt que noms, forme affirmative, négation réservée aux conséquences graves (section 3), 3.1 « vous » (section 6), 5.2 listes homogènes (sections 2 et 5), 6.2 texte alternatif des images et 7.2 liens descriptifs (sections 4 et 8). https://conception.canada.ca/guide-redaction/"
  source-ditp: "Direction interministérielle de la transformation publique (DITP), Simplifier le langage et les documents administratifs. https://www.modernisation.gouv.fr/simplifier-la-vie-des-usagers-et-des-agents/simplifier-le-langage-et-les-documents-administratifs"
  source-oqlf-imperatif-infinitif: "Office québécois de la langue française (OQLF), Vitrine linguistique, distinction entre l'impératif et l'infinitif (section 5). https://vitrinelinguistique.oqlf.gouv.qc.ca/24208/la-grammaire/le-verbe/modes/imperatif/distinction-entre-limperatif-et-linfinitif"
  source-oqlf-espacement: "OQLF, Vitrine linguistique, espacement avant et après les signes de ponctuation et les symboles (section 7 et references/typographie.md). https://vitrinelinguistique.oqlf.gouv.qc.ca/22039/la-typographie/espacement/espacement-avant-et-apres-les-signes-de-ponctuation-et-les-symboles"
  source-oqlf-ne-que: "OQLF, Vitrine linguistique, constructions avec « ne… que » (section 3). https://vitrinelinguistique.oqlf.gouv.qc.ca/22466/la-syntaxe/la-negation-et-la-restriction/constructions-avec-ne-que"
  source-oqlf-etc: "OQLF, Vitrine linguistique, abréviation de « et cetera » (section 7). https://vitrinelinguistique.oqlf.gouv.qc.ca/21006/les-abreviations-et-les-symboles/les-abreviations/cas-particuliers-dabreviations/abreviation-de-et-cetera"
  source-microsoft-fr-fr: "Microsoft, French (France) Localization Style Guide : 2.2.4 but avant l'action (section 5), section 3 formulations épicènes (section 6), 4.1.5 casse des titres (section 2), 4.1.13 « on » (section 3), « Nonbreaking space », guillemets imbriqués et réserve sur les espaces insécables dans le contenu en ligne (section 7 et references/typographie.md). https://download.microsoft.com/download/c/7/9/c7921dbd-4531-4a4e-8490-e4656d739f3d/fra-fra-StyleGuide.pdf"
  source-academie-majuscules: "Académie française, accentuation des majuscules (section 7 et references/typographie.md). https://www.dictionnaire-academie.fr/article/QDL005"
  source-academie-dire-ne-pas-dire: "Académie française, « Dire, ne pas dire », liste des entrées à remarque normative ; la recommandation « affecter » pour « impacter » est rapportée par la presse (section 4). https://www.dictionnaire-academie.fr/article/DNP0797"
  source-ulaval-anglicismes: "Chaire de rédaction juridique de l'Université Laval, capsule sur les anglicismes, « supporter » (section 4). https://www.redactionjuridique.chaire.ulaval.ca/sites/redactionjuridique.chaire.ulaval.ca/files/uploads/Capsules/Capsule-anglicismes-vf.pdf"
  source-franceterme: "FranceTerme, termes recommandés au Journal officiel (section 4). https://www.culture.gouv.fr/thematiques/langue-francaise-et-langues-de-france/agir-pour-les-langues/moderniser-et-enrichir-la-langue-francaise/vous-avez-besoin-d-un-terme-francais"
  source-google-developer-style: "Google developer documentation style guide, CC BY 4.0, pages Cross-references and linking (pas d'URL comme texte de lien), Accessibility (lecteurs d'écran qui passent de lien en lien) et Images (pas de « Image of », pas de capture de texte, de code ni de sortie de terminal) (section 4). Lu par le miroir public github.com/tech-writing-lab/style-guide, le site renvoyant une vérification anti-robot. https://developers.google.com/style/cross-references ; https://developers.google.com/style/accessibility ; https://developers.google.com/style/images"
  source-asd-ste100: "ASD-STE100 Simplified Technical English, Issue 9 (janvier 2025), langue contrôlée née dans la maintenance aéronautique, en anglais seulement (section « Langage clair, FALC et langue contrôlée »). https://www.asd-ste100.org/"
  source-unapei-falc: "Unapei, L'information pour tous, règles européennes du FALC (section « Langage clair, FALC et langue contrôlée »). https://www.unapei.org/document/explication-liste-verification-falc/"
  editorial-choices: "Choix propres à ce skill, sans source directe : les textes qui sortent de la grille de documentation (section 1) ; les chaînes de compléments, le participe présent en remorque, le conditionnel de prudence, les pronoms et les liens logiques, adaptés à la documentation technique (section 3) ; « librairie » et « consistant » comme faux amis, et la priorité au vocabulaire du projet (section 4) ; le résultat attendu et la place de l'avertissement (section 5) ; l'espace ordinaire dans un fichier source, qui étend la réserve du guide Microsoft sur les insécables dans le contenu en ligne (section 7 et section « Fichiers sources » de references/typographie.md)."
---

# Rédaction en français

Un texte est en **langage clair** quand son lecteur y trouve ce dont il a besoin, le comprend à la première lecture et peut s'en servir. « Langage clair » est le terme français pour *plain language*. Ce skill applique cette démarche au français technique.

Une fois le texte écrit, passez `unslop` (par `unslop-agent` si l'agent ne peut pas l'invoquer), qui retire les tics d'écriture d'IA. Ses règles visent l'anglais, donc appliquez leur équivalent français. Sa règle 19 (guillemets droits) ne vaut pas pour le français : gardez « ».

Ne modifiez jamais le code, les commandes, les chemins, les identifiants, les URL, les messages d'erreur cités ni les citations. Corrigez la prose autour. Une réécriture garde chaque fait, chaque condition et le degré de certitude du texte d'origine : elle n'ajoute ni fait, ni commande, ni garantie. Une précision qui manque se vérifie dans le projet ou se demande.

Les conventions écrites du dépôt ou de l'organisation l'emportent sur ce skill : glossaire, tutoiement, écriture inclusive, variante régionale, espaces insécables. Cherchez-les avant d'écrire (`AGENTS.md`, `CONTRIBUTING.md`, charte éditoriale, textes voisins).

## 1. Situer le lecteur

Avant d'écrire, répondez à trois questions :

- Qui lit ? Une personne qui développe le projet, qui l'exploite, qui l'utilise, qui relit une PR ?
- Que sait-elle déjà ? Le vocabulaire du domaine, le code, rien ?
- Que doit-elle faire ou savoir après la lecture ?

Un document sert un usage principal. Pour la documentation d'un produit, deux questions le fixent : le lecteur veut-il agir ou comprendre ? Apprend-il, ou travaille-t-il déjà ?

| | Apprendre | Travailler |
| --- | --- | --- |
| **Agir** | tutoriel : mène un débutant, pas à pas, jusqu'à un premier résultat sûr | guide pratique : mène un lecteur compétent vers un but précis |
| **Comprendre** | explication : donne le contexte et les raisons d'un choix | référence : décrit sans commenter (API, options, configuration) |

Quand un texte mélange deux usages, séparez-les en sections ou en documents liés. Une procédure n'explique pas le pourquoi en cours de route. Elle renvoie à l'explication. Une description de PR, un message de commit et une note de décision n'entrent pas dans cette grille : chacun sert un seul lecteur à un moment précis.

Si le public est inconnu et que le choix change le texte, demandez-le.

L'étape est finie quand vous pouvez écrire en une phrase : « [lecteur] lit ce texte pour [action ou savoir] ».

## 2. Mettre l'essentiel d'abord

- Ouvrez le document, la section et le paragraphe par ce que le lecteur doit retenir ou faire. Le contexte, les détails et les exceptions viennent après (pyramide inversée).
- Un titre dit ce que contient la section : « Sauvegarder la base avant la migration », pas « Remarques ». Écrivez-le en casse de phrase : seule la première lettre et les noms propres prennent une majuscule.
- Trois niveaux de titres au plus.
- Un thème par paragraphe.
- Étapes ordonnées : liste numérotée. Éléments sans ordre : liste à puces. Données à comparer : tableau. Les éléments d'une liste ont la même forme grammaticale.

## 3. Écrire des phrases claires

- **Une idée par phrase.** Au-delà de 20 mots, cherchez à couper. Une phrase plus longue reste si elle porte une seule idée et se lit d'une traite.
- **Sujet, verbe, complément.** Rapprochez le sujet du verbe. Une incise longue entre les deux devient une autre phrase.
- **Nommez qui agit.** « Le script supprime les fichiers temporaires », pas « Les fichiers temporaires sont supprimés ». Le passif reste possible quand l'acteur est inconnu ou sans importance.
- **Le verbe plutôt que le nom.** « procéder à la vérification de » devient « vérifier », « effectuer la mise à jour de » devient « mettre à jour ». Méfiez-vous de « permettre de », « faire l'objet de », « être en mesure de ».
- **Pas de chaîne de compléments.** « La mise à jour de la configuration du serveur de production » se lit mal. Écrivez « mettre à jour la configuration du serveur de production », ou coupez.
- **Pas de participe présent en remorque.** « …, permettant ainsi de réduire les coûts » devient une phrase qui a son propre sujet : « Le cache réduit les coûts. »
- **Affirmez ce qui est sûr.** Le conditionnel de prudence (« devrait », « pourrait », « il conviendrait de ») rend chaque phrase incertaine. Écrivez le fait au présent. Gardez une incertitude réelle, au présent : « La migration peut supprimer des données. » Pour une cause inconnue, dites-le : « La cause n'est pas encore identifiée. »
- **La forme affirmative.** « Gardez la clé secrète » plutôt que « Ne divulguez pas la clé ». Réservez la négation aux interdictions qui ont des conséquences graves. Évitez la double négation.
- **Le sens positif plutôt que « ne… pas que ».** « Le script ne lit pas que les fichiers JSON » signifie qu'il lit aussi d'autres fichiers. La phrase est correcte, mais la négation d'une restriction oblige à relire. Écrivez « Le script lit les fichiers JSON et d'autres formats ».
- **Un pronom, un antécédent évident.** « Celui-ci », « ce dernier », « cela », « ce qui » renvoient souvent à deux candidats. Répétez le nom.
- **Le sujet nommé plutôt que « on ».** « On » ne dit pas qui agit. Écrivez « vous », « nous », « l'équipe », « le serveur ».
- **Des liens logiques explicites.** « parce que », « donc », « si », « avant », « après » disent la relation que le lecteur devrait sinon deviner.

## 4. Choisir les mots

- Le mot courant : « utiliser », pas « recourir à ». « Avant », pas « préalablement ». « Pour », pas « afin de ».
- Un terme par notion, du début à la fin. Un synonyme fait croire à une autre notion.
- Définissez un terme technique à sa première occurrence, en mots simples ou par un exemple. Développez un sigle à sa première occurrence : « interface de programmation (API) ».
- Le vocabulaire du projet l'emporte. Si le dépôt dit « merge », « déployer », « ticket », gardez ces mots.
- Hors vocabulaire du projet, évitez les faux amis et les calques de l'anglais : « supporter » au sens de *to support* devient « prendre en charge » ou « soutenir », « impacter » devient « affecter » ou « toucher », « librairie » au sens de *library* devient « bibliothèque », « consistant » au sens de *consistent* devient « cohérent ». En cas de doute, cherchez dans FranceTerme, la Vitrine linguistique de l'OQLF ou « Dire, ne pas dire » de l'Académie française.
- Écrivez au sens propre. Une figure de style ou une expression familière échappe au lecteur qui lit en seconde langue ou à travers un outil de traduction.
- **Le texte d'un lien dit où il mène**, et garde son sens lu seul, comme l'entend une personne qui passe d'un lien à l'autre avec un lecteur d'écran : « Suivez la [procédure de restauration](…) », jamais « [cliquez ici](…) », « [ici](…) » ni l'URL elle-même. Deux cibles différentes, deux textes différents. Un lien qui télécharge un fichier en donne le format et la taille : « [rapport annuel (PDF, 2 Mo)](…) ».
- **Une image qui informe a un texte alternatif** qui dit ce qu'elle apprend au lecteur, sans « image de » ni « capture de ». Une phrase courte suffit ; le détail va dans le texte de la page. Une image décorative a un texte alternatif vide (`![](…)`, `alt=""`). Le code et les sorties de terminal s'écrivent en texte, pas en capture d'écran.

## 5. Rédiger les consignes

- **Une forme pour tout le document.** L'impératif (« Lancez la commande ») s'adresse au lecteur. L'infinitif (« Lancer la commande ») convient aux modes d'emploi impersonnels et aux consignes très courtes. Les deux sont corrects. Gardez la même forme dans tout le document, et la forme déjà employée par le dépôt s'il en a une.
- **Le but ou la condition d'abord.** « Pour restaurer la base, lancez `make restore`. » « Si la commande échoue, relancez-la avec `--verbose`. » Le lecteur saute ce qui ne le concerne pas.
- **Une action par étape.** Ajoutez ce que le lecteur doit voir quand l'étape a réussi : la sortie attendue, le fichier créé, le message affiché.
- **L'avertissement avant l'étape qu'il protège**, jamais après.

## 6. S'adresser au lecteur

- Vouvoyez le lecteur, sauf si le projet tutoie.
- « Nous » désigne les auteurs ou l'équipe, quand c'est utile.
- Écriture inclusive : suivez la convention du projet. Sans convention, préférez les tournures qui ne demandent aucun signe particulier : noms épicènes (« les membres », « le personnel »), noms collectifs (« l'équipe », « la direction »), reformulation (« si vous êtes inscrit » devient « après votre inscription »).

## 7. Appliquer la typographie française

Ces règles portent sur la prose, pas sur le code.

- **Guillemets** « » avec une espace insécable à l'intérieur : « exemple ». Après une apostrophe, le guillemet ouvrant se colle : d'« exemple ». Pour une citation dans une citation, “ ”. Le code garde ses guillemets droits.
- **Espaces avant la ponctuation.** Usage de France : espace insécable avant `:` `;` `!` `?`. Usage du Québec : espace insécable avant `:`, aucune espace avant `;` `!` `?`. Suivez la variante du dépôt. À défaut, prenez celle du public visé. Dans un fichier source (Markdown, message de commit), une espace ordinaire remplace l'insécable si le dépôt n'en utilise pas. Entre deux mots, les deux-points sont toujours précédés d'une espace, dans les deux variantes. Les notations spécialisées gardent leur forme : heure `13:52:45`, code, URL.
- **Majuscules accentuées** : « État », « À noter ». Pas de majuscule aux jours, aux mois ni aux noms de langues.
- **Nombres** : `1 000` (espace insécable entre les milliers), `3,5` (virgule décimale), `10 %`, `20 €`, `14 h 30`, `1er`, `2e`. L'unité suit le nombre, séparée par une espace insécable.
- **Abréviations** : « etc. » termine une liste sans points de suspension. « M. », « Mme ».

Tableau complet par signe, variantes et caractères Unicode : [`references/typographie.md`](references/typographie.md).

## 8. Relire

Relisez le texte entier contre chaque section ci-dessus. Puis vérifiez :

- La première phrase de chaque section dit l'essentiel.
- Chaque phrase de plus de 20 mots a été relue et coupée, ou gardée pour une raison que vous pouvez donner.
- Aucun « on », aucun conditionnel de prudence, aucun participe présent en remorque ne reste sans raison.
- Chaque terme technique est défini ou connu du lecteur, et chaque notion garde un seul nom.
- Chaque lien se comprend lu seul, et chaque image qui informe a un texte alternatif.
- Les consignes ont toutes la même forme verbale.
- Les guillemets, les espaces avant la ponctuation et les nombres suivent la section 7.
- Le code, les commandes et les citations sont intacts.
- Chaque fait, chaque condition et chaque degré de certitude du texte d'origine est conservé. Aucun fait, aucune commande, aucune garantie n'a été ajouté.

Les formules de lisibilité (Flesch et ses adaptations au français) repèrent des phrases longues, mais ne disent pas si le lecteur comprend. Le seul test fiable est un lecteur du public visé. Quand le texte compte (procédure d'exploitation, message à des usagers), proposez de le faire relire par une personne de ce public.

L'étape est finie quand le texte livré est la version corrigée, pas une liste de remarques. Passez ensuite `unslop`.

## Exemple

Avant :

> Afin de procéder à la mise à jour de la configuration, il conviendrait d'effectuer préalablement une sauvegarde de la base, celle-ci pouvant être impactée par la migration, ce qui pourrait entraîner une perte de données.

Après :

> Avant de mettre à jour la configuration, sauvegardez la base de données. La migration peut affecter la base et entraîner une perte de données.

L'action ouvre le texte. Les noms tirés de verbes, « il conviendrait » et le pronom ambigu « celle-ci » disparaissent, et « affecter » remplace « impacter ». Le risque reste un risque : « peut » remplace « pourrait », sans fait ajouté. Pour nommer la commande de sauvegarde ou les tables touchées, vérifiez-les d'abord dans le projet.

## Langage clair, FALC et langue contrôlée

Le langage clair vise tout lecteur. Deux démarches voisines ont d'autres buts :

- Le **FALC** (facile à lire et à comprendre) s'adresse aux personnes qui ont une déficience intellectuelle. Ses règles européennes sont plus strictes, et un texte FALC se relit avec des personnes de ce public. Si le texte vise ce public, dites-le et renvoyez aux règles de l'Unapei.
- Une **langue contrôlée** (ASD-STE100, français rationalisé du GIFAS) restreint le vocabulaire et les temps verbaux pour la maintenance industrielle et la traduction. Ce skill n'impose pas ces restrictions.
